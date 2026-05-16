import SwiftUI
import UIKit

struct ProfilePlaylist: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var videoIDs: [UUID]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        videoIDs: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.videoIDs = videoIDs
        self.createdAt = createdAt
    }
}

@MainActor
final class ProfilePlaylistStore: ObservableObject {
    static let shared = ProfilePlaylistStore()

    @Published var playlistsByUser: [String: [ProfilePlaylist]] = [:] {
        didSet { savePlaylists() }
    }

    private let key = "subpremium_tv_profile_playlists"

    private init() {
        loadPlaylists()
    }

    func playlists(for email: String) -> [ProfilePlaylist] {
        playlistsByUser[email.lowercased()] ?? []
    }

    func createPlaylist(name: String, for email: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let userEmail = email.lowercased()

        guard !clean.isEmpty else { return }

        var list = playlistsByUser[userEmail] ?? []

        guard !list.contains(where: { $0.name.lowercased() == clean.lowercased() }) else {
            return
        }

        list.insert(ProfilePlaylist(name: clean), at: 0)
        playlistsByUser[userEmail] = list
    }

    func deletePlaylist(_ playlist: ProfilePlaylist, for email: String) {
        let userEmail = email.lowercased()
        var list = playlistsByUser[userEmail] ?? []
        list.removeAll { $0.id == playlist.id }
        playlistsByUser[userEmail] = list
    }

    func addVideo(_ video: Video, to playlist: ProfilePlaylist, for email: String) {
        let userEmail = email.lowercased()
        var list = playlistsByUser[userEmail] ?? []

        guard let index = list.firstIndex(where: { $0.id == playlist.id }) else { return }

        if !list[index].videoIDs.contains(video.id) {
            list[index].videoIDs.insert(video.id, at: 0)
        }

        playlistsByUser[userEmail] = list
    }

    func removeVideo(_ video: Video, from playlist: ProfilePlaylist, for email: String) {
        let userEmail = email.lowercased()
        var list = playlistsByUser[userEmail] ?? []

        guard let index = list.firstIndex(where: { $0.id == playlist.id }) else { return }

        list[index].videoIDs.removeAll { $0 == video.id }
        playlistsByUser[userEmail] = list
    }

    func isVideo(_ video: Video, in playlist: ProfilePlaylist) -> Bool {
        playlist.videoIDs.contains(video.id)
    }

    private func savePlaylists() {
        guard let data = try? JSONEncoder().encode(playlistsByUser) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func loadPlaylists() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [ProfilePlaylist]].self, from: data) else {
            playlistsByUser = [:]
            return
        }

        playlistsByUser = decoded
    }
}

struct ProfilePlaylistsView: View {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var videoStore = VideoStore.shared
    @StateObject private var playlistStore = ProfilePlaylistStore.shared

    @State private var playlistName = ""
    @State private var selectedPlaylist: ProfilePlaylist?
    @State private var showCreateAlert = false

    private var currentEmail: String {
        auth.currentUser?.email.lowercased() ?? ""
    }

    private var playlists: [ProfilePlaylist] {
        playlistStore.playlists(for: currentEmail)
    }

    private var availableVideos: [Video] {
        videoStore.newestVideos
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

            if currentEmail.isEmpty {
                loginRequired
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        createPlaylistCard
                        playlistsSection
                        availableVideosSection
                    }
                    .padding(18)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPlaylist) { playlist in
            PlaylistDetailSheet(playlist: playlist)
        }
    }
}

// MARK: - Main UI

private extension ProfilePlaylistsView {
    var loginRequired: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 58))
                .foregroundColor(.red)

            Text("Login Required")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)

            Text("Log in to create playlists and add videos.")
                .foregroundColor(.gray)
        }
        .padding()
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("My Playlists")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.white)

            Text("Create playlists and add any available videos from SUB PREMIUM TV.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    var createPlaylistCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Create New Playlist")
                .font(.title3.bold())
                .foregroundColor(.white)

            TextField("Playlist name", text: $playlistName)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                createPlaylist()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Playlist")
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreatePlaylist ? Color.red : Color.gray.opacity(0.30))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(!canCreatePlaylist)
        }
        .padding(16)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    var canCreatePlaylist: Bool {
        !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createPlaylist() {
        playlistStore.createPlaylist(name: playlistName, for: currentEmail)
        playlistName = ""
    }
}

