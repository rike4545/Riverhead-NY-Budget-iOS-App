//
//  RBFoundationHelpers.swift
//  Riverhead NY Budget App
//
//  Shared Foundation helpers that keep common literals and filesystem paths
//  out of force-unwrap territory.
//

import Foundation
import OSLog

// MARK: - Structured logging

enum RBLog {
    static let ai      = Logger(subsystem: "me.riverhead.budget", category: "AI")
    static let data    = Logger(subsystem: "me.riverhead.budget", category: "Data")
    static let network = Logger(subsystem: "me.riverhead.budget", category: "Network")
    static let ui      = Logger(subsystem: "me.riverhead.budget", category: "UI")
}

// MARK: - App directories

enum RBAppDirectories {
    static func applicationSupportDirectory(appFolder: String? = nil) -> URL {
        resolvedDirectory(for: .applicationSupportDirectory, appFolder: appFolder)
    }

    static func cachesDirectory(appFolder: String? = nil) -> URL {
        resolvedDirectory(for: .cachesDirectory, appFolder: appFolder)
    }

    private static func resolvedDirectory(
        for searchPath: FileManager.SearchPathDirectory,
        appFolder: String?
    ) -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: searchPath, in: .userDomainMask).first
            ?? fm.temporaryDirectory

        guard let appFolder else { return base }

        let dir = base.appendingPathComponent(appFolder, isDirectory: true)
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            RBLog.data.error("Failed to create directory at \(dir.path): \(error.localizedDescription)")
            assertionFailure("Failed to create directory at \(dir.path): \(error.localizedDescription)")
        }
        return dir
    }
}

// MARK: - URL helpers

extension URL {
    static func verified(_ literal: StaticString) -> URL {
        guard let url = URL(string: "\(literal)") else {
            preconditionFailure("Invalid URL literal: \(literal)")
        }
        return url
    }
}
