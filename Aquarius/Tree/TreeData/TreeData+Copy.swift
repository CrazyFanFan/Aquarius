//
//  TreeData+Copy.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/12/4.
//

import Foundation

private enum Constant {
    static let connector1 = "└── ".data(using: .utf8)!
    static let connector2 = "├── ".data(using: .utf8)!
    static let prefix1 = "    ".data(using: .utf8)!
    static let prefix2 = "│   ".data(using: .utf8)!
    static let newline: Data = .init(repeating: 10, count: 1)
}

// MARK: - Data Copy
extension TreeData {
    enum NodeContentDeepMode: Hashable {
        case none
        case single
        case recursive
        case stripRecursive
    }

    @MainActor func startCopyStatus(with pod: Pod, and deepMode: NodeContentDeepMode) {
        let start = Date()
        resetCopyStatus()
        isCopying = true

        self.copyTask = Task.detached(priority: .background) {
            defer {
                print(start.distance(to: Date()))
            }

            guard let content = self.copy(for: pod, with: deepMode), !Task.isCancelled else {
                return
            }

            Pasteboard.write(content)

            await self.resetCopyStatus()
        }
    }

    @MainActor func resetCopyStatus() {
        isCopying = false
        copyProgress = 0
    }

    @MainActor func cancelCurrentCopyTask() {
        copyTask?.cancel()
        copyTask = nil
        resetCopyStatus()
    }
}

private extension TreeData {
    struct CopyStaticContext {
        let deepMode: NodeContentDeepMode
        var fileHandle: FileHandle
        var fileURL: URL?
    }

    enum CopyError: Error {
        case cancelled
    }

    func copy(for pod: Pod, with deepMode: NodeContentDeepMode) -> String? {
        var context = CopyStaticContext(deepMode: deepMode, fileHandle: .nullDevice)

        do {
            if deepMode == .recursive {
                let treeURL = try Utils.cacheFile()

                context.fileHandle = try FileHandle(forWritingTo: treeURL)
                context.fileURL = treeURL

                try self.recursiveContent(for: pod, weight: 1, context: context)

                if let size = Utils.size(of: treeURL), size <= 4096 {
                    if let data = try? Data(contentsOf: treeURL), let string = String(data: data, encoding: .utf8) {
                        try? FileManager.default.removeItem(at: treeURL) // delete cache file
                        return string
                    }
                }

                return String(
                    format: String(localized: "Tree content is too large, written to cache file: %@"),
                    treeURL.path
                )
            } else {
                return try self.recursiveContent(for: pod, weight: 1, context: context)
            }
        } catch {
            if let url = context.fileURL {
                try? FileManager.default.removeItem(at: url)
            }

            return ""
        }
    }

    @inline(__always)
    func updateProgress(append: Double) {
        DispatchQueue.main.async {
            self.copyProgress += append
        }
    }

    @discardableResult
    func recursiveContent(
        for pod: Pod,
        weight: Double,
        currentPrefix: Data = .init(),
        nextPrefix: Data = .init(),
        context: CopyStaticContext
    ) throws -> String {
        guard !Task.isCancelled else { throw CopyError.cancelled }

        func formatNames(_ input: inout [String]) -> String {
            if input.isEmpty { return "" }

            if input.count == 1 {
                return ("\n└── " + input.joined())
            } else {
                let last = input.removeLast()
                return ("\n├── " + input.joined(separator: "\n├── ") + "\n└── " + last)
            }
        }

        switch context.deepMode {
        case .none:
            updateProgress(append: weight)
            return pod.name
        case .single:
            var result: String = pod.name

            if var next = pod.nextLevel(isImpact) {
                result += formatNames(&next)
            }
            updateProgress(append: weight)

            return result

        case .recursive:
            let currentWeight: Double
            let nextsWeight: Double

            let realtimeProgressUpdate = weight > 1e-5

            if realtimeProgressUpdate {
                currentWeight = weight * 0.01
                nextsWeight = weight * 0.99
            } else {
                currentWeight = 0
                nextsWeight = 0
            }

            context.fileHandle.write(currentPrefix)
            context.fileHandle.write(pod.name)
            context.fileHandle.write(Data([10]))

            if realtimeProgressUpdate {
                updateProgress(append: currentWeight)
            }

            guard var next = pod.nextLevel(isImpact)?.compactMap({ nameToPodCache[$0] }) else {
                if realtimeProgressUpdate {
                    updateProgress(append: nextsWeight)
                }

                return ""
            }

            switch next.count {
            case 0: break

            case 1: try recursiveContent(
                for: next.first!,
                weight: nextsWeight,
                currentPrefix: nextPrefix + Constant.connector1,
                nextPrefix: nextPrefix + Constant.prefix1,
                context: context)

            default:
                let partOfWeight = nextsWeight / Double(next.count)
                let last = next.removeLast()

                for pod in next {
                    try recursiveContent(
                        for: pod,
                        weight: partOfWeight,
                        currentPrefix: nextPrefix + Constant.connector2,
                        nextPrefix: nextPrefix + Constant.prefix2,
                        context: context)
                }

                try recursiveContent(
                    for: last,
                    weight: partOfWeight,
                    currentPrefix: nextPrefix + Constant.connector1,
                    nextPrefix: nextPrefix + Constant.prefix1,
                    context: context)
            }

            if !realtimeProgressUpdate {
                updateProgress(append: weight)
            }

            return ""

        case .stripRecursive:
            var subNames = pod.nextLevel(isImpact) ?? []
            var index = 0

            while index < subNames.count {
                subNames += nameToPodCache[subNames[index]]?
                    .nextLevel(isImpact)?
                    .filter({ !subNames.contains($0) }) ?? []
                index += 1
            }
            updateProgress(append: weight)

            return pod.name + formatNames(&subNames)
        }
    }
}

fileprivate extension FileHandle {
    func write(_ content: String) {
        if let data = content.data(using: .utf8) {
            write(data)
        }
    }
}
