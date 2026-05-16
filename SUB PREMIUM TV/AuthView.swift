import SwiftUI

struct AuthView: View {
    @StateObject private var auth = AuthManager.shared

    @State private var isRegister = false
    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
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

                ScrollView {
                    VStack(spacing: 18) {
                        Text("SUB PREMIUM TV")
                            .font(.system(size: 34, weight: .black))
                            .foregroundColor(.red)

                        Text(isRegister ? "Create Account" : "Login")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        if isRegister {
                            input("Name", text: $name)
                            input("Username example: username005", text: $username)
                            input("Bio", text: $bio)
                        }

                        input("Email", text: $email)

                        SecureField("Password", text: $password)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline.bold())
                        }

                        Button {
                            submit()
                        } label: {
                            Text(isRegister ? "Create Account" : "Login")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        Button {
                            isRegister.toggle()
                            errorMessage = ""
                        } label: {
                            Text(isRegister ? "Already have an account? Login" : "Create new account")
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(22)
                }
            }
        }
    }

    func input(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    func submit() {
        errorMessage = ""

        if isRegister {
            let result = auth.register(
                name: name,
                username: username,
                bio: bio,
                email: email,
                password: password
            )

            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
        } else {
            let result = auth.login(
                email: email,
                password: password
            )

            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
            }
        }
    }
}
