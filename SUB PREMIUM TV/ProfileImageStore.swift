import Foundation
import UIKit

@MainActor
final class ProfileImageStore: ObservableObject {
    static let shared = ProfileImageStore()

    private init() { }

    private var folderURL: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let folder = documents.appendingPathComponent(
            "SubPremiumTVProfileImages",
            isDirectory: true
        )

        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )
        }

        return folder
    }

    func saveProfileImage(_ image: UIImage, for email: String) -> String? {
        let safeEmail = email
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: ".", with: "_")

        guard !safeEmail.isEmpty else { return nil }

        let url = folderURL.appendingPathComponent("\(safeEmail)_avatar.jpg")

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }

        do {
            try data.write(to: url, options: .atomic)
            return url.path
        } catch {
            return nil
        }
    }

    func loadProfileImage(path: String?) -> UIImage? {
        guard let path else { return nil }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        if clean.hasPrefix("file://"),
           let url = URL(string: clean),
           FileManager.default.fileExists(atPath: url.path) {
            return UIImage(contentsOfFile: url.path)
        }

        if FileManager.default.fileExists(atPath: clean) {
            return UIImage(contentsOfFile: clean)
        }

        return nil
    }

    func deleteProfileImage(path: String?) {
        guard let path else { return }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if clean.hasPrefix("file://"),
           let url = URL(string: clean),
           FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(atPath: url.path)
            return
        }

        if FileManager.default.fileExists(atPath: clean) {
            try? FileManager.default.removeItem(atPath: clean)
        }
    }
}
