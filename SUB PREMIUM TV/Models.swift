import Foundation

enum VideoCategory: String, CaseIterable, Codable {
    case movies = "Movies"
    case series = "Series"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case music = "Music"
}

struct Video: Identifiable, Codable, Hashable {

    let id: UUID

    var title: String
    var description: String

    var thumbnailURL: String?
    var videoURL: String?

    var category: VideoCategory

    var creatorName: String

    var createdAt: Date

    var views: Int
    var likes: Int

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        thumbnailURL: String? = nil,
        videoURL: String? = nil,
        category: VideoCategory = .movies,
        creatorName: String = "SUB PREMIUM TV",
        createdAt: Date = Date(),
        views: Int = 0,
        likes: Int = 0
    ) {

        self.id = id
        self.title = title
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.category = category
        self.creatorName = creatorName
        self.createdAt = createdAt
        self.views = views
        self.likes = likes
    }
}
