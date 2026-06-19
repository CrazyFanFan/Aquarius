//
//  TreeData.Copy.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/12/4.
//

import Foundation
import Quartz

private enum Constant {
    static let lConnector = Data("└── ".utf8)
    static let tConnector = Data("├── ".utf8)
    static let lastPrefix = Data("    ".utf8)
    static let middlePrefix = Data("│   ".utf8)
    static let newline = Data("\n".utf8)
}

private struct RecursiveCopyFrame {
    let names: [String]
    var nextIndex: Int
    let lastExistingIndex: Int
    let removesPrefixOnExit: Bool
}

// MARK: - Data Copy

extension TreeData {
    @MainActor func startCopyStatus(with pod: Pod, and deepMode: CopyingStrategy) {
        resetCopyStatus()
        isCopying = true
        copyMode = deepMode
        copyResult = nil
        currentCopyingCount = 0
        copyToken = UUID()

        copyTask?.cancel()
        copyProgressTask?.cancel()

        let isImpact = isImpact
        let nameToPodCache = nameToPodCache
        let token = copyToken
        let (progressStream, progressContinuation) = AsyncStream<Int>.makeStream()

        copyProgressTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await processedCount in progressStream {
                guard self.copyToken == token else { return }
                self.currentCopyingCount = processedCount
            }
        }

        let task = Task.detached(priority: .background) { () -> CopyResult in
            defer { progressContinuation.finish() }
            return Self.copyTree(
                for: pod,
                with: deepMode,
                isImpact: isImpact,
                nameToPodCache: nameToPodCache,
                progress: { progressContinuation.yield($0) }
            )
        }
        copyTask = task
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await task.value
            guard !Task.isCancelled, self.copyToken == token else { return }
            self.resetCopyStatus()
            self.copyTask = nil
            self.copyProgressTask?.cancel()
            self.copyProgressTask = nil
            self.copyResult = result
        }
    }

    @MainActor func resetCopyStatus() {
        isCopying = false
        copyMode = nil
    }

    @MainActor func cancelCurrentCopyTask() {
        copyTask?.cancel()
        copyTask = nil
        copyProgressTask?.cancel()
        copyProgressTask = nil
        copyToken = UUID()
        resetCopyStatus()
    }
}

private extension TreeData {
    nonisolated static func copyTree(
        for pod: Pod,
        with deepMode: CopyingStrategy,
        isImpact: Bool,
        nameToPodCache: [String: Pod],
        progress: (@Sendable (Int) -> Void)?
    ) -> CopyResult {
        var context: CopyContext?
        lazy var defaultErrorMessage = String(format: String(localized: "Faile to create tree of %@"), pod.name)

        do {
            let treeURL = try Utils.cacheFile()
            let _context = try CopyContext(
                deepMode: deepMode,
                fileHandle: FileHandle(forWritingTo: treeURL),
                fileURL: treeURL
            )
            context = _context

            try Self.iterativeContent(
                for: pod,
                isImpact: isImpact,
                nameToPodCache: nameToPodCache,
                context: _context,
                progress: progress
            )

            if Task.isCancelled {
                return .cancelled
            }

            try _context.close()

            func fileString(at url: URL = treeURL) -> CopyResult {
                defer {
                    try? FileManager.default.removeItem(at: url)
                }

                if let data = try? Data(contentsOf: treeURL), let string = String(data: data, encoding: .utf8) {
                    return .string(string)
                }
                return .failure(defaultErrorMessage)
            }

            return if deepMode == .recursive {
                if let size = Utils.size(of: treeURL), size <= 4096 {
                    fileString()
                } else {
                    .file(treeURL)
                }
            } else {
                fileString()
            }
        } catch {
            if let url = context?.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
            if let error = error as? CopyError {
                switch error {
                case .cancelled:
                    return .cancelled
                }
            }
            return .failure(defaultErrorMessage)
        }
    }

