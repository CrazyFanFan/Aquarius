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

        copyTask = Task.detached(priority: .background) {
            let result = self.copy(for: pod, with: deepMode)

            await self.resetCopyStatus()
            await MainActor.run {
                self.copyResult = result
            }
        }
    }

    @MainActor func resetCopyStatus() {
        isCopying = false
        copyMode = nil
    }

    @MainActor func cancelCurrentCopyTask() {
        copyTask?.cancel()
        copyTask = nil
        resetCopyStatus()
    }
}

private extension TreeData {
    func copy(for pod: Pod, with deepMode: CopyingStrategy) -> CopyResult {
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

            try iterativeContent(for: pod, context: _context)

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

    @inline(__always)
    func updateProgress(_ processedCount: Int) {
        runWithMainActor {
            self.currentCopyingCount = processedCount
        }
    }

    func format(names: inout [String]) -> String {
        if names.isEmpty { return "" }

        if names.count == 1 {
            return "\n└── " + names.joined()
        } else {
            let last = names.removeLast()
            return "\n├── " + names.joined(separator: "\n├── ") + "\n└── " + last
        }
    }

    func iterativeContent(
        for pod: Pod,
        currentPrefix: Data = .init(),
        nextPrefix: Data = .init(),
        context: CopyContext
    ) throws(CopyError) {
        guard !Task.isCancelled else { throw .cancelled }

        switch context.deepMode {
        case .nameOnly:
            context.write(pod.name)

        case .children:
            var result: String = pod.name

            if var nexts = pod.nextLevel(isImpact) {
                result += format(names: &nexts)
            }

            context.write(result)

        case .recursive:
            var nodes: [(pod: Pod, current: Data, next: Data)] = [(pod, currentPrefix, nextPrefix)]
            var processed = 0
            let start = CACurrentMediaTime()

            while let (pod, currentPrefix, nextPrefix) = nodes.popLast() {
                guard !Task.isCancelled else { throw CopyError.cancelled }

                processed += 1
                let step = 100_000
                if processed % step == 0 {
                    let duration = CACurrentMediaTime() - start
                    let tmp = processed
                    DispatchQueue.global().async {
                        print(String(format: "Processed \(tmp) pods in %.2lf seconds, average %.2lf seconds per \(step) pods.", duration, duration / Double(tmp / step)))
                    }
                }

                context.write(currentPrefix + pod.nameData + Constant.newline)

                guard var nextPods = pod.nextLevel(isImpact)?.compactMap({ nameToPodCache[$0] }), !nextPods.isEmpty else {
                    continue
                }

                let last = nextPods.removeLast()
                let nextNodes = nextPods.enumerated()
                    .map { ($0.element, nextPrefix + Constant.tConnector, nextPrefix + Constant.middlePrefix) }
                nodes.append((last, nextPrefix + Constant.lConnector, nextPrefix + Constant.lastPrefix))
                nodes.append(contentsOf: nextNodes.reversed())

                updateProgress(processed)
            }

        case .pruneRecursive:
            var names = pod.nextLevel(isImpact) ?? []
            var index = 0

            while index < names.count {
                names += nameToPodCache[names[index]]?
                    .nextLevel(isImpact)?
                    .filter { !names.contains($0) } ?? []
                index += 1
            }

            context.write(pod.name + format(names: &names))
        }
    }
}
