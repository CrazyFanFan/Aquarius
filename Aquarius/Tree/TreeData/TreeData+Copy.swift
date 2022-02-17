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

    func copy(for node: Pod, with deepMode: NodeContentDeepMode) async -> String? {
        await self.resetCopyStatus()

        var content = ""
        do {
            content = try await self.runcopy(for: node, with: deepMode)
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

    private func runcopy(for node: Pod, with deepMode: NodeContentDeepMode) async throws -> String {
        var cache: [CacheKey: String] = [:]
        return try await self.innerContent(for: node, with: deepMode, weight: 1, cache: &cache)
    }

    @inline(__always)
    private func updateProgress(append: Double) {
        DispatchQueue.main.async {
            self.copyProgress += append
        }
    }

    private func innerContent(
        for node: Pod,
        with deepMode: NodeContentDeepMode,
        weight: Double,
        cache: inout [CacheKey: String],
        prefix: String = ""
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

        switch deepMode {
        case .none:
            updateProgress(append: weight)
            return node.name
        case .single:
            var result: String = node.name
            if var next = node.nextLevel(isImpact) {
                result += formatNames(&next)
            }
            updateProgress(append: weight)
            return result

        case .recursive:
            let key = node.name
            if let result = cache[key] {
                updateProgress(append: weight)
                return result
            }

            var result = node.name
            updateProgress(append: weight * 0.01)

            @inline(__always)
            func newPart(for node: Pod, separator: String, connector: String, weight: Double) async throws {
                let next = try await innerContent(for: node, with: deepMode, weight: weight, cache: &cache)
                    .split(separator: "\n")
                    .joined(separator: separator)
                result = result + connector + next
            }

            let nodesWeight = weight * 0.98

            if var nodes = node.nextLevel(isImpact)?.compactMap({ nameToPodCache[$0] }), !nodes.isEmpty {
                if nodes.count == 1, let node = nodes.first {
                    try await newPart(for: node, separator: "\n    ", connector: "\n└── ", weight: nodesWeight)
                } else {
                    let partWeight = nodesWeight / Double(nodes.count)
                    let last = nodes.removeLast()

                    for node in nodes {
                        try await newPart(for: node, separator: "\n│   ", connector: "\n├── ", weight: partWeight)
                    }

                    try await newPart(for: last, separator: "\n    ", connector: "\n└── ", weight: partWeight)
                }
            } else {
                updateProgress(append: nodesWeight)
            }

            cache[key] = result

            updateProgress(append: weight * 0.01)
            return result

        case .stripRecursive:
            var subNames = node.nextLevel(isImpact) ?? []
            var index = 0

            while index < subNames.count {
                subNames += nameToPodCache[subNames[index]]?
                        .nextLevel(isImpact)?
                        .filter({ !subNames.contains($0) }) ?? []
                index += 1
            }
            updateProgress(append: weight)

            return node.name + formatNames(&subNames)
        }
    }
}
