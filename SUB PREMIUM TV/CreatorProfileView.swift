import SwiftUI
import UIKit

enum CreatorProfileTab: String, CaseIterable {
    case videos = "Videos"
    case playlists = "Playlists"
    case liked = "Liked"
    case about = "About"
}

struct CreatorProfileView: View {

    let creatorName: String

    @StateObject private var store = VideoStore.shared
    @StateObject private var auth = AuthManager.shared

    @State private var selectedTab: CreatorProfileTab = .videos
    @State private var showShareSheet = false
    @State private var copiedLink = false

    private var creatorVideos: [Video] {
        store.newestVideos.filter {
            $0.creatorName.lowercased() == creatorName.lowercased()
        }
    }

    private var creatorLikedVideos: [Video] {
        creatorVideos.filter { $0.likes > 0 }
    }

    private var totalViews: Int {
        creatorVideos.reduce(0) { $0 + $1.views }
    }

    private var totalLikes: Int {
        creatorVideos.reduce(0) { $0 + $1.likes }
    }

    private var profileLink: String {
        "subpremiumtv://creator/\(creatorName)"
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
                VStack(spacing: 20) {
                    topBanner
                    creatorHeader
                    statsSection
                    actionButtons
                    tabBar
                    tabContent
                }
                .padding(.bottom, 110)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Copied", isPresented: $copiedLink) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Creator profile link copied.")
        }
    }
}

// MARK: - Header

private extension CreatorProfileView {

    var topBanner: some View {
        ZStack(alignment: .bottomLeading) {

            LinearGradient(
                colors: [
                    Color.red.opacity(0.9),
                    Color.orange.opacity(0.7),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("SUB PREMIUM TV")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white.opacity(0.85))

                Text("CREATOR CHANNEL")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(20)
        }
        .frame(height: 210)
        .clipShape(
            RoundedRectangle(cornerRadius: 0)
        )
    }

    var creatorHeader: some View {
        VStack(spacing: 14) {

            avatarView

            VStack(spacing: 5) {

                Text(creatorName.uppercased())
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("@\(cleanHandle)")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            Text("OTT Creator • Upload movies, series, entertainment and premium streaming videos.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, -75)
    }

    var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.25))

            Text(initialLetter)
                .font(.system(size: 48, weight: .black))
                .foregroundColor(.white)
        }
        .frame(width: 128, height: 128)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    var initialLetter: String {
        String(creatorName.prefix(1)).uppercased()
    }

    var cleanHandle: String {
        creatorName
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }
}

// MARK: - Stats

private extension CreatorProfileView {

    var statsSection: some View {
        HStack(spacing: 12) {

            statCard(
                title: "Videos",
                value: "\(creatorVideos.count)"
            )

            statCard(
                title: "Views",
                value: formatNumber(totalViews)
            )

            statCard(
                title: "Likes",
                value: formatNumber(totalLikes)
            )
        }
        .padding(.horizontal, 18)
    }

    func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {

            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.gray.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Buttons

private extension CreatorProfileView {

    var actionButtons: some View {
        HStack(spacing: 12) {

            Button {
                UIPasteboard.general.string = profileLink
                copiedLink = true
            } label: {

                HStack(spacing: 8) {
                    Image(systemName: "link")
                    Text("Copy Link")
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Button {
                shareProfile()
            } label: {

                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(.horizontal, 18)
    }

    func shareProfile() {
        UIPasteboard.general.string =
        """
        Watch creator \(creatorName) on SUB PREMIUM TV.
        \(profileLink)
        """
    }
}

// MARK: - Tabs

private extension CreatorProfileView {

    var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 12) {

                ForEach(CreatorProfileTab.allCases, id: \.self) { tab in

                    Button {

                        selectedTab = tab

                    } label: {

                        Text(tab.rawValue)
                            .font(.headline.bold())
                            .foregroundColor(
                                selectedTab == tab
                                ? .black
                                : .white
                            )
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == tab
                                ? Color.white
                                : Color.gray.opacity(0.25)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    @ViewBuilder
    var tabContent: some View {

        switch selectedTab {

        case .videos:
            videosSection(
                title: "All Videos",
                videos: creatorVideos
            )

        case .playlists:
            playlistsSection

        case .liked:
            videosSection(
                title: "Liked Videos",
                videos: creatorLikedVideos
            )

        case .about:
            aboutSection
        }
    }
}

// MARK: - Video Sections

private extension CreatorProfileView {

    func videosSection(
        title: String,
        videos: [Video]
    ) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 18)

            if videos.isEmpty {

                VStack(spacing: 12) {

                    Image(systemName: "play.rectangle")
                        .font(.system(size: 52))
                        .foregroundColor(.white.opacity(0.45))

                    Text("No videos yet")
                        .font(.headline.bold())
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)

            } else {

                ScrollView(.horizontal, showsIndicators: false) {

                    HStack(spacing: 14) {

                        ForEach(videos) { video in

                            NavigationLink {

                                VideoDetailView(video: video)

                            } label: {

                                CreatorVideoCard(video: video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
    }

    var playlistsSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Creator Playlists")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 14) {

                    playlistCard(
                        title: "Popular Uploads",
                        subtitle: "\(creatorVideos.count) videos"
                    )

                    playlistCard(
                        title: "Top Trending",
                        subtitle: "\(formatNumber(totalViews)) views"
                    )

                    playlistCard(
                        title: "Most Liked",
                        subtitle: "\(formatNumber(totalLikes)) likes"
                    )
                }
                .padding(.horizontal, 18)
            }
        }
    }

    func playlistCard(
        title: String,
        subtitle: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.85),
                            Color.orange.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 240, height: 135)
                .overlay(
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.white.opacity(0.85))
                )

            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - About

private extension CreatorProfileView {

    var aboutSection: some View {

        VStack(spacing: 14) {

            aboutCard(
                title: "Creator",
                value: creatorName
            )

            aboutCard(
                title: "Username",
                value: "@\(cleanHandle)"
            )

            aboutCard(
                title: "Total Videos",
                value: "\(creatorVideos.count)"
            )

            aboutCard(
                title: "Total Views",
                value: formatNumber(totalViews)
            )

            aboutCard(
                title: "Total Likes",
                value: formatNumber(totalLikes)
            )

            aboutCard(
                title: "Platform",
                value: "SUB PREMIUM TV"
            )
        }
        .padding(.horizontal, 18)
    }

    func aboutCard(
        title: String,
        value: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)

            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Helpers

private extension CreatorProfileView {

    func formatNumber(_ value: Int) -> String {

        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }

        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }

        return "\(value)"
    }
}

// MARK: - Creator Video Card

struct CreatorVideoCard: View {

    let video: Video

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            thumbnail

            VStack(alignment: .leading, spacing: 6) {

                Text(video.title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text("\(video.views) views • \(video.likes) likes")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 250)
    }

    var thumbnail: some View {

        ZStack(alignment: .bottomTrailing) {

            if let image = loadImage(video.thumbnailURL) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else {

                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 42))
                            .foregroundColor(.white.opacity(0.55))
                    )
            }

            HStack(spacing: 5) {

                Image(systemName: "play.fill")

                Text("Watch")
            }
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.75))
            .clipShape(Capsule())
            .padding(10)
        }
        .frame(width: 250, height: 145)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func loadImage(_ path: String?) -> UIImage? {

        guard let path else { return nil }

        let clean =
        path.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !clean.isEmpty else { return nil }

        if FileManager.default.fileExists(atPath: clean) {

            return UIImage(contentsOfFile: clean)
        }

        return nil
    }
}
