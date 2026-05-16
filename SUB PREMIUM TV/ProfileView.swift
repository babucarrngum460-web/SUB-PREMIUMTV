import SwiftUI
import UIKit
import PhotosUI

enum ProfileTab: String, CaseIterable {
    case home = "Home"
    case videos = "Videos"
    case saved = "Saved"
    case history = "History"
    case about = "About"
}

struct ProfileView: View {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var store = VideoStore.shared

    @State private var selectedTab: ProfileTab = .home
    @State private var showEditProfile = false
    @State private var showLogoutAlert = false
    @State private var copied = false

    private var user: UserAccount? {
        auth.currentUser
    }

    private var isLoggedIn: Bool {
        auth.isLoggedIn && auth.currentUser != nil
    }

    private var displayName: String {
        let name = user?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "SUB TV USER" : name.uppercased()
    }

    private var username: String {
        let handle = user?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return handle.isEmpty ? "username005" : handle.lowercased()
    }

    private var email: String {
        user?.email.lowercased() ?? ""
    }

    private var bio: String {
        let value = user?.bio.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "No bio yet." : value
    }

    private var profileLink: String {
        "subpremiumtv://user/\(username)"
    }

    private var userVideos: [Video] {
        store.newestVideos.filter {
            $0.creatorName.lowercased() == displayName.lowercased() ||
            $0.creatorName.lowercased() == username.lowercased() ||
            $0.creatorName.lowercased() == "sub premium tv"
        }
    }

    private var totalViews: Int {
        userVideos.reduce(0) { $0 + $1.views }
    }

    private var totalLikes: Int {
        userVideos.reduce(0) { $0 + $1.likes }
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

                if isLoggedIn {
                    loggedInProfile
                } else {
                    loginRequiredView
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
            }
            .alert("Log out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    auth.logout()
                }

                Button("Cancel", role: .cancel) { }
            }
            .alert("Copied", isPresented: $copied) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Profile link copied.")
            }
        }
    }
}

// MARK: - Logged In Profile

