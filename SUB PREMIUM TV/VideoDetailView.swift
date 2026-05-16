import SwiftUI
import AVKit
import UIKit
import PhotosUI

struct VideoDetailView: View {

    let video: Video

    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = VideoStore.shared
    @StateObject private var progressStore = WatchProgressStore.shared

    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var didResume = false
    @State private var watchedProgress: Double = 0

    @State private var isLiked = false
    @State private var isDisliked = false
    @State private var isSaved = false

    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showReportAlert = false
    @State private var showCopiedAlert = false

    private var currentVideo: Video {
        store.videos.first(where: { $0.id == video.id }) ?? video
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.13),
                    Color(red: 0.07, green: 0.07, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    playerSection

                    progressResumeSection

                    VStack(alignment: .leading, spacing: 16) {
                        Text(currentVideo.title)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(3)

                        metaRow
                        actionRows

                        if !currentVideo.description.isEmpty {
                            Text(currentVideo.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.82))
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.10))

                        Text("Creator")
                            .font(.headline.bold())
                            .foregroundColor(.white)

                        Text(currentVideo.creatorName)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        moreVideosSection
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 110)
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 90 {
                            if let player {
                                saveCurrentProgress()

                                MiniPlayerManager.shared.show(
                                    video: currentVideo,
                                    player: player
                                )

                                dismiss()
                            }
                        }
                    }
            )
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .top) {
            topBar
        }
        .onAppear {
            setupPlayer()
            store.addView(to: currentVideo)
            isLiked = store.isLiked(currentVideo)
            isSaved = store.isSaved(currentVideo)
            resumeSavedPosition()
            startProgressObserver()
        }
        .onDisappear {
            if !MiniPlayerManager.shared.isVisible {
                saveCurrentProgress()
                removeProgressObserver()
                player?.pause()
                player = nil
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditVideoSheet(video: currentVideo)
        }
        .alert("Delete Video Permanently?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                saveCurrentProgress()
                removeProgressObserver()
                MiniPlayerManager.shared.hide()
                store.deleteVideo(currentVideo)
                dismiss()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the video from the app permanently.")
        }
        .alert("Reported", isPresented: $showReportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thank you. This video has been reported.")
        }
        .alert("Copied", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Video details copied.")
        }
    }
}

// MARK: - Top Bar

private extension VideoDetailView {

    var topBar: some View {
        HStack(spacing: 12) {

            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")

                    Text("Back")
                }
                .font(.headline.bold())
                .foregroundColor(.red)
            }

            Spacer()

            Button {
                if let player {
                    MiniPlayerManager.shared.show(
                        video: currentVideo,
                        player: player
                    )

                    dismiss()
                }
            } label: {
                Image(systemName: "rectangle.inset.filled.and.person.filled")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    showEditSheet = true
                } label: {
                    Label(
                        "Edit Video",
                        systemImage: "pencil"
                    )
                }

                Button {
                    copyVideoInfo()
                } label: {
                    Label(
                        "Share / Copy",
                        systemImage: "square.and.arrow.up"
                    )
                }

                Button {
                    showReportAlert = true
                } label: {
                    Label(
                        "Report Video",
                        systemImage: "exclamationmark.bubble"
                    )
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label(
                        "Delete Video Permanently",
                        systemImage: "trash"
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Color(
                red: 0.12,
                green: 0.12,
                blue: 0.13
            )
        )
    }
}

// MARK: - Player

private extension VideoDetailView {

