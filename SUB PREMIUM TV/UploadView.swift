import SwiftUI
import PhotosUI
import AVKit
import AVFoundation
import UIKit

struct UploadView: View {
    @Binding var selectedTab: MainAppTab

    @StateObject private var store = VideoStore.shared

    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedThumbnailItem: PhotosPickerItem?

    @State private var videoPath: String?
    @State private var thumbnailPath: String?

    @State private var previewPlayer: AVPlayer?

    @State private var title = ""
    @State private var description = ""
    @State private var category: VideoCategory = .movies

    @State private var isLoadingVideo = false
    @State private var isLoadingThumbnail = false
    @State private var message = ""

    @FocusState private var focusedField: UploadField?

    enum UploadField {
        case title
        case description
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.13),
                        Color(red: 0.08, green: 0.08, blue: 0.09)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        topBar

                        videoPickerSection

                        thumbnailPickerSection

                        detailsSection

                        uploadButton

                        if !message.isEmpty {
                            Text(message)
                                .foregroundColor(.white.opacity(0.75))
                                .font(.subheadline)
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .onChange(of: selectedVideoItem) { _, _ in
                loadSelectedVideo()
            }
            .onChange(of: selectedThumbnailItem) { _, _ in
                loadSelectedThumbnail()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}

// MARK: - Top Bar

private extension UploadView {
    var topBar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                previewPlayer?.pause()
                selectedTab = .home
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.headline.bold())
                .foregroundColor(.red)
            }

            Text("Upload Video")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.white)

            Text("Choose a video, preview it, add a thumbnail, then publish to SUB PREMIUM TV.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Video Picker

private extension UploadView {
    var videoPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Preview")
                .font(.title3.bold())
                .foregroundColor(.white)

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.gray.opacity(0.22))

                if let previewPlayer {
                    VideoPlayer(player: previewPlayer)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .onTapGesture {
                            previewPlayer.play()
                        }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 58))
                            .foregroundColor(.white.opacity(0.65))

                        Text(isLoadingVideo ? "Loading video..." : "Select a video")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.headline)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 9, contentMode: .fit)

            PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                HStack {
                    Image(systemName: "video.fill")
                    Text(videoPath == nil ? "Choose Video" : "Change Video")
                }
                .font(.headline.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if videoPath != nil {
                Text("Video saved permanently.")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
        }
    }

    func loadSelectedVideo() {
        guard let selectedVideoItem else { return }

        isLoadingVideo = true
        message = ""

        Task {
            do {
                if let data = try await selectedVideoItem.loadTransferable(type: Data.self) {
                    let savedPath = try UploadStorageManager.shared.saveVideoData(data)
                    let url = URL(fileURLWithPath: savedPath)

                    await MainActor.run {
                        videoPath = savedPath
                        previewPlayer?.pause()
                        previewPlayer = AVPlayer(url: url)
                        previewPlayer?.play()
                        isLoadingVideo = false
                        message = "Video saved permanently and ready."
                    }

                    generateThumbnailIfNeeded(from: url)
                } else {
                    await MainActor.run {
                        isLoadingVideo = false
                        message = "Failed to read video data."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingVideo = false
                    message = "Failed to save video permanently."
                }
            }
        }
    }
}

// MARK: - Thumbnail Picker

private extension UploadView {
    var thumbnailPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thumbnail Preview")
                .font(.title3.bold())
                .foregroundColor(.white)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.22))

                if let image = loadImage(from: thumbnailPath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 46))
                            .foregroundColor(.white.opacity(0.55))

                        Text(isLoadingThumbnail ? "Loading thumbnail..." : "Thumbnail will appear here")
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 9, contentMode: .fit)

            PhotosPicker(selection: $selectedThumbnailItem, matching: .images) {
                HStack {
                    Image(systemName: "photo")
                    Text(thumbnailPath == nil ? "Choose Thumbnail" : "Change Thumbnail")
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if thumbnailPath != nil {
                Button(role: .destructive) {
                    deleteFile(at: thumbnailPath)
                    thumbnailPath = nil
                } label: {
                    Text("Remove Thumbnail")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }
            }
        }
    }

    func loadSelectedThumbnail() {
        guard let selectedThumbnailItem else { return }

        isLoadingThumbnail = true
        message = ""

        Task {
            do {
                if let data = try await selectedThumbnailItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let path = UploadStorageManager.shared.saveThumbnailImage(image) {
                    await MainActor.run {
                        thumbnailPath = path
                        isLoadingThumbnail = false
                        message = "Thumbnail saved permanently."
                    }
                } else {
                    await MainActor.run {
                        isLoadingThumbnail = false
                        message = "Failed to read thumbnail."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingThumbnail = false
                    message = "Failed to save thumbnail."
                }
            }
        }
    }
}

// MARK: - Details

private extension UploadView {
    var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Video Details")
                .font(.title3.bold())
                .foregroundColor(.white)

            TextField("Title", text: $title)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .focused($focusedField, equals: .title)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }

            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(3...6)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .focused($focusedField, equals: .description)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }

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
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    var uploadButton: some View {
        Button {
            publishVideo()
        } label: {
            Text("Upload Now")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canUpload ? Color.red : Color.gray.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .disabled(!canUpload)
    }

    var canUpload: Bool {
        videoPath != nil &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func publishVideo() {
        focusedField = nil

        guard let videoPath else {
            message = "Please select a video."
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            message = "Please enter a title."
            return
        }

        store.uploadVideo(
            title: cleanTitle,
            description: cleanDescription,
            thumbnailURL: thumbnailPath,
            videoURL: videoPath,
            category: category
        )

        previewPlayer?.pause()
        resetForm()

        message = "Video uploaded successfully."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedTab = .home
        }
    }

    func resetForm() {
        selectedVideoItem = nil
        selectedThumbnailItem = nil
        videoPath = nil
        thumbnailPath = nil
        previewPlayer = nil
        title = ""
        description = ""
        category = .movies
    }
}

// MARK: - Helpers

private extension UploadView {

    func generateThumbnailIfNeeded(from videoURL: URL) {
        guard thumbnailPath == nil else { return }

        Task {
            let image = UploadStorageManager.shared.generateThumbnail(from: videoURL)

            if let image {
                thumbnailPath = UploadStorageManager.shared.saveThumbnailImage(image)
            } else {
                message = "Video selected, but thumbnail was not generated."
            }
        }
    }

    func saveImage(_ image: UIImage) -> String? {
        UploadStorageManager.shared.saveThumbnailImage(image)
    }

    func loadImage(from path: String?) -> UIImage? {
        UploadStorageManager.shared.loadImage(from: path)
    }

    func deleteFile(at path: String?) {
        UploadStorageManager.shared.deleteFile(at: path)
    }
}
