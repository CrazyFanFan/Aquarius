//
//  Utils.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/8/7.
//

import Foundation

enum Utils {
    static let fileManager = FileManager.default

    private static var systemCacheDirectory: URL { fileManager.temporaryDirectory }
    private static var applicationCacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private static func rootCacheDir() -> URL {
        switch GlobalState.shared.locationOfCacheFile {
        case .system: systemCacheDirectory
        case .application: applicationCacheDirectory ?? systemCacheDirectory
        }
    }

    static func refreshCacheDir() {
        cacheDir = rootCacheDir()
    }

    static func clear() {
        [systemCacheDirectory, applicationCacheDirectory]
            .compactMap { $0 }
            .forEach { url in
                if fileManager.fileExists(atPath: url.path) {
                    try? fileManager.removeItem(at: url)
                    try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                }
            }
    }

    private(set) static var cacheDir: URL = rootCacheDir()

    static func cacheFile() throws -> URL {
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }

        let tmp = cacheDir.appendingPathComponent(UUID().uuidString + ".tree.txt")

        if !fileManager.fileExists(atPath: tmp.path) {
            fileManager.createFile(atPath: tmp.path, contents: nil)
        }

        return tmp
    }

    static func size(of fileURL: URL) -> UInt64? {
        do {
            let attr = try fileManager.attributesOfItem(atPath: fileURL.path)
            var fileSize = attr[FileAttributeKey.size] as? UInt64

            if fileSize == nil {
                let dict = attr as NSDictionary
                fileSize = dict.fileSize()
            }

            return fileSize
        } catch {
            return nil
        }
    }

    static var userHome: URL = .init(fileURLWithPath: userHomePath, isDirectory: true)

    static var userHomePath: String {
        let pwd = getpwuid(getuid())

        if let home = pwd?.pointee.pw_dir {
            return FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
            .path
    }
}