    var progressResumeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progressText)
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.85))

                Spacer()

                if progressStore.shouldContinue(currentVideo.id) {
                    Button {
                        seekToSavedPosition()
                    } label: {
                        Text("Resume")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 5)

                    Capsule()
                        .fill(Color.red)
                        .frame(
                            width: geo.size.width * progressStore.progress(for: currentVideo.id),
                            height: 5
                        )
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 18)
    }

    var progressText: String {
        let progress = progressStore.progress(for: currentVideo.id)
        let percent = Int(progress * 100)
        let seconds = progressStore.savedPosition(for: currentVideo.id)

        if progressStore.shouldContinue(currentVideo.id) {
            return "\(percent)% watched • stopped at \(formatSeconds(seconds))"
        }

        if progress >= 0.96 {
            return "Watched"
        }

        return "Progress will save while watching"
    }

    var playerSection: some View {
        VStack(spacing: 0) {
            Group {
                if let player {
                    VideoPlayer(player: player)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .background(Color.black)
                        .onAppear {
                            player.play()
                        }
                } else if let image = loadImage(currentVideo.thumbnailURL) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .background(Color.black)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.22))

                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 55))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .aspectRatio(16 / 9, contentMode: .fit)
                }
            }

            progressBar
        }
        .background(Color.black)
    }

    var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.18))

                Rectangle()
                    .fill(Color.red)
                    .frame(
                        width: geo.size.width * progressStore.progress(for: currentVideo.id)
                    )
            }
        }
        .frame(height: 5)
    }

    func setupPlayer() {
        guard let path = currentVideo.videoURL else { return }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if clean.hasPrefix("http://") || clean.hasPrefix("https://"),
           let url = URL(string: clean) {
            player = AVPlayer(url: url)
            resumeSavedPosition()
            startProgressObserver()
            return
        }

        if clean.hasPrefix("file://"),
           let url = URL(string: clean) {
            player = AVPlayer(url: url)
            resumeSavedPosition()
            startProgressObserver()
            return
        }

        if FileManager.default.fileExists(atPath: clean) {
            player = AVPlayer(url: URL(fileURLWithPath: clean))
            resumeSavedPosition()
            startProgressObserver()
        }
    }

    func resumeSavedPosition() {
        guard !didResume else { return }
        guard let player else { return }

        let savedSeconds = progressStore.savedPosition(for: currentVideo.id)
        guard savedSeconds > 3 else { return }

        didResume = true

        let time = CMTime(seconds: savedSeconds, preferredTimescale: 600)

        player.seek(
            to: time,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func seekToSavedPosition() {
        guard let player else { return }

        let savedSeconds = progressStore.savedPosition(for: currentVideo.id)
        guard savedSeconds > 3 else { return }

        let time = CMTime(seconds: savedSeconds, preferredTimescale: 600)

        player.seek(
            to: time,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )

        player.play()
    }

    func startProgressObserver() {
        guard let player else { return }

        removeProgressObserver()

        let interval = CMTime(seconds: 2, preferredTimescale: 600)

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { _ in
            saveCurrentProgress()
        }
    }

    func removeProgressObserver() {
        guard let timeObserver else { return }

        player?.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }

    func saveCurrentProgress() {
        guard let player else { return }

        let current = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0

        guard current.isFinite, duration.isFinite, duration > 0 else { return }

        progressStore.saveProgress(
            videoID: currentVideo.id,
            currentTime: current,
            duration: duration
        )
    }
}

// MARK: - Content

private extension VideoDetailView {

    var metaRow: some View {
        HStack(spacing: 14) {
            Label("\(currentVideo.views) views", systemImage: "eye.fill")
            Label("\(currentVideo.likes) likes", systemImage: "heart.fill")
            Text(currentVideo.category.rawValue)
        }
        .font(.subheadline.bold())
        .foregroundColor(.gray)
    }

    var actionRows: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                actionButton(
                    title: isLiked ? "Liked" : "Like",
                    icon: isLiked ? "heart.fill" : "heart"
                ) {
                    store.toggleLike(currentVideo)
                    isLiked = store.isLiked(currentVideo)

                    if isLiked {
                        isDisliked = false
                    }
                }

                actionButton(
                    title: isDisliked ? "Disliked" : "Dislike",
                    icon: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown"
                ) {
                    isDisliked.toggle()

                    if isDisliked && isLiked {
                        store.toggleLike(currentVideo)
                        isLiked = false
                    }
                }

                actionButton(
                    title: isSaved ? "Saved" : "Bookmark",
                    icon: isSaved ? "bookmark.fill" : "bookmark"
                ) {
                    store.toggleSave(currentVideo)
                    isSaved = store.isSaved(currentVideo)
                }

                actionButton(title: "Share", icon: "square.and.arrow.up") {
                    copyVideoInfo()
                }

                actionButton(title: "Download", icon: "arrow.down.circle") {
                    copyVideoPath()
                }

                actionButton(title: "Report", icon: "exclamationmark.bubble") {
                    showReportAlert = true
                }
            }
            .padding(.vertical, 2)
        }
    }

    func actionButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Color.gray.opacity(0.25))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    var moreVideosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("More Videos")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top, 10)

            ForEach(store.newestVideos.filter { $0.id != currentVideo.id }.prefix(10)) { item in
                NavigationLink {
                    VideoDetailView(video: item)
                } label: {
                    HStack(spacing: 12) {
                        thumbnail(item)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title)
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .lineLimit(2)

                            Text("\(item.creatorName) • \(item.views) views")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    func thumbnail(_ video: Video) -> some View {
        ZStack {
            if let image = loadImage(video.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.white.opacity(0.55))
                    )
            }
        }
        .frame(width: 145, height: 82)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Helpers

private extension VideoDetailView {

    func formatSeconds(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }

        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%d:%02d", minutes, secs)
    }

    func copyVideoInfo() {
        let text = """
        \(currentVideo.title)
        \(currentVideo.description)
        Creator: \(currentVideo.creatorName)
        Views: \(currentVideo.views)
        """

        UIPasteboard.general.string = text
        showCopiedAlert = true
    }

    func copyVideoPath() {
        UIPasteboard.general.string = currentVideo.videoURL ?? ""
        showCopiedAlert = true
    }

    func loadImage(_ path: String?) -> UIImage? {
        guard let path else { return nil }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        if clean.hasPrefix("file://"),
           let url = URL(string: clean) {
            return UIImage(contentsOfFile: url.path)
        }

        if FileManager.default.fileExists(atPath: clean) {
            return UIImage(contentsOfFile: clean)
        }

        return nil
    }
}

