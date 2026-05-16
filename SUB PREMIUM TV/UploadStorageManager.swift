import Foundation
import UIKit
import AVFoundation

@MainActor
final class UploadStorageManager {
    static let shared = UploadStorageManager()

    private init() { }

    private var appFolder: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let folder = documents.appendingPathComponent(
            "SubPremiumTVUploads",
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

    private var videosFolder: URL {
        createFolder(named: "Videos")
    }

    private var thumbnailsFolder: URL {
        createFolder(named: "Thumbnails")
    }

    private func createFolder(named name: String) -> URL {
        let folder = appFolder.appendingPathComponent(
            name,
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

    func saveVideoData(_ data: Data) throws -> String {
        let fileName = "video_\(UUID().uuidString).mov"
        let url = videosFolder.appendingPathComponent(fileName)

        try data.write(to: url, options: .atomic)

        return url.path
    }

    func saveThumbnailImage(_ image: UIImage) -> String? {
        let fileName = "thumbnail_\(UUID().uuidString).jpg"
        let url = thumbnailsFolder.appendingPathComponent(fileName)

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

    func loadImage(from path: String?) -> UIImage? {
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

    func deleteFile(at path: String?) {
        guard let path else { return }

        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if FileManager.default.fileExists(atPath: clean) {
            try? FileManager.default.removeItem(atPath: clean)
        }
    }

    func generateThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)

        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1280, height: 720)

        do {
            let cgImage = try generator.copyCGImage(
                at: CMTime(seconds: 1, preferredTimescale: 600),
                actualTime: nil
            )

            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
}
