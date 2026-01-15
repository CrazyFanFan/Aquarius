//
//  TreeData.Copy.Model.swift
//  Aquarius
//
//  Created by Crazy凡 on 2025/3/26.
//

import Quartz

extension TreeData {
    enum CopyingStrategy: Hashable {
        case nameOnly
        case children
        case recursive
        case pruneRecursive
    }

    enum CopyResult: Equatable {
        case file(URL)
        case string(String)
        case failure(String)
        case cancelled
    }

    final class CopyContext {
        let deepMode: CopyingStrategy

        private let cacheSize = 128 * 1024

        private var fileHandle: FileHandle
        private var cache: Data = .init()

        var fileURL: URL?

        init(
            deepMode: CopyingStrategy,
            fileHandle: FileHandle,
            fileURL: URL
        ) {
            self.deepMode = deepMode
            self.fileHandle = fileHandle
            self.fileURL = fileURL
        }

        @inline(__always) private func flushCache(_ append: Data? = nil) {
            if !cache.isEmpty {
                let flushed = cache
                cache.removeAll(keepingCapacity: true)
                fileHandle.write(flushed)
                if let append { fileHandle.write(append) }
            }
        }

        func write(_ data: Data) {
            if data.count >= cacheSize {
                if cache.isEmpty {
                    fileHandle.write(data)
                } else {
                    flushCache(data)
                }
            } else if cache.isEmpty {
                cache = data
            } else if cache.count + data.count >= cacheSize {
                flushCache(data)
            } else {
                cache += data
            }
        }

        @inline(__always) func write(_ string: String) {
            write(Data(string.utf8))
        }

        func close() throws {
            if !cache.isEmpty {
                flushCache()
            }
            try fileHandle.synchronize()
            try fileHandle.close()
        }
    }

    enum CopyError: Error {
        case cancelled
    }
}
