import Foundation

@MainActor
final class WatchProgressStore: ObservableObject {
    static let shared = WatchProgressStore()

    @Published private(set) var progressByVideoID: [UUID: Double] = [:] {
        didSet { save() }
    }

    @Published private(set) var lastPositionByVideoID: [UUID: Double] = [:] {
        didSet { save() }
    }

    private let progressKey = "subpremium_tv_watch_progress"
    private let positionKey = "subpremium_tv_watch_positions"

    private init() {
        load()
    }

    func saveProgress(videoID: UUID, currentTime: Double, duration: Double) {
        guard duration > 0 else { return }

        let progress = min(max(currentTime / duration, 0), 1)

        if progress >= 0.96 {
            progressByVideoID[videoID] = 1
            lastPositionByVideoID[videoID] = 0
        } else {
            progressByVideoID[videoID] = progress
            lastPositionByVideoID[videoID] = currentTime
        }
    }

    func savedPosition(for videoID: UUID) -> Double {
        lastPositionByVideoID[videoID] ?? 0
    }

    func progress(for videoID: UUID) -> Double {
        progressByVideoID[videoID] ?? 0
    }

    func shouldContinue(_ videoID: UUID) -> Bool {
        let progress = progress(for: videoID)
        return progress > 0.02 && progress < 0.96
    }

    func removeProgress(for videoID: UUID) {
        progressByVideoID[videoID] = nil
        lastPositionByVideoID[videoID] = nil
    }

    private func save() {
        let progressData = progressByVideoID.mapKeys { $0.uuidString }
        let positionData = lastPositionByVideoID.mapKeys { $0.uuidString }

        if let data = try? JSONEncoder().encode(progressData) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }

        if let data = try? JSONEncoder().encode(positionData) {
            UserDefaults.standard.set(data, forKey: positionKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            progressByVideoID = decoded.compactMapKeys { UUID(uuidString: $0) }
        }

        if let data = UserDefaults.standard.data(forKey: positionKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            lastPositionByVideoID = decoded.compactMapKeys { UUID(uuidString: $0) }
        }
    }
}

private extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        Dictionary<T, Value>(
            uniqueKeysWithValues: map { (transform($0.key), $0.value) }
        )
    }

    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        Dictionary<T, Value>(
            uniqueKeysWithValues: compactMap {
                guard let key = transform($0.key) else { return nil }
                return (key, $0.value)
            }
        )
    }
}
