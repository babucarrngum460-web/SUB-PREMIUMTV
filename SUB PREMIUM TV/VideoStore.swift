import Foundation
import SwiftUI

    @MainActor
    final class VideoStore: ObservableObject {
        static let shared = VideoStore()
        
        @Published var videos: [Video] = [] {
            didSet { saveVideos() }
        }
        
        @Published var likedVideoIDs: [UUID] = [] {
            didSet { saveLikedVideos() }
        }
        
        @Published var savedVideoIDs: [UUID] = [] {
            didSet { saveSavedVideos() }
        }
        
        @Published var watchHistoryIDs: [UUID] = [] {
            didSet { saveHistory() }
        }
        
        private let videosKey = "subpremium_tv_videos"
        private let likedKey = "subpremium_tv_liked_videos"
        private let savedKey = "subpremium_tv_saved_videos"
        private let historyKey = "subpremium_tv_history"
        
        private init() {
            loadAll()
        }
        
        // MARK: - Upload
        
        func addVideo(_ video: Video) {
            guard !videos.contains(where: { $0.id == video.id }) else { return }
            videos.insert(video, at: 0)
        }
        
        func uploadVideo(
            title: String,
            description: String,
            thumbnailURL: String?,
            videoURL: String?,
            category: VideoCategory
        ) {
            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !cleanTitle.isEmpty else { return }
            
            let newVideo = Video(
                title: cleanTitle,
                description: cleanDescription,
                thumbnailURL: thumbnailURL,
                videoURL: videoURL,
                category: category
            )
            
            addVideo(newVideo)
        }
        
        // MARK: - Delete / Edit
        
        func deleteVideo(_ video: Video) {
            videos.removeAll { $0.id == video.id }
            likedVideoIDs.removeAll { $0 == video.id }
            savedVideoIDs.removeAll { $0 == video.id }
            watchHistoryIDs.removeAll { $0 == video.id }
        }
        
        func updateVideo(_ updatedVideo: Video) {
            guard let index = videos.firstIndex(where: { $0.id == updatedVideo.id }) else { return }
            videos[index] = updatedVideo
        }
        
        // MARK: - Views
        
        func addView(to video: Video) {
            guard let index = videos.firstIndex(where: { $0.id == video.id }) else { return }
            videos[index].views += 1
            addToHistory(video)
        }
        
        // MARK: - Likes
        
        func isLiked(_ video: Video) -> Bool {
            likedVideoIDs.contains(video.id)
        }
        
        func toggleLike(_ video: Video) {
            guard let index = videos.firstIndex(where: { $0.id == video.id }) else { return }
            
            if likedVideoIDs.contains(video.id) {
                likedVideoIDs.removeAll { $0 == video.id }
                videos[index].likes = max(videos[index].likes - 1, 0)
            } else {
                likedVideoIDs.append(video.id)
                videos[index].likes += 1
            }
        }
        
        // MARK: - Save
        
        func isSaved(_ video: Video) -> Bool {
            savedVideoIDs.contains(video.id)
        }
        
        func toggleSave(_ video: Video) {
            if savedVideoIDs.contains(video.id) {
                savedVideoIDs.removeAll { $0 == video.id }
            } else {
                savedVideoIDs.insert(video.id, at: 0)
            }
        }
        
        var savedVideos: [Video] {
            savedVideoIDs.compactMap { id in
                videos.first { $0.id == id }
            }
        }
        
        // MARK: - History
        
        func addToHistory(_ video: Video) {
            watchHistoryIDs.removeAll { $0 == video.id }
            watchHistoryIDs.insert(video.id, at: 0)
        }
        
        var watchHistory: [Video] {
            watchHistoryIDs.compactMap { id in
                videos.first { $0.id == id }
            }
        }
        
        func clearHistory() {
            watchHistoryIDs.removeAll()
        }
        
        // MARK: - Categories
        
        func videos(for category: VideoCategory) -> [Video] {
            videos
                .filter { $0.category == category }
                .sorted { $0.createdAt > $1.createdAt }
        }
        
        var trendingVideos: [Video] {
            videos.sorted {
                let firstScore = $0.views + ($0.likes * 2)
                let secondScore = $1.views + ($1.likes * 2)
                return firstScore > secondScore
            }
        }
        
        var newestVideos: [Video] {
            videos.sorted { $0.createdAt > $1.createdAt }
        }
        
        // MARK: - Search
        
        func searchVideos(_ query: String) -> [Video] {
            let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !clean.isEmpty else { return [] }
            
            return videos.filter { video in
                video.title.lowercased().contains(clean) ||
                video.description.lowercased().contains(clean) ||
                video.creatorName.lowercased().contains(clean) ||
                video.category.rawValue.lowercased().contains(clean)
            }
        }
        
        // MARK: - Persistence
        
        private func loadAll() {
            videos = load([Video].self, key: videosKey, defaultValue: [])
            likedVideoIDs = load([UUID].self, key: likedKey, defaultValue: [])
            savedVideoIDs = load([UUID].self, key: savedKey, defaultValue: [])
            watchHistoryIDs = load([UUID].self, key: historyKey, defaultValue: [])
        }
        
        private func saveVideos() {
            save(videos, key: videosKey)
        }
        
        private func saveLikedVideos() {
            save(likedVideoIDs, key: likedKey)
        }
        
        private func saveSavedVideos() {
            save(savedVideoIDs, key: savedKey)
        }
        
        private func saveHistory() {
            save(watchHistoryIDs, key: historyKey)
        }
        
        private func save<T: Codable>(_ value: T, key: String) {
            guard let data = try? JSONEncoder().encode(value) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
        
        private func load<T: Codable>(
            _ type: T.Type,
            key: String,
            defaultValue: T
        ) -> T {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(type, from: data) else {
                return defaultValue
            }
            
            return decoded
        }
}
