import SwiftUI

struct SettingsView: View {
    @StateObject private var auth = AuthManager.shared

    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        settingsSection(title: "Account") {
                            settingLink(
                                icon: "person.crop.circle.fill",
                                title: "Account Settings",
                                subtitle: "Profile, username, email, password, recovery"
                            ) {
                                AccountSettingsView()
                            }

                            settingLink(
                                icon: "eye.slash.fill",
                                title: "Privacy",
                                subtitle: "Private account, visibility, data controls"
                            ) {
                                PrivacySettingsView()
                            }
                        }

                        settingsSection(title: "App") {
                            settingLink(
                                icon: "paintbrush.fill",
                                title: "Appearance",
                                subtitle: "Gray mode, text size, theme"
                            ) {
                                AppearanceSettingsView()
                            }

                            settingLink(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "Uploads, likes, featured alerts"
                            ) {
                                NotificationSettingsView()
                            }

                            settingLink(
                                icon: "play.rectangle.fill",
                                title: "Video & Playback",
                                subtitle: "Autoplay, quality, captions"
                            ) {
                                VideoPlaybackSettingsView()
                            }
                        }

                        settingsSection(title: "Support") {
                            settingLink(
                                icon: "questionmark.circle.fill",
                                title: "Help Center",
                                subtitle: "Support and app help"
                            ) {
                                HelpCenterView()
                            }

                            settingLink(
                                icon: "list.bullet.rectangle.fill",
                                title: "Rules & Guidelines",
                                subtitle: "Community rules and upload safety"
                            ) {
                                RulesGuidelinesView()
                            }

                            settingLink(
                                icon: "exclamationmark.bubble.fill",
                                title: "Report Issue",
                                subtitle: "Send concerns to support"
                            ) {
                                ReportIssueView()
                            }

                            settingLink(
                                icon: "info.circle.fill",
                                title: "About SUB PREMIUM TV",
                                subtitle: "Version and platform info"
                            ) {
                                AboutSubPremiumTVView()
                            }
                        }

                        logoutButton
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Log out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    auth.logout()
                }

                Button("Cancel", role: .cancel) { }
            }
        }
    }
}

