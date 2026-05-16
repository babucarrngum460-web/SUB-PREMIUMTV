import SwiftUI
import PhotosUI
import UIKit

struct ProfileSettingsView: View {
    @StateObject private var auth = AuthManager.shared

    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var avatarPath: String?
    @State private var selectedImage: PhotosPickerItem?

    @State private var errorMessage = ""
    @State private var savedMessage = ""

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
                VStack(spacing: 20) {
                    header
                    avatarSection
                    formSection
                    saveButton

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline.bold())
                    }

                    if !savedMessage.isEmpty {
                        Text(savedMessage)
                            .foregroundColor(.green)
                            .font(.subheadline.bold())
                    }
                }
                .padding(18)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUser()
        }
        .onChange(of: selectedImage) { _, newItem in
            loadAvatar(newItem)
        }
    }
}

private extension ProfileSettingsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profile Settings")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)

            Text("Edit your creator name, @username handle, bio and profile image.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var avatarSection: some View {
        VStack(spacing: 14) {
            avatarPreview

            PhotosPicker(selection: $selectedImage, matching: .images) {
                Text("Change Profile Image")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.25))
                    .clipShape(Capsule())
            }

            Button(role: .destructive) {
                avatarPath = nil
            } label: {
                Text("Remove Image")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    var avatarPreview: some View {
        Group {
            if let image = imageFromPath(avatarPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Text(String(displayInitial.prefix(1)).uppercased())
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 128, height: 128)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5))
    }

    var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            inputBlock(title: "Creator Name", placeholder: "Enter USER - SUB TV", text: $name)

            inputBlock(title: "@Username Handle", placeholder: "username005", text: $username)

            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.headline.bold())
                    .foregroundColor(.white)

                TextField("Tell viewers about your channel", text: $bio, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            usernameRules
        }
        .padding(16)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    func inputBlock(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)

            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    var usernameRules: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Username rules")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.75))

            Text("Use 5–20 characters, lowercase letters, numbers, or underscore. Example: username005 or username110.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            Text("Save Profile")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    var displayInitial: String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? "S" : clean
    }
}

private extension ProfileSettingsView {
    func loadUser() {
        guard let user = auth.currentUser else { return }

        name = user.name
        username = user.username
        bio = user.bio
        avatarPath = user.avatarPath
    }

    func saveProfile() {
        errorMessage = ""
        savedMessage = ""

        let result = auth.updateProfile(
            name: name,
            username: username,
            bio: bio,
            avatarPath: avatarPath
        )

        switch result {
        case .success:
            savedMessage = "Profile saved successfully."
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func loadAvatar(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let path = saveImage(image) {
                await MainActor.run {
                    avatarPath = path
                }
            }
        }
    }

    func saveImage(_ image: UIImage) -> String? {
        let fileName = "profile_avatar_\(UUID().uuidString).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            return nil
        } 

        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    func imageFromPath(_ path: String?) -> UIImage? {
        guard let path else { return nil }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        if clean.hasPrefix("file://"),
           let url = URL(string: clean) {
            return UIImage(contentsOfFile: url.path)
        }

        if FileManager.default.fileExists(atPath: clean) {
            return UIImage(contentsOfFile: clean)
        }

        return nil
    }
}