// MARK: - Edit Video Sheet

struct EditVideoSheet: View {

    let video: Video

    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = VideoStore.shared

    @State private var title: String
    @State private var description: String
    @State private var category: VideoCategory
    @State private var thumbnailPath: String?
    @State private var selectedThumbnailItem: PhotosPickerItem?

    init(video: Video) {
        self.video = video
        _title = State(initialValue: video.title)
        _description = State(initialValue: video.description)
        _category = State(initialValue: video.category)
        _thumbnailPath = State(initialValue: video.thumbnailURL)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.13),
                        Color(red: 0.07, green: 0.07, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Edit Video")
                            .font(.system(size: 30, weight: .black))
                            .foregroundColor(.white)

                        thumbnailPreview

                        PhotosPicker(selection: $selectedThumbnailItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Add New Thumbnail")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button(role: .destructive) {
                            thumbnailPath = nil
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Thumbnail")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        TextField("Title", text: $title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Picker("Category", selection: $category) {
                            ForEach(VideoCategory.allCases, id: \.self) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button {
                            saveChanges()
                        } label: {
                            Text("Save Changes")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onChange(of: selectedThumbnailItem) { _, newItem in
                loadThumbnail(from: newItem)
            }
        }
    }

    private var thumbnailPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.gray.opacity(0.22))

            if let image = loadImage(thumbnailPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 46))
                        .foregroundColor(.white.opacity(0.55))

                    Text("No thumbnail")
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func saveChanges() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        var updated = video
        updated.title = cleanTitle
        updated.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.category = category
        updated.thumbnailURL = thumbnailPath

        store.updateVideo(updated)
        dismiss()
    }

    private func loadThumbnail(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let path = saveImage(image) {
                await MainActor.run {
                    thumbnailPath = path
                }
            }
        }
    }

    private func saveImage(_ image: UIImage) -> String? {
        let fileName = "edited_thumbnail_\(UUID().uuidString).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }

        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    private func loadImage(_ path: String?) -> UIImage? {
        guard let path else { return nil }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        if clean.hasPrefix("file://"),
           let url = URL(string: clean) {
            return UIImage(contentsOfFile: url.path)
        }

        if FileManager.default.fileExists(atPath: clean) {
            return UIImage(contentsOfFile: clean)
        }

        return nil
    }
}
