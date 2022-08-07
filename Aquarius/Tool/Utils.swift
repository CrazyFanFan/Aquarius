//
//  Utils.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/8/7.
//

import Foundation

enum Utils {
    static let fileManager = FileManager.default

    private static func rootCacheDir() -> URL {
        switch GlobalState.shared.locationOfCacheFile {
        case .system: break
        case .application:
            if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                return url
            }
        }

        return fileManager.temporaryDirectory
    }

    static func refrashCacheDir() {
        cacheDir = rootCacheDir()
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
