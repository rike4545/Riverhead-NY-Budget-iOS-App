//
//  RBLocalJSONCache.swift
//  Riverhead NY Budget App
//
//  Tiny JSON cache helper for the Budget Explorer.
//  Keeps imported datasets available offline.
//
//  Swift 6 • iOS 17+
//

import Foundation

enum RBLocalJSONCache {

    private static let folderName = "RBJSONCache"

    private static var cacheDir: URL {
        let fm = FileManager.default

        // Use Application Support (backed up) but tucked into a small folder.
        // If you prefer non-backed-up storage, switch to .cachesDirectory.
        let base = RBAppDirectories.applicationSupportDirectory()
        let dir = base.appendingPathComponent(folderName, isDirectory: true)

        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func url(forKey key: String) -> URL {
        // Ensure a filesystem-safe filename
        let safe = key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return cacheDir.appendingPathComponent("\(safe).json")
    }

    static func readData(forKey key: String) throws -> Data {
        let fileURL = url(forKey: key)
        return try Data(contentsOf: fileURL)
    }

    static func writeData(_ data: Data, forKey key: String) throws {
        let fileURL = url(forKey: key)

        // Atomic write to prevent corruption
        try data.write(to: fileURL, options: .atomic)
    }

    static func delete(forKey key: String) {
        let fm = FileManager.default
        let fileURL = url(forKey: key)
        if fm.fileExists(atPath: fileURL.path) {
            try? fm.removeItem(at: fileURL)
        }
    }

    static func exists(forKey key: String) -> Bool {
        FileManager.default.fileExists(atPath: url(forKey: key).path)
    }
}
