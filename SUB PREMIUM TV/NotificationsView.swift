import SwiftUI
import UIKit

struct NotificationsView: View {
    @StateObject private var store = VideoStore.shared

    @State private var searchText = ""
    @State private var showClearAlert = false
    @State private var clearedNotificationIDs: Set<String> = []

    private let clearedKey = "subpremium_tv_cleared_notifications"

    private var notifications: [AppNotification] {
        var items: [AppNotification] = []

        for video in store.newestVideos {
            items.append(
                AppNotification(
                    title: "New video uploaded",
                    message: "\(video.creatorName) uploaded \(video.title)",
                    video: video,
                    kind: "Upload",
                    date: video.createdAt
                )
            )

            if video.likes > 0 {
                items.append(
                    AppNotification(
                        title: "USER liked a video",
                        message: "USER • \(video.title) has \(video.likes) likes",
                        video: video,
                        kind: "Like",
                        date: video.createdAt
                    )
                )
            }

            if store.trendingVideos.contains(where: { $0.id == video.id }) {
                items.append(
                    AppNotification(
                        title: "Featured video",
                        message: "\(video.title) is trending now",
                        video: video,
                        kind: "Featured",
                        date: video.createdAt
                    )
                )
            }
        }

        let clean = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items
            .filter { !clearedNotificationIDs.contains(notificationKey($0)) }
            .filter {
                clean.isEmpty ||
                $0.title.lowercased().contains(clean) ||
                $0.message.lowercased().contains(clean) ||
                $0.kind.lowercased().contains(clean)
            }
            .sorted { $0.date > $1.date }
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

            VStack(spacing: 0) {
                topBar
                searchBar

                if notifications.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(notifications) { item in
                                NavigationLink {
                                    VideoDetailView(video: item.video)
                                } label: {
                                    notificationRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadClearedNotifications()
        }
        .alert("Clear notifications?", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) {
                clearedNotificationIDs = Set(notifications.map { notificationKey($0) })
                saveClearedNotifications()
            }

            Button("Cancel", role: .cancel) { }
        }
    }
}

private extension NotificationsView {
    var topBar: some View {
        HStack {
            Text("Notifications")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)

            Spacer()

            Menu {
                Button {
                    shareNotifications()
                } label: {
                    Label("Share with others", systemImage: "square.and.arrow.up")
                }

                Button { } label: {
                    Label("Report", systemImage: "exclamationmark.bubble")
                }

                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("Clear History", systemImage: "trash")
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
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.55))

            TextField("Search notifications...", text: $searchText)
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.gray.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 54))
                .foregroundColor(.white.opacity(0.45))

            Text("No notifications yet")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("New uploads, likes, and featured videos will appear here.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    func notificationRow(_ item: AppNotification) -> some View {
        HStack(spacing: 12) {
            thumbnail(item.video)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.kind)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .clipShape(Capsule())

                    Text(relativeDate(item.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text(item.title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(12)
        .background(Color.gray.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func thumbnail(_ video: Video) -> some View {
        ZStack {
            if let image = loadImage(video.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "play.rectangle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.55))
                    )
            }
        }
        .frame(width: 104, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func notificationKey(_ item: AppNotification) -> String {
        item.video.id.uuidString + "_" + item.kind
    }

    func saveClearedNotifications() {
        UserDefaults.standard.set(Array(clearedNotificationIDs), forKey: clearedKey)
    }

    func loadClearedNotifications() {
        let saved = UserDefaults.standard.stringArray(forKey: clearedKey) ?? []
        clearedNotificationIDs = Set(saved)
    }

    func shareNotifications() {
        let text = notifications
            .map { "\($0.kind): \($0.message)" }
            .joined(separator: "\n")

        UIPasteboard.general.string = text
    }

    func loadImage(_ path: String?) -> UIImage? {
        guard let path else { return nil }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        if FileManager.default.fileExists(atPath: clean) {
            return UIImage(contentsOfFile: clean)
        }

        return nil
    }

    func relativeDate(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60) min ago" }
        if seconds < 86400 { return "\(seconds / 3600) hr. ago" }
        if seconds < 31_536_000 { return "\(seconds / 86400) days ago" }

        return "\(seconds / 31_536_000) yr. ago"
    }
}

struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let video: Video
    let kind: String
    let date: Date
}