    nonisolated static func writeFormatted(names: [String], to context: CopyContext) {
        guard let last = names.last else { return }

        for name in names.dropLast() {
            context.write(Constant.newline)
            context.write(Constant.tConnector)
            context.write(name)
        }

        context.write(Constant.newline)
        context.write(Constant.lConnector)
        context.write(last)
    }

    nonisolated static func lastExistingIndex(in names: [String], nameToPodCache: [String: Pod]) -> Int? {
        var index = names.count - 1
        while index >= 0 {
            if nameToPodCache[names[index]] != nil {
                return index
            }
            index -= 1
        }
        return nil
    }

    nonisolated static func write(_ prefixSegments: [Data], to context: CopyContext) {
        for segment in prefixSegments {
            context.write(segment)
        }
    }

    nonisolated static func iterativeContent(
        for pod: Pod,
        currentPrefix: Data = .init(),
        nextPrefix: Data = .init(),
        isImpact: Bool,
        nameToPodCache: [String: Pod],
        context: CopyContext,
        progress: (@Sendable (Int) -> Void)?
    ) throws(CopyError) {
        guard !Task.isCancelled else { throw .cancelled }

        switch context.deepMode {
        case .nameOnly:
            context.write(pod.name)

        case .children:
            context.write(pod.name)

            let nexts = pod.nextLevel(isImpact)
            if !nexts.isEmpty {
                Self.writeFormatted(names: nexts, to: context)
            }

        case .recursive:
            context.write(currentPrefix)
            context.write(pod.nameData)
            context.write(Constant.newline)

            var processed = 1
            var prefixSegments: [Data] = []
            prefixSegments.reserveCapacity(64)
            if !nextPrefix.isEmpty {
                prefixSegments.append(nextPrefix)
            }

            let rootNextNames = pod.nextLevel(isImpact)
            var frames: [RecursiveCopyFrame] = []
            frames.reserveCapacity(64)
            if let lastExistingIndex = Self.lastExistingIndex(in: rootNextNames, nameToPodCache: nameToPodCache) {
                frames.append(.init(
                    names: rootNextNames,
                    nextIndex: 0,
                    lastExistingIndex: lastExistingIndex,
                    removesPrefixOnExit: false
                ))
            }

            while var frame = frames.popLast() {
                guard !Task.isCancelled else { throw CopyError.cancelled }

                var childIndex = frame.nextIndex
                while childIndex < frame.names.count, nameToPodCache[frame.names[childIndex]] == nil {
                    childIndex += 1
                }

                guard childIndex < frame.names.count else {
                    if frame.removesPrefixOnExit {
                        prefixSegments.removeLast()
                    }
                    continue
                }

                frame.nextIndex = childIndex + 1
                frames.append(frame)

                let isLast = childIndex == frame.lastExistingIndex
                let child = nameToPodCache[frame.names[childIndex]]!
                Self.write(prefixSegments, to: context)
                context.write(isLast ? Constant.lConnector : Constant.tConnector)
                context.write(child.nameData)
                context.write(Constant.newline)

                let childNextNames = child.nextLevel(isImpact)
                if let childLastExistingIndex = Self.lastExistingIndex(in: childNextNames, nameToPodCache: nameToPodCache) {
                    prefixSegments.append(isLast ? Constant.lastPrefix : Constant.middlePrefix)
                    frames.append(.init(
                        names: childNextNames,
                        nextIndex: 0,
                        lastExistingIndex: childLastExistingIndex,
                        removesPrefixOnExit: true
                    ))
                }

                processed += 1
                if processed & 0x3FF == 0 { progress?(processed) }
            }

        case .pruneRecursive:
            var names = pod.nextLevel(isImpact)
            var visited = Set(names)
            var index = 0

            while index < names.count {
                let nexts = nameToPodCache[names[index]]?.nextLevel(isImpact) ?? []
                for name in nexts where visited.insert(name).inserted {
                    names.append(name)
                }
                index += 1
            }

            context.write(pod.name)
            Self.writeFormatted(names: names, to: context)
        }
    }
}