// MARK: - Playlists

private extension ProfilePlaylistsView {
    var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Playlists")
                .font(.title2.bold())
                .foregroundColor(.white)

            if playlists.isEmpty {
                emptyCard(
                    icon: "music.note.list",
                    title: "No playlists yet",
                    subtitle: "Create one above, then add videos."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(playlists) { playlist in
                            Button {
                                selectedPlaylist = playlist
                            } label: {
                                playlistCard(playlist)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    playlistStore.deletePlaylist(playlist, for: currentEmail)
                                } label: {
                                    Label("Delete Playlist", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func playlistCard(_ playlist: ProfilePlaylist) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.90),
                                Color.orange.opacity(0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 46))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(width: 240, height: 135)

            Text(playlist.name)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 240, alignment: .leading)

            Text("\(playlist.videoIDs.count) videos")
                .font(.caption.bold())
                .foregroundColor(.gray)
                .frame(width: 240, alignment: .leading)
        }
    }
}

// MARK: - Available Videos

private extension ProfilePlaylistsView {
    var availableVideosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Available Videos")
                .font(.title2.bold())
                .foregroundColor(.white)

            if availableVideos.isEmpty {
                emptyCard(
                    icon: "play.slash",
                    title: "No videos available",
                    subtitle: "Upload videos first, then add them to playlists."
                )
            } else if playlists.isEmpty {
                emptyCard(
                    icon: "plus.rectangle.on.rectangle",
                    title: "Create a playlist first",
                    subtitle: "After creating a playlist, videos can be added here."
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(availableVideos) { video in
                        availableVideoRow(video)
                    }
                }
            }
        }
    }

    func availableVideoRow(_ video: Video) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                thumbnail(video)

                VStack(alignment: .leading, spacing: 5) {
                    Text(video.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text("\(video.creatorName) • \(video.views) views")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(playlists) { playlist in
                        let added = playlistStore.isVideo(video, in: playlist)

                        Button {
                            if added {
                                playlistStore.removeVideo(video, from: playlist, for: currentEmail)
                            } else {
                                playlistStore.addVideo(video, to: playlist, for: currentEmail)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                                Text(playlist.name)
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(added ? Color.red : Color.gray.opacity(0.28))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func thumbnail(_ video: Video) -> some View {
        ZStack {
            if let image = loadImage(video.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.55))
                    )
            }
        }
        .frame(width: 130, height: 76)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func emptyCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundColor(.white.opacity(0.40))

            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

// MARK: - Playlist Detail

struct PlaylistDetailSheet: View {
    let playlist: ProfilePlaylist

    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthManager.shared
    @StateObject private var videoStore = VideoStore.shared
    @StateObject private var playlistStore = ProfilePlaylistStore.shared

    private var currentEmail: String {
        auth.currentUser?.email.lowercased() ?? ""
    }

    private var playlistVideos: [Video] {
        playlist.videoIDs.compactMap { id in
            videoStore.videos.first { $0.id == id }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.11)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(playlist.name)
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)

                        Text("\(playlistVideos.count) videos")
                            .foregroundColor(.gray)

                        if playlistVideos.isEmpty {
                            Text("No videos in this playlist yet.")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            ForEach(playlistVideos) { video in
                                HStack(spacing: 12) {
                                    playlistThumbnail(video)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(video.title)
                                            .font(.headline.bold())
                                            .foregroundColor(.white)
                                            .lineLimit(2)

                                        Text("\(video.views) views")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Button {
                                        playlistStore.removeVideo(video, from: playlist, for: currentEmail)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(12)
                                .background(Color.gray.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func playlistThumbnail(_ video: Video) -> some View {
        ZStack {
            if let image = loadImage(video.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.white.opacity(0.55))
                    )
            }
        }
        .frame(width: 122, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