private extension ProfileView {
    var loggedInProfile: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                topBar
                profileHeader
                statsSection
                tabBar
                tabContent
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 110)
        }
    }

    var topBar: some View {
        HStack {
            Text("Profile")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)

            Spacer()

            Button {
                showEditProfile = true
            } label: {
                Image(systemName: "pencil")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    UIPasteboard.general.string = profileLink
                    copied = true
                } label: {
                    Label("Copy Profile Link", systemImage: "doc.on.doc")
                }

                Button {
                    showEditProfile = true
                } label: {
                    Label("Edit Account Info", systemImage: "person.crop.circle")
                }

                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.top, 12)
    }

    var profileHeader: some View {
        VStack(spacing: 14) {
            profileAvatar(size: 126)

            Text(displayName)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("@\(username)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)

            Text(bio)
                .font(.body)
                .foregroundColor(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            HStack(spacing: 12) {
                Button {
                    showEditProfile = true
                } label: {
                    Text("Edit Profile")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Button {
                    UIPasteboard.general.string = profileLink
                    copied = true
                } label: {
                    Text("Copy Link")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.25))
                        .clipShape(Capsule())
                }
            }
        }
    }

    var statsSection: some View {
        HStack(spacing: 0) {
            compactStat(value: "\(userVideos.count)", title: "Videos")

            Divider()
                .frame(height: 34)
                .overlay(Color.white.opacity(0.18))

            compactStat(value: "\(totalViews)", title: "Views")

            Divider()
                .frame(height: 34)
                .overlay(Color.white.opacity(0.18))

            compactStat(value: "\(totalLikes)", title: "Likes")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    func compactStat(value: String, title: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    var accountSecuritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Security")
                .font(.title3.bold())
                .foregroundColor(.white)

            securityRow(icon: "envelope.fill", title: "Email", value: email.isEmpty ? "No email" : email)
            securityRow(icon: "lock.fill", title: "Password", value: "Protected")
            securityRow(icon: "person.text.rectangle.fill", title: "Recovery", value: "Use email/password recovery")
        }
        .padding(16)
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func securityRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
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

    var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProfileTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.headline.bold())
                            .foregroundColor(selectedTab == tab ? .black : .white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(selectedTab == tab ? Color.white : Color.gray.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    var tabContent: some View {
        switch selectedTab {
        case .home:
            videoSection(title: "My Latest Videos", videos: userVideos)
            videoSection(title: "Saved Videos", videos: store.savedVideos)

        case .videos:
            videoSection(title: "All My Videos", videos: userVideos)

        case .saved:
            videoSection(title: "Saved Videos", videos: store.savedVideos)

        case .history:
            videoSection(title: "Watch History", videos: store.watchHistory)

        case .about:
            aboutSection
        }
    }
}

// MARK: - Videos

private extension ProfileView {
    func videoSection(title: String, videos: [Video]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)

            if videos.isEmpty {
                Text("No videos yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(videos) { video in
                            NavigationLink {
                                VideoDetailView(video: video)
                            } label: {
                                ProfileVideoCard(video: video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    var aboutSection: some View {
        VStack(spacing: 12) {
            aboutRow(title: "Name", value: displayName)
            aboutRow(title: "Username", value: "@\(username)")
            aboutRow(title: "Email", value: email)
            aboutRow(title: "Bio", value: bio)
            aboutRow(title: "Profile Link", value: profileLink)
        }
    }

    func aboutRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Login Required

private extension ProfileView {
    var loginRequiredView: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("Login Required")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(.white)

            Text("Please log in to view your profile, videos, likes, saved videos, and account security.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            NavigationLink {
                AuthView()
            } label: {
                Text("Log In / Create Account")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 30)
            }
        }
    }
}

// MARK: - Helpers

private extension ProfileView {
    func profileAvatar(size: CGFloat) -> some View {
        Group {
            if let image = loadImage(user?.avatarPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Text(String(displayName.prefix(1)).uppercased())
                            .font(.system(size: size * 0.42, weight: .black))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5))
    }

    func loadImage(_ path: String?) -> UIImage? {
        guard let path else { return nil }
        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        if clean.hasPrefix("file://"), let url = URL(string: clean) {
            return UIImage(contentsOfFile: url.path)
        }

        if FileManager.default.fileExists(atPath: clean) {
            return UIImage(contentsOfFile: clean)
        }

        return nil
    }
}

// MARK: - Profile Video Card

struct ProfileVideoCard: View {
    let video: Video

    @StateObject private var progressStore = WatchProgressStore.shared

    private var progress: Double {
        progressStore.progress(for: video.id)
    }

    private var isContinueWatching: Bool {
        progressStore.shouldContinue(video.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .bottomTrailing) {
                posterImage
                    .frame(width: 260, height: 150)
                    .clipped()

                VStack {
                    Spacer()

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.black.opacity(0.55))
                                .frame(height: 5)

                            Rectangle()
                                .fill(Color.red)
                                .frame(
                                    width: geo.size.width * progress,
                                    height: 5
                                )
                        }
                    }
                    .frame(height: 5)
                }

                VStack {
                    HStack {
                        if isContinueWatching {
                            Text("\(Int(progress * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }

                        Spacer()
                    }
                    .padding(8)

                    Spacer()

                    HStack {
                        Spacer()

                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")

                            Text(isContinueWatching ? "Resume" : "Play")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.72))
                        .clipShape(Capsule())
                        .padding(8)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(video.title)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 260, alignment: .leading)

            Text("\(video.creatorName) • \(video.views) views")
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 260, alignment: .leading)
        }
        .frame(width: 260)
    }

    private var posterImage: some View {
        Group {
            if let image = loadImage(video.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.55))
                    )
            }
        }
    }

    private func loadImage(_ path: String?) -> UIImage? {
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

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthManager.shared

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var avatarPath: String?
    @State private var selectedImage: PhotosPickerItem?
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.11).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        avatarPreview

                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            Text("Change Profile Image")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.25))
                                .clipShape(Capsule())
                        }

                        input("Name", text: $name)
                        input("Username example: username005", text: $username)
                        input("Bio", text: $bio)

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }

                        Button {
                            save()
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
                    .padding(18)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                name = auth.currentUser?.name ?? ""
                username = auth.currentUser?.username ?? ""
                bio = auth.currentUser?.bio ?? ""
                avatarPath = auth.currentUser?.avatarPath
            }
            .onChange(of: selectedImage) { _, newItem in
                loadImage(newItem)
            }
        }
    }

    private var avatarPreview: some View {
        Group {
            if let image = imageFromPath(avatarPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
    }

    private func input(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    private func save() {
        let result = auth.updateProfile(
            name: name,
            username: username,
            bio: bio,
            avatarPath: avatarPath
        )

        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func loadImage(_ item: PhotosPickerItem?) {
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

    private func saveImage(_ image: UIImage) -> String? {
        let fileName = "profile_\(UUID().uuidString).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }

        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    private func imageFromPath(_ path: String?) -> UIImage? {
        guard let path else { return nil }
        return FileManager.default.fileExists(atPath: path) ? UIImage(contentsOfFile: path) : nil
    }
}
