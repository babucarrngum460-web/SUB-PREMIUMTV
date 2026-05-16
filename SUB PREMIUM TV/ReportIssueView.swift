import SwiftUI
import UIKit

struct ReportIssueView: View {
    @StateObject private var auth = AuthManager.shared

    @State private var issueTitle = ""
    @State private var issueMessage = ""
    @State private var copied = false

    private let supportEmail = "subpremium760@gmail.com"

    private var reportText: String {
        """
        SUB PREMIUM TV REPORT

        From:
        \(auth.currentUser?.name ?? "Unknown User")
        @\(auth.currentUser?.username ?? "unknown")
        \(auth.currentUser?.email ?? "No email")

        Issue:
        \(issueTitle)

        Message:
        \(issueMessage)
        """
    }

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    TextField("Issue title", text: $issueTitle)
                        .fieldStyle()

                    TextField("Explain the issue or concern...", text: $issueMessage, axis: .vertical)
                        .lineLimit(6...10)
                        .fieldStyle()

                    Button {
                        UIPasteboard.general.string = reportText
                        copied = true
                    } label: {
                        actionLabel("Copy Report Message", "doc.on.doc.fill", .white)
                    }

                    Button {
                        openEmail()
                    } label: {
                        actionLabel("Send Email to Support", "envelope.fill", .red)
                    }

                    Text("Support email: \(supportEmail)")
                        .font(.footnote.bold())
                        .foregroundColor(.gray)

                    if copied {
                        Text("Report copied. Paste it into email or messages.")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                }
                .padding(18)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle("Report Issue")
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
            Text("Report Issue")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.white)

            Text("Send problems, concerns, video reports, account issues, or feedback to support.")
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    private func actionLabel(_ title: String, _ icon: String, _ color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline.bold())
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(color == .red ? Color.red : Color.gray.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func openEmail() {
        let subject = "SUB PREMIUM TV Report"
        let body = reportText

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

private extension View {
    func fieldStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()
    }
}
