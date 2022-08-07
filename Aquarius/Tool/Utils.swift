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
    private static var applicationCacheDirectory: URL? { fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first }

    private static func rootCacheDir() -> URL {
        switch GlobalState.shared.locationOfCacheFile {
        case .system: return systemCacheDirectory
        case .application: return applicationCacheDirectory ?? systemCacheDirectory
        }
    }

    static func refrashCacheDir() {
        cacheDir = rootCacheDir()
    }

    static func clear() {
        [systemCacheDirectory, applicationCacheDirectory]
            .compactMap({ $0 })
            .forEach { url in
                if fileManager.fileExists(atPath: url.path) {
                    try? fileManager.removeItem(at: url)
                    try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                }
            }
    }

    static private(set) var cacheDir: URL = rootCacheDir()

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

}
