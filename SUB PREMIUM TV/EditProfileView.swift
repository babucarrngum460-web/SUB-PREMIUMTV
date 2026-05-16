import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthManager.shared

    @State private var name = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var avatarPath: String?
    @State private var selectedAvatarItem: PhotosPickerItem?

    @State private var errorMessage = ""
    @State private var savedMessage = ""
    @State private var showRemoveImageAlert = false

    private var currentUser: UserAccount? {
        auth.currentUser
    }

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        avatarSection
                        formSection
                        saveButton

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        if !savedMessage.isEmpty {
                            Text(savedMessage)
                                .font(.subheadline.bold())
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadProfile()
            }
            .onChange(of: selectedAvatarItem) { _, newItem in
                loadAvatar(newItem)
            }
            .alert("Remove profile image?", isPresented: $showRemoveImageAlert) {
                Button("Remove", role: .destructive) {
                    avatarPath = nil
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your avatar will be removed from your profile.")
            }
        }
    }
}

// MARK: - Layout

private extension EditProfileView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Edit Profile")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)

            Text("Update your creator identity, profile image, name, @username handle, and bio.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var avatarSection: some View {
        VStack(spacing: 14) {
            avatarPreview

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    HStack(spacing: 7) {
                        Image(systemName: "photo.fill")
                        Text("Change Image")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button(role: .destructive) {
                    showRemoveImageAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(width: 56, height: 52)
                        .background(Color.red.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Text("Profile image will show on your creator page, videos, and account settings.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
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
                        VStack(spacing: 6) {
                            Text(profileInitial)
                                .font(.system(size: 48, weight: .black))
                                .foregroundColor(.white)

                            Text("Avatar")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.55))
                        }
                    )
            }
        }
        .frame(width: 132, height: 132)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)
    }

    var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            textInput(
                title: "Display Name",
                placeholder: "Enter USER - SUB TV",
                text: $name
            )

            textInput(
                title: "@Username Handle",
                placeholder: "username005",
                text: $username
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.headline.bold())
                    .foregroundColor(.white)

                TextField("Tell viewers about your profile", text: $bio, axis: .vertical)
                    .lineLimit(3...7)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            usernameHelp
        }
        .padding(16)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    func textInput(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
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

    var usernameHelp: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Username examples")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.75))

            Text("Use names like username005 or username110. Username must be unique and secure for account recovery.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            Text("Save Changes")
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.red : Color.gray.opacity(0.30))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .disabled(!canSave)
    }
}

// MARK: - Data

private extension EditProfileView {
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var profileInitial: String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = clean.first {
            return String(first).uppercased()
        }

        return "S"
    }

    func loadProfile() {
        guard let user = currentUser else { return }

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
            savedMessage = "Profile updated successfully."
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Image

private extension EditProfileView {
    func loadAvatar(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let path = saveImage(image) {
                await MainActor.run {
                    avatarPath = path
                    errorMessage = ""
                    savedMessage = ""
                }
            }
        }
    }

    func saveImage(_ image: UIImage) -> String? {
        guard let email = auth.currentUser?.email else {
            return nil
        }

        return ProfileImageStore.shared.saveProfileImage(image, for: email)
    }

    func imageFromPath(_ path: String?) -> UIImage? {
        ProfileImageStore.shared.loadProfileImage(path: path)
    }
}
