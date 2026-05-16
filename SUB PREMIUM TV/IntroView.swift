import SwiftUI

struct IntroView: View {
    @Binding var showIntro: Bool

    @State private var playScale: CGFloat = 0.3
    @State private var playOpacity = 0.0
    @State private var glow = false

    @State private var subOffset: CGFloat = -220
    @State private var premiumOffset: CGFloat = 240
    @State private var tvOpacity = 0.0

    @State private var taglineOpacity = 0.0
    @State private var finalFade = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.10, green: 0.10, blue: 0.11),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.red.opacity(glow ? 0.28 : 0.08))
                .frame(width: glow ? 270 : 160, height: glow ? 270 : 160)
                .blur(radius: 35)

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.45), lineWidth: 2)
                        .frame(width: 118, height: 118)
                        .scaleEffect(glow ? 1.25 : 0.85)
                        .opacity(glow ? 0.15 : 0.85)

                    Image(systemName: "play.fill")
                        .font(.system(size: 62, weight: .black))
                        .foregroundColor(.red)
                        .scaleEffect(playScale)
                        .opacity(playOpacity)
                        .shadow(color: .red.opacity(glow ? 1 : 0.35), radius: glow ? 28 : 8)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text("SUB")
                            .offset(x: subOffset)

                        Text("PREMIUM")
                            .offset(x: premiumOffset)
                    }
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .red.opacity(0.65), radius: 12)

                    Text("TV")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                        .opacity(tvOpacity)
                        .tracking(8)
                }

                Text("Watch • Upload • Stream")
                    .font(.headline.bold())
                    .foregroundColor(.white.opacity(0.72))
                    .opacity(taglineOpacity)
            }
            .opacity(finalFade ? 0 : 1)
            .scaleEffect(finalFade ? 1.08 : 1)
        }
        .onAppear {
            runIntro()
        }
    }

    private func runIntro() {
        withAnimation(.spring(response: 0.75, dampingFraction: 0.55)) {
            playScale = 1
            playOpacity = 1
        }

        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            glow = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.70)) {
                subOffset = 0
                premiumOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.45)) {
                tvOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.55)) {
                taglineOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                finalFade = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            showIntro = false
        }
    }
}
