import SwiftUI

struct RulesGuidelinesView: View {

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    ruleCard(
                        icon: "play.rectangle.fill",
                        title: "Upload Real Videos",
                        text: "Only upload videos you own or have permission to share. Do not upload stolen, copied, or harmful content."
                    )

                    ruleCard(
                        icon: "person.2.fill",
                        title: "Respect Other Users",
                        text: "No bullying, harassment, hate speech, threats, or abusive behavior toward creators or viewers."
                    )

                    ruleCard(
                        icon: "exclamationmark.shield.fill",
                        title: "No Harmful Content",
                        text: "Do not upload violent, dangerous, sexual, scam, spam, or misleading content."
                    )

                    ruleCard(
                        icon: "lock.fill",
                        title: "Account Safety",
                        text: "Keep your login information private. Use a recovery email and never share your password."
                    )

                    ruleCard(
                        icon: "flag.fill",
                        title: "Report Problems",
                        text: "If you see a problem, report it through the app or email SUB PREMIUM TV support."
                    )

                    Text("SUB PREMIUM TV may remove content or accounts that break these rules.")
                        .font(.footnote.bold())
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
                .padding(18)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var background: some View {
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rules & Guidelines")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.white)

            Text("Keep SUB PREMIUM TV safe, respectful, and professional.")
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    private func ruleCard(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundColor(.red)
                .frame(width: 52, height: 52)
                .background(Color.red.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.white)

                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.gray.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
