import SwiftUI
import UIKit

struct SearchView: View {
    @StateObject private var store = VideoStore.shared
    @StateObject private var progressStore = WatchProgressStore.shared

    @State private var searchText = ""
    @State private var recentSearches: [String] = []
    @State private var showClearAlert = false

    private let recentKey = "subpremium_tv_recent_searches"

    private var cleanSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [Video] {
        cleanSearch.isEmpty ? store.newestVideos : store.searchVideos(cleanSearch)
    }

    private var continueWatchingVideos: [Video] {
        store.newestVideos.filter {
            progressStore.shouldContinue($0.id)
        }
    }

    private var recentVideos: [Video] {
        store.newestVideos
    }

    private var favoriteVideos: [Video] {
        store.savedVideos
    }

    private var trendingVideos: [Video] {
        store.trendingVideos
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        searchBar

                        if !recentSearches.isEmpty {
                            recentSearchSection
                        }

                        if cleanSearch.isEmpty {
                            if !continueWatchingVideos.isEmpty {
                                videoSection(title: "Continue Watching", videos: continueWatchingVideos)
                            }

                            videoSection(title: "Recent Videos", videos: recentVideos)

                            if !favoriteVideos.isEmpty {
                                videoSection(title: "Favorites", videos: favoriteVideos)
                            }

                            if !trendingVideos.isEmpty {
                                videoSection(title: "Trending", videos: trendingVideos)
                            }

                            videoSection(title: "All Videos", videos: store.newestVideos)
                        } else {
                            searchResultsHeader
                            videoSection(title: "Search Results", videos: results)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRecentSearches()
        }
        .alert("Clear search history?", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) {
                clearRecentSearches()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This only clears search history. Videos will not be deleted.")
        }
    }
}

// MARK: - Main Layout

private extension SearchView {
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

    var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Search")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)

                Text("Find videos, creators, favorites, and continue watching.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button {
                    copyRecentSearches()
                } label: {
                    Label("Copy Recent Searches", systemImage: "doc.on.doc")
                }

                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("Clear Search History", systemImage: "trash")
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
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.55))

            TextField("Search videos...", text: $searchText)
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    saveSearch(searchText)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.gray.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 18)
    }

    var searchResultsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Results for “\(cleanSearch)”")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("\(results.count) videos found")
                .font(.caption.bold())
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 18)
    }
}

// MARK: - Recent Searches

private extension SearchView {
    var recentSearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Spacer()

                Button {
                    showClearAlert = true
                } label: {
                    Text("Clear")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentSearches, id: \.self) { item in
                        Button {
                            searchText = item
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text(item)
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.gray.opacity(0.25))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}

// MARK: - Video Sections

private extension SearchView {
    func videoSection(title: String, videos: [Video]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Spacer()

                if !videos.isEmpty {
                    Text("\(videos.count)")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 18)

            if videos.isEmpty {
                emptyVideosCard(title: title)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(videos) { video in
                            NavigationLink {
                                VideoDetailView(video: video)
                            } label: {
                                SearchVideoCard(video: video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
        }
    }

    func emptyVideosCard(title: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 42))
                .foregroundColor(.white.opacity(0.35))

            Text("No videos yet")
                .font(.headline.bold())
                .foregroundColor(.white.opacity(0.7))

            Text("Upload videos to see them in \(title).")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 18)
    }
}

// MARK: - Search History Helpers

private extension SearchView {
    func saveSearch(_ value: String) {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        recentSearches.removeAll { $0.lowercased() == clean.lowercased() }
        recentSearches.insert(clean, at: 0)

        if recentSearches.count > 20 {
            recentSearches = Array(recentSearches.prefix(20))
        }

        UserDefaults.standard.set(recentSearches, forKey: recentKey)
    }

    func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: recentKey)
    }

    func copyRecentSearches() {
        UIPasteboard.general.string = recentSearches.joined(separator: "\n")
    }
}

// MARK: - Video Card

struct SearchVideoCard: View {
    @StateObject private var store = VideoStore.shared
    @StateObject private var progressStore = WatchProgressStore.shared

    let video: Video

    private var progress: Double {
        progressStore.progress(for: video.id)
    }

    private var isContinueWatching: Bool {
        progressStore.shouldContinue(video.id)
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
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.black.opacity(0.55))
                                .frame(height: 5)

                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * progress, height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                VStack {
                    HStack {
                        if isContinueWatching {
                            Text("\(Int(progress * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        Menu {
                            Button {
                                store.toggleSave(video)
                            } label: {
                                Label(
                                    store.isSaved(video) ? "Remove Favorite" : "Add to Favorites",
                                    systemImage: store.isSaved(video) ? "bookmark.slash" : "bookmark"
                                )
                            }

                            Button {
                                UIPasteboard.general.string = video.title
                            } label: {
                                Label("Copy Title", systemImage: "doc.on.doc")
                            }

                            Button {
                                WatchProgressStore.shared.removeProgress(for: video.id)
                            } label: {
                                Label("Remove Progress", systemImage: "xmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.black.opacity(0.55))
                                .clipShape(Circle())
                        }
                    }
                    .padding(8)

                    Spacer()

                    HStack {
                        Spacer()

                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")
                            Text(isContinueWatching ? "Resume" : "Play")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.72))
                        .clipShape(Capsule())
                        .padding(8)
                    }
                }
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
