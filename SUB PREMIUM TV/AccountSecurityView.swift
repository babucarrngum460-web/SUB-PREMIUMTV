import SwiftUI

struct AccountSecurityView: View {
    @StateObject private var auth = AuthManager.shared

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var recoveryEmail = ""

    @State private var showPasswords = false
    @State private var message = ""
    @State private var isSuccess = false
    @State private var showLogoutAlert = false

    private var currentUser: UserAccount? {
        auth.currentUser
    }

    private var emailText: String {
        currentUser?.email.lowercased() ?? "No email found"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.13),
                    Color(red: 0.07, green: 0.07, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    accountInfoSection
                    passwordSection
                    recoverySection
                    sessionSection

                    if !message.isEmpty {
                        Text(message)
                            .font(.subheadline.bold())
                            .foregroundColor(isSuccess ? .green : .red)
                            .padding(.top, 4)
                    }
                }
                .padding(18)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle("Account Security")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            recoveryEmail = currentUser?.email ?? ""
        }
        .alert("Log out?", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) {
                auth.logout()
            }

            Button("Cancel", role: .cancel) { }
        }
    }
}

private extension AccountSecurityView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Account Security")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)

            Text("Protect your SUB PREMIUM TV account with email, password, and recovery tools.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    var accountInfoSection: some View {
        securitySection(title: "Account Info") {
            infoRow(
                icon: "person.fill",
                title: "User",
                value: currentUser?.name.isEmpty == false ? currentUser?.name ?? "SUB TV USER" : "SUB TV USER"
            )

            infoRow(
                icon: "at",
                title: "Username",
                value: "@\(currentUser?.username ?? "username005")"
            )

            infoRow(
                icon: "envelope.fill",
                title: "Email",
                value: emailText
            )
        }
    }

    var passwordSection: some View {
        securitySection(title: "Change Password") {
            secureInput(
                title: "Current Password",
                placeholder: "Enter current password",
                text: $currentPassword
            )

            secureInput(
                title: "New Password",
                placeholder: "Enter new password",
                text: $newPassword
            )

            secureInput(
                title: "Confirm New Password",
                placeholder: "Confirm password",
                text: $confirmPassword
            )

            Toggle(isOn: $showPasswords) {
                Text("Show passwords")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .tint(.red)

            Button {
                changePassword()
            } label: {
                Text("Update Password")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    var recoverySection: some View {
        securitySection(title: "Recovery Email") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recovery Email")
                    .font(.headline.bold())
                    .foregroundColor(.white)

                TextField("Enter recovery email", text: $recoveryEmail)
                    .foregroundColor(.white)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.gray.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button {
                saveRecoveryEmail()
            } label: {
                Text("Save Recovery Email")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Text("Recovery email helps you reset your password if you forget it.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    var sessionSection: some View {
        securitySection(title: "Session") {
            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            Text("Logging out protects your account on shared devices.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    func securitySection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)

            content()
        }
        .padding(16)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline.bold())
                .foregroundColor(.red)
                .frame(width: 36, height: 36)
                .background(Color.red.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.gray)

                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    func secureInput(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)

            Group {
                if showPasswords {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .foregroundColor(.white)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color.gray.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

private extension AccountSecurityView {

    func changePassword() {
        message = ""
        isSuccess = false

        guard !currentPassword.isEmpty else {
            message = "Enter your current password."
            return
        }

        guard newPassword.count >= 6 else {
            message = "New password must be at least 6 characters."
            return
        }

        guard newPassword == confirmPassword else {
            message = "New passwords do not match."
            return
        }

        guard var user = auth.currentUser else {
            message = "No logged-in account found."
            return
        }

        guard user.password == currentPassword else {
            message = "Current password is incorrect."
            return
        }

        user.password = newPassword

        if let index = auth.users.firstIndex(where: { $0.id == user.id }) {
            auth.users[index] = user
        }

        auth.currentUser = user

        currentPassword = ""
        newPassword = ""
        confirmPassword = ""

        isSuccess = true
        message = "Password updated successfully."
    }

    func saveRecoveryEmail() {
        message = ""
        isSuccess = false

        let clean = recoveryEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard clean.contains("@"), clean.contains(".") else {
            message = "Enter a valid recovery email."
            return
        }

        UserDefaults.standard.set(clean, forKey: "subpremium_tv_recovery_email")

        isSuccess = true
        message = "Recovery email saved."
    }
}
