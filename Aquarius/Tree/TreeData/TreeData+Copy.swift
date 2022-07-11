//
//  TreeData+Copy.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/12/4.
//

import Foundation

// MARK: - Data Copy
extension TreeData {
    enum NodeContentDeepMode: Hashable {
        case none
        case single
        case recursive
        case stripRecursive
    }

    typealias CacheKey = String

    enum CopyError: Error {
        case cancelled
    }

    @MainActor func resetCopyStatus() {
        copyProgress = 0
    }

    @MainActor func cancelCopyTask() {
        copyTask?.cancel()
        copyTask = nil
        resetCopyStatus()
    }

    struct CopyStaticContext {
        let deepMode: NodeContentDeepMode
        var cache: [CacheKey: String]
    }

    func copy(for pod: Pod, with deepMode: NodeContentDeepMode) async -> String? {
        await self.resetCopyStatus()

        var content = ""
        do {
            var context = CopyStaticContext(
                deepMode: deepMode,
                cache: .init()
            )
            content = try await self.recursiveContent(for: pod, weight: 1, context: &context)
        } catch {
            if error is CopyError {
                return nil
            }
        }
        var isWriteToFile = false
        if content.count > 4096, let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                }
                let treeURL = url.appendingPathComponent(UUID().uuidString + ".tree.txt")
                try content.data(using: .utf8)?.write(to: URL(fileURLWithPath: treeURL.path))
                content = String(
                    format: String(localized: "Tree content is too large, writed to cache file: %@"),
                    treeURL.path
                )
                isWriteToFile = true
            } catch {
                // TODO fix write error
                print(error)
            }
        }

        return content
    }

    @inline(__always)
    private func updateProgress(append: Double) {
        DispatchQueue.main.async {
            self.copyProgress += append
        }
    }

    private func recursiveContent(
        for pod: Pod,
        weight: Double,
        context: inout CopyStaticContext
    ) async throws -> String {
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
            let key = pod.name
            if let result = context.cache[key] {
                updateProgress(append: weight)
                return result
            }

            var result = pod.name
            updateProgress(append: weight * 0.01)

            @inline(__always)
            func content(for pod: Pod, separator: String, connector: String, weight: Double) async throws {
                let next = try await recursiveContent(for: pod, weight: weight, context: &context)
                    .split(separator: "\n")
                    .joined(separator: separator)
                result = result + connector + next
            }

            let nodesWeight = weight * 0.98

            if var nodes = pod.nextLevel(isImpact)?.compactMap({ nameToPodCache[$0] }), !nodes.isEmpty {
                if nodes.count == 1, let node = nodes.first {
                    try await content(for: node, separator: "\n    ", connector: "\n└── ", weight: nodesWeight)
                } else {
                    let partWeight = nodesWeight / Double(nodes.count)
                    let last = nodes.removeLast()

                    for pod in nodes {
                        try await content(for: pod, separator: "\n│   ", connector: "\n├── ", weight: partWeight)
                    }

                    try await content(for: last, separator: "\n    ", connector: "\n└── ", weight: partWeight)
                }
            } else {
                updateProgress(append: nodesWeight)
            }

            context.cache[key] = result

            updateProgress(append: weight * 0.01)
            return result

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
