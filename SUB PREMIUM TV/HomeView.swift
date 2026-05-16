import SwiftUI
import AVKit
import UIKit

struct HomeView: View {
    @StateObject private var store = VideoStore.shared
    @StateObject private var progressStore = WatchProgressStore.shared

    @State private var selectedCategory: VideoCategory?
    @State private var featuredIndex = 0

    private let slideTimer = Timer.publish(
        every: 7,
        on: .main,
        in: .common
    ).autoconnect()

    private var allVideos: [Video] {
        if let selectedCategory {
            return store.videos(for: selectedCategory)
        }

        return store.newestVideos
    }

    private var featuredVideos: [Video] {
        Array(store.newestVideos.prefix(10))
    }

    private var continueWatchingVideos: [Video] {
        store.newestVideos.filter {
            progressStore.shouldContinue($0.id)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                VStack(spacing: 0) {
                    topBar

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            featuredSlider

                            if !continueWatchingVideos.isEmpty {
                                videoRow(
                                    title: "Continue Watching",
                                    videos: continueWatchingVideos
                                )
                            }

                            categoryChips

                            videoRow(title: "Latest Videos", videos: allVideos)
                            videoRow(title: "Trending Now", videos: store.trendingVideos)
                            videoRow(title: "New Releases", videos: store.newestVideos)
                            videoRow(title: "Saved Videos", videos: store.savedVideos)
                            videoRow(title: "Watch History", videos: store.watchHistory)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }
}

// MARK: - Background

private extension HomeView {
    var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.12, blue: 0.13),
                Color(red: 0.07, green: 0.07, blue: 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Top Bar

private extension HomeView {
    var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.8), radius: 8)

                AnimatedSubPremiumLogo()
            }

            Spacer()

            NavigationLink {
                SearchView()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            NavigationLink {
                NotificationsView()
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
    }
}

// MARK: - Featured Slider

private extension HomeView {
    var featuredSlider: some View {
        Group {
            if featuredVideos.isEmpty {
                emptyFeatured
            } else {
                TabView(selection: $featuredIndex) {
                    ForEach(Array(featuredVideos.enumerated()), id: \.element.id) { index, video in
                        NavigationLink {
                            VideoDetailView(video: video)
                        } label: {
                            FeaturedVideoCard(video: video)
                        }
                        .buttonStyle(.plain)
                        .tag(index)
                    }
                }
                .frame(height: 235)
                .padding(.horizontal, 18)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .onReceive(slideTimer) { _ in
                    guard !featuredVideos.isEmpty else { return }

                    withAnimation(.easeInOut(duration: 0.35)) {
                        featuredIndex = (featuredIndex + 1) % featuredVideos.count
                    }
                }
            }
        }
    }

    var emptyFeatured: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 62))
                .foregroundColor(.white.opacity(0.55))

            Text("Upload your first video")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("New uploads will appear here as featured previews.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(Color.gray.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 18)
    }
}

// MARK: - Categories

private extension HomeView {
    var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    selectedCategory = nil
                } label: {
                    chipTitle("All", isSelected: selectedCategory == nil)
                }

                ForEach(VideoCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        chipTitle(
                            category.rawValue,
                            isSelected: selectedCategory == category
                        )
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    func chipTitle(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(isSelected ? Color.white : Color.gray.opacity(0.25))
            .clipShape(Capsule())
    }
}

// MARK: - Rows

private extension HomeView {
    func videoRow(title: String, videos: [Video]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 18)

            if videos.isEmpty {
                Text("No videos yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 18)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(videos) { video in
                            NavigationLink {
                                VideoDetailView(video: video)
                            } label: {
                                OTTPosterCard(video: video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
    }
}

// MARK: - Logo

struct AnimatedSubPremiumLogo: View {
    @State private var glow = false

    var body: some View {
        Text("SUB PREMIUM TV")
            .font(.system(size: 20, weight: .black))
            .foregroundStyle(
                LinearGradient(
                    colors: [.red, .orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(
                color: .red.opacity(glow ? 0.9 : 0.25),
                radius: glow ? 12 : 3
            )
            .scaleEffect(glow ? 1.03 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    glow.toggle()
                }
            }
    }
}

// MARK: - Featured Card

struct FeaturedVideoCard: View {
    let video: Video

    @StateObject private var progressStore = WatchProgressStore.shared

    private var progress: Double {
        progressStore.progress(for: video.id)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            posterImage
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 9, contentMode: .fill)
                .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.88)
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(progressStore.shouldContinue(video.id) ? "CONTINUE WATCHING" : "FEATURED")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .clipShape(Capsule())

                Text(video.title.uppercased())
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                    Text("\(video.views) views")
                    Text("•")
                    Text(relativeDate(video.createdAt))
                }
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.8))

                HStack {
                    Image(systemName: "play.fill")
                    Text(progressStore.shouldContinue(video.id) ? "Resume" : "Watch Now")
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.red)
                .clipShape(Capsule())
            }
            .padding(18)

            VStack {
                Spacer()

                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geo.size.width * progress, height: 5)
                }
                .frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var posterImage: some View {
        Group {
            if let image = loadImage(video.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 62))
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
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

    private func relativeDate(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60) min ago" }
        if seconds < 86400 { return "\(seconds / 3600) hr. ago" }
        if seconds < 31_536_000 { return "\(seconds / 86400) days ago" }

        return "\(seconds / 31_536_000) yr. ago"
    }
}

// MARK: - OTT Poster Card

struct OTTPosterCard: View {
    let video: Video

    @StateObject private var progressStore = WatchProgressStore.shared

    private var progress: Double {
        progressStore.progress(for: video.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .bottomTrailing) {
                posterImage
                    .frame(width: 260, height: 150)
                    .clipped()

                VStack {
                    Spacer()

                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geo.size.width * progress, height: 5)
                    }
                    .frame(height: 5)
                }

                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                    Text(progressStore.shouldContinue(video.id) ? "Resume" : "Play")
                }
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.72))
                .clipShape(Capsule())
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(video.title)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 260, alignment: .leading)

            Text("\(video.creatorName) • \(video.views) views")
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 260, alignment: .leading)
        }
        .frame(width: 260)
    }

    private var posterImage: some View {
        Group {
            if let image = loadImage(video.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.55))
                    )
            }
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
