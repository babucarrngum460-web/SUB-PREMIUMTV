import Foundation
import AVKit
import SwiftUI

@MainActor
final class MiniPlayerManager: ObservableObject {
    static let shared = MiniPlayerManager()

    @Published var isVisible: Bool = false
    @Published var video: Video?
    @Published var player: AVPlayer?
    @Published var offset: CGSize = .zero

    private init() { }

    func show(video: Video, player: AVPlayer?) {
        self.video = video
        self.player = player
        self.isVisible = true
        self.offset = .zero
        self.player?.play()
    }

    func hide() {
        player?.pause()
        player = nil
        video = nil
        isVisible = false
        offset = .zero
    }

    func playPause() {
        guard let player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    func rewind10() {
        guard let player else { return }

        let current = player.currentTime().seconds
        let newTime = max(current - 10, 0)

        player.seek(
            to: CMTime(seconds: newTime, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func forward10() {
        guard let player else { return }

        let current = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? current + 10
        let newTime = min(current + 10, duration)

        player.seek(
            to: CMTime(seconds: newTime, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func updateOffset(_ value: CGSize) {
        offset = value
    }

    func resetPosition() {
        withAnimation(.spring()) {
            offset = .zero
        }
    }
}
