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

    nonisolated static func format(names: inout [String]) -> String {
        if names.isEmpty { return "" }

        if names.count == 1 {
            return "\n└── " + names.joined()
        } else {
            let last = names.removeLast()
            return "\n├── " + names.joined(separator: "\n├── ") + "\n└── " + last
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
            var result: String = pod.name

            if var nexts = pod.nextLevel(isImpact) {
                result += Self.format(names: &nexts)
            }

            context.write(result)

        case .recursive:
            var nodes: [(pod: Pod, current: Data, next: Data)] = [(pod, currentPrefix, nextPrefix)]
            var processed = 0

            while let (pod, currentPrefix, nextPrefix) = nodes.popLast() {
                guard !Task.isCancelled else { throw CopyError.cancelled }

                processed += 1
                context.write(currentPrefix)
                context.write(pod.nameData)
                context.write(Constant.newline)

                guard let nextNames = pod.nextLevel(isImpact), !nextNames.isEmpty else {
                    if processed & 0x3FF == 0 { progress?(processed) }
                    continue
                }

                var pushedLast = false
                for name in nextNames.reversed() {
                    guard let child = nameToPodCache[name] else { continue }
                    if !pushedLast {
                        nodes.append((child, nextPrefix + Constant.lConnector, nextPrefix + Constant.lastPrefix))
                        pushedLast = true
                    } else {
                        nodes.append((child, nextPrefix + Constant.tConnector, nextPrefix + Constant.middlePrefix))
                    }
                }

                if processed & 0x3FF == 0 { progress?(processed) }
            }

        case .pruneRecursive:
            var names = pod.nextLevel(isImpact) ?? []
            var visited = Set(names)
            var index = 0

            while index < names.count {
                if let nexts = nameToPodCache[names[index]]?.nextLevel(isImpact) {
                    for name in nexts where visited.insert(name).inserted {
                        names.append(name)
                    }
                }
                index += 1
            }

            context.write(pod.name + Self.format(names: &names))
        }
    }
}
