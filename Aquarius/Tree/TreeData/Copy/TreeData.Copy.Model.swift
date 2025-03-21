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

    class CopyContext {
        let deepMode: CopyingStrategy

        private let cacheSize = 16 * 1024

        private var fileHandle: FileHandle
        private var cache: Data = .init()
        private var queue: DispatchQueue = .init(label: "copy.result.queue")

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
                let _cache = cache
                queue.async {
                    if let append {
                        self.fileHandle.write(_cache + append)
                    } else {
                        self.fileHandle.write(_cache)
                    }
                }
                cache.removeAll(keepingCapacity: true)
            }
        }

        func write(_ data: Data) {
            if data.count >= cacheSize {
                if cache.isEmpty {
                    queue.async {
                        self.fileHandle.write(data)
                    }
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
            queue.sync(flags: .barrier) {}
            try fileHandle.synchronize()
            try fileHandle.close()
        }
    }

    enum CopyError: Error {
        case cancelled
    }
}
