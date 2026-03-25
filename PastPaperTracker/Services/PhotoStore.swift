import Foundation
import UIKit

struct PhotoStore {
    private let fileManager: FileManager
    private let baseFolderName = "PastPaperTrackerPhotos"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func saveImageData(_ data: Data, for id: UUID) throws -> String {
        let relativePath = "mistakes/\(id.uuidString.lowercased()).jpg"
        let url = try url(for: relativePath)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        return relativePath
    }

    func image(for relativePath: String) -> UIImage? {
        guard let data = try? Data(contentsOf: try url(for: relativePath)) else {
            return nil
        }
        return UIImage(data: data)
    }

    func data(for relativePath: String) throws -> Data {
        try Data(contentsOf: try url(for: relativePath))
    }

    func fileExists(relativePath: String) -> Bool {
        guard let url = try? url(for: relativePath) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    func delete(relativePath: String) {
        guard let url = try? url(for: relativePath) else { return }
        try? fileManager.removeItem(at: url)
    }

    func url(for relativePath: String) throws -> URL {
        let folder = try applicationSupportDirectory()
        return folder.appendingPathComponent(relativePath)
    }

    private func applicationSupportDirectory() throws -> URL {
        let baseURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appFolder = baseURL.appendingPathComponent(baseFolderName, isDirectory: true)
        try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder
    }
}
