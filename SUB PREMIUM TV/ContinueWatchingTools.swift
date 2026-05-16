import SwiftUI

@MainActor
struct ContinueWatchingTools {

    static func resumeTitle(for video: Video) -> String {
        let progress = WatchProgressStore.shared.progress(for: video.id)

        if progress > 0.02 && progress < 0.96 {
            return "Resume \(Int(progress * 100))%"
        }

        return "Play"
    }

    static func shouldShow(_ video: Video) -> Bool {
        WatchProgressStore.shared.shouldContinue(video.id)
    }

    static func remove(_ video: Video) {
        WatchProgressStore.shared.removeProgress(for: video.id)
    }

    static func clearCompleted(videos: [Video]) {
        for video in videos {
            let progress = WatchProgressStore.shared.progress(for: video.id)

            if progress >= 0.96 {
                WatchProgressStore.shared.removeProgress(for: video.id)
            }
        }
    }
}