private extension SettingsView {
    var background: some View {
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

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 38, weight: .black))
                .foregroundColor(.white)

            Text("Manage your SUB PREMIUM TV account and app preferences.")
                .font(.body)
                .foregroundColor(.gray)
        }
    }

    func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)

            VStack(spacing: 12) {
                content()
            }
        }
    }

    func settingLink<Destination: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundColor(.red)
                    .frame(width: 54, height: 54)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(14)
            .background(Color.gray.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    var logoutButton: some View {
        Button {
            showLogoutAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
            }
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(.top, 10)
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    @StateObject private var auth = AuthManager.shared

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    pageHeader(
                        title: "Account Settings",
                        subtitle: "Manage profile info, login, password and recovery."
                    )

                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        settingsRow(
                            icon: "person.crop.circle.fill",
                            title: "Profile Settings",
                            subtitle: "Name, username, avatar, bio"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AccountSecurityView()
                    } label: {
                        settingsRow(
                            icon: "lock.shield.fill",
                            title: "Account Security",
                            subtitle: "Email, password, recovery"
                        )
                    }
                    .buttonStyle(.plain)

                    accountInfoCard
                }
                .padding(18)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var accountInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Account")
                .font(.title3.bold())
                .foregroundColor(.white)

            infoLine("Name", auth.currentUser?.name ?? "No name")
            infoLine("Username", "@\(auth.currentUser?.username ?? "username005")")
            infoLine("Email", auth.currentUser?.email ?? "No email")
            infoLine("Status", auth.isLoggedIn ? "Logged in" : "Logged out")
        }
        .padding(16)
        .background(Color.gray.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func infoLine(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)

            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Privacy

struct PrivacySettingsView: View {
    @AppStorage("privacy_private_account") private var privateAccount = false
    @AppStorage("privacy_show_likes") private var showLikes = true
    @AppStorage("privacy_show_watch_history") private var showWatchHistory = false
    @AppStorage("privacy_allow_profile_search") private var allowProfileSearch = true
    @AppStorage("privacy_allow_messages") private var allowMessages = true

    var body: some View {
        SettingsPage(title: "Privacy", subtitle: "Control your account visibility and data.") {
            settingToggle("Private Account", "Only approved people can view your profile.", isOn: $privateAccount)
            settingToggle("Show Likes", "Allow viewers to see your liked count.", isOn: $showLikes)
            settingToggle("Show Watch History", "Display watched videos on your profile.", isOn: $showWatchHistory)
            settingToggle("Allow Profile Search", "Let users find your profile by username.", isOn: $allowProfileSearch)
            settingToggle("Allow Messages", "Let users message you in the app.", isOn: $allowMessages)
        }
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @AppStorage("appearance_gray_mode") private var grayMode = true
    @AppStorage("appearance_large_text") private var largeText = false
    @AppStorage("appearance_reduce_animation") private var reduceAnimation = false
    @AppStorage("appearance_red_accent") private var redAccent = true

    var body: some View {
        SettingsPage(title: "Appearance", subtitle: "Customize the SUB PREMIUM TV look.") {
            settingToggle("Gray Mode", "Use soft gray background instead of pure black.", isOn: $grayMode)
            settingToggle("Large Text", "Make titles and labels easier to read.", isOn: $largeText)
            settingToggle("Reduce Animation", "Reduce motion for smoother performance.", isOn: $reduceAnimation)
            settingToggle("Red Accent", "Use SUB PREMIUM TV red highlights.", isOn: $redAccent)
        }
    }
}

// MARK: - Notifications

struct NotificationSettingsView: View {
    @AppStorage("notify_new_uploads") private var newUploads = true
    @AppStorage("notify_likes") private var likes = true
    @AppStorage("notify_featured") private var featured = true
    @AppStorage("notify_playlist") private var playlist = true
    @AppStorage("notify_email") private var emailNotifications = false

    var body: some View {
        SettingsPage(title: "Notifications", subtitle: "Choose what alerts you want to receive.") {
            settingToggle("New Uploads", "Notify when creators upload videos.", isOn: $newUploads)
            settingToggle("Likes", "Notify when videos get likes.", isOn: $likes)
            settingToggle("Featured Videos", "Notify when a video becomes featured.", isOn: $featured)
            settingToggle("Playlist Updates", "Notify when videos are added to playlists.", isOn: $playlist)
            settingToggle("Email Notifications", "Send important alerts to email.", isOn: $emailNotifications)
        }
    }
}

// MARK: - Video Playback

struct VideoPlaybackSettingsView: View {
    @AppStorage("playback_autoplay") private var autoplay = true
    @AppStorage("playback_autoplay_next") private var autoplayNext = true
    @AppStorage("playback_wifi_only") private var wifiOnly = false
    @AppStorage("playback_captions") private var captions = false
    @AppStorage("playback_default_quality") private var quality = "Auto"

    private let qualityOptions = ["Auto", "1080p", "720p", "480p", "360p"]

    var body: some View {
        SettingsPage(title: "Video & Playback", subtitle: "Control video behavior and quality.") {
            settingToggle("Autoplay Preview", "Play short previews on home feed.", isOn: $autoplay)
            settingToggle("Autoplay Next Video", "Continue to the next video automatically.", isOn: $autoplayNext)
            settingToggle("Wi-Fi Only", "Use Wi-Fi for high quality playback.", isOn: $wifiOnly)
            settingToggle("Captions Default On", "Show captions when available.", isOn: $captions)

            VStack(alignment: .leading, spacing: 10) {
                Text("Default Quality")
                    .font(.headline.bold())
                    .foregroundColor(.white)

                Picker("Quality", selection: $quality) {
                    ForEach(qualityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(14)
            .background(Color.gray.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

// MARK: - Support

struct HelpCenterView: View {
    var body: some View {
        SettingsPage(title: "Help Center", subtitle: "Get support for your account and videos.") {
            helpCard("Upload Help", "Fix video upload, thumbnail, and playback issues.", "tray.and.arrow.up.fill")
            helpCard("Account Help", "Recover account, password, username, and email.", "person.crop.circle.badge.questionmark")
            helpCard("Safety & Report", "Report videos, users, or unsafe content.", "exclamationmark.shield.fill")
            helpCard("Contact Support", "Support email: support@subpremiumtv.com", "envelope.fill")
        }
    }
}

struct AboutSubPremiumTVView: View {
    var body: some View {
        SettingsPage(title: "About SUB PREMIUM TV", subtitle: "Free online OTT entertainment platform.") {
            helpCard("App Name", "SUB PREMIUM TV", "play.rectangle.fill")
            helpCard("Version", "1.0", "info.circle.fill")
            helpCard("Platform", "Upload, watch, save, like, and manage OTT videos.", "tv.fill")
            helpCard("Storage", "Videos and account data are saved locally for now.", "internaldrive.fill")
        }
    }
}

// MARK: - Reusable Page

struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    pageHeader(title: title, subtitle: subtitle)
                    content
                }
                .padding(18)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared Helpers

private var settingsBackground: some View {
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

private func pageHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.system(size: 34, weight: .black))
            .foregroundColor(.white)

        Text(subtitle)
            .font(.body)
            .foregroundColor(.gray)
    }
}

private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
    HStack(spacing: 14) {
        Image(systemName: icon)
            .font(.title2.bold())
            .foregroundColor(.red)
            .frame(width: 54, height: 54)
            .background(Color.red.opacity(0.15))
            .clipShape(Circle())

        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }

        Spacer()

        Image(systemName: "chevron.right")
            .font(.title3.bold())
            .foregroundColor(.white.opacity(0.35))
    }
    .padding(14)
    .background(Color.gray.opacity(0.16))
    .clipShape(RoundedRectangle(cornerRadius: 22))
}

private func settingToggle(_ title: String, _ subtitle: String, isOn: Binding<Bool>) -> some View {
    Toggle(isOn: isOn) {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    .tint(.red)
    .padding(14)
    .background(Color.gray.opacity(0.16))
    .clipShape(RoundedRectangle(cornerRadius: 18))
}

private func helpCard(_ title: String, _ subtitle: String, _ icon: String) -> some View {
    HStack(spacing: 14) {
        Image(systemName: icon)
            .font(.title2.bold())
            .foregroundColor(.red)
            .frame(width: 54, height: 54)
            .background(Color.red.opacity(0.15))
            .clipShape(Circle())

        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }

        Spacer()
    }
    .padding(14)
    .background(Color.gray.opacity(0.16))
    .clipShape(RoundedRectangle(cornerRadius: 18))
}
