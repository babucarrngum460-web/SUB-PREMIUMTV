import SwiftUI
import AVKit

struct MiniPlayerView: View {
    @StateObject private var mini = MiniPlayerManager.shared

    @GestureState private var dragOffset: CGSize = .zero

    private var totalOffset: CGSize {
        CGSize(
            width: mini.offset.width + dragOffset.width,
            height: mini.offset.height + dragOffset.height
        )
    }

    var body: some View {
        if mini.isVisible, let player = mini.player, let video = mini.video {
            VStack(spacing: 8) {
                VideoPlayer(player: player)
                    .frame(width: 150, height: 150)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(video.title)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: 150)

                HStack(spacing: 14) {
                    Button {
                        mini.rewind10()
                    } label: {
                        Image(systemName: "gobackward.10")
                    }

                    Button {
                        mini.playPause()
                    } label: {
                        Image(systemName: "playpause.fill")
                    }

                    Button {
                        mini.forward10()
                    } label: {
                        Image(systemName: "goforward.10")
                    }

                    Button {
                        mini.hide()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                .font(.headline.bold())
                .foregroundColor(.white)
            }
            .padding(10)
            .background(Color.black.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(radius: 12)
            .offset(totalOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        mini.updateOffset(
                            CGSize(
                                width: mini.offset.width + value.translation.width,
                                height: mini.offset.height + value.translation.height
                            )
                        )
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 18)
            .padding(.bottom, 90)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(999)
        }
    }
}
