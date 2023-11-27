//
//  TreeData.Copy.swift
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
    static let newlineValue: UInt8 = 10
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

            guard let content = await self.copy(for: pod, with: deepMode), !Task.isCancelled else {
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
        var engine: CopyTaskEngine<Data>
    }

    enum CopyError: Error {
        case cancelled
    }

    func copy(for pod: Pod, with deepMode: NodeContentDeepMode) async -> String? {
        var context = CopyStaticContext(deepMode: deepMode, fileHandle: .nullDevice, engine: .init())
        lazy var defaultErrorMessage = String(format: String(localized: "Faile to create tree of %@"), pod.name)

        do {
            let treeURL = try Utils.cacheFile()
            defer {
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: treeURL)
                }
            }

            context.fileHandle = try FileHandle(forWritingTo: treeURL)
            context.fileURL = treeURL

            let r = await self.recursiveContent2(for: pod, weight: 1, context: context)
            context.fileHandle.write(r)

            func fileString(at url: URL = treeURL) -> String? {
                defer {
                    try? FileManager.default.removeItem(at: url)
                }

                if let data = try? Data(contentsOf: treeURL), let string = String(data: data, encoding: .utf8) {
                    return string
                }
                return nil
            }

            return if deepMode == .recursive {
                if let size = Utils.size(of: treeURL), size <= 4096 {
                    fileString() ?? defaultErrorMessage
                } else {
                    String(format:
                            String(localized: "Tree content is too large, written to cache file: %@"),
                           treeURL.path)
                }
            } else {
                fileString() ?? defaultErrorMessage
            }
        } catch {
            return defaultErrorMessage
        }
    }

    @inline(__always)
    func updateProgress(append: Double) {
        runWithMainActor {
            self.copyProgress += append
        }
    }

    func formatNames(_ input: inout [String]) -> String {
        if input.isEmpty { return "" }

        if input.count == 1 {
            return ("\n└── " + input.joined())
        } else {
            let last = input.removeLast()
            return ("\n├── " + input.joined(separator: "\n├── ") + "\n└── " + last)
        }
    }

    func recursiveContent(
        for pod: Pod,
        weight: Double,
        currentPrefix: Data = .init(),
        nextPrefix: Data = .init(),
        context: CopyStaticContext
    ) throws {
        guard !Task.isCancelled else { throw CopyError.cancelled }

        switch context.deepMode {
        case .none:
            updateProgress(append: weight)
            context.fileHandle.write(pod.name)
        case .single:
            var result: String = pod.name

            if var next = pod.nextLevel(isImpact) {
                result += formatNames(&next)
            }
            updateProgress(append: weight)

            context.fileHandle.write(result)

        case .recursive:
            let realtimeProgressUpdate = weight > 1e-7

            let (currentWeight, nextsWeight) = if realtimeProgressUpdate {
                (weight * 0.001, weight * 0.999)
            } else {
                (0, 0)
            }

            context.fileHandle.write(currentPrefix)
            context.fileHandle.write(pod.name)
            context.fileHandle.write(Constant.newline)

            if realtimeProgressUpdate {
                updateProgress(append: currentWeight)
            }

            guard var next = pod.nextLevel(isImpact)?.compactMap({ nameToPodCache[$0] }) else {
                if realtimeProgressUpdate {
                    updateProgress(append: nextsWeight)
                }

                return
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

            context.fileHandle.write(pod.name + formatNames(&subNames))
        }
    }

    func recursiveContent2(
        for pod: Pod,
        weight: Double,
        currentPrefix: Data = .init(),
        nextPrefix: Data = .init(),
        context: CopyStaticContext
    ) async -> Data {
        guard !Task.isCancelled else { return .init() }

        switch context.deepMode {
        case .none:
            updateProgress(append: weight)
            return pod.name.data
        case .single:
            var result: String = pod.name

            if var next = pod.nextLevel(isImpact) {
                result += formatNames(&next)
            }
            updateProgress(append: weight)

            return result.data

        case .recursive:
            return await innerRecursiveContent(for: pod, weight: weight, context: context)

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

            return (pod.name + formatNames(&subNames)).data
        }
    }

    func update(subconent: Data, isLast: Bool) -> Data {
        let (connectorChar, prefixChar) = isLast ? (Constant.connector1, Constant.prefix1) : (Constant.connector2, Constant.prefix2)
        return connectorChar + subconent.replacing(Constant.newline, with: Constant.newline + prefixChar)
    }

    func innerRecursiveContent(
        for pod: Pod,
        weight: Double,
        currentPrefix: Data = .init(),
        nextPrefix: Data = .init(),
        context: CopyStaticContext
    ) async -> Data {
        guard !Task.isCancelled else {
            await context.engine.cancelAllTasks()
            return .init()
        }

        let realtimeProgressUpdate = weight > 1e-7

        let (currentWeight, nextsWeight) = if realtimeProgressUpdate {
            (weight * 0.001, weight * 0.999)
        } else {
            (0, 0)
        }

        defer {
            if !realtimeProgressUpdate {
                updateProgress(append: weight)
            }
        }

        func content(for pod: Pod) async -> Data {
            guard let next = pod.nextLevel(self.isImpact)?.compactMap({ self.nameToPodCache[$0] }) else {
                if realtimeProgressUpdate {
                    self.updateProgress(append: nextsWeight)
                }

                return pod.name.data
            }

            switch next.count {
            case 0: return pod.name.data

            default:
                let partOfWeight = nextsWeight / Double(next.count)

                var nextResults: [Data] = await withTaskGroup(of: (Int, Data).self) { group in
                    for (index, pod) in next.enumerated() {
                        group.addTask {
                            defer {
                                if realtimeProgressUpdate {
                                    self.updateProgress(append: currentWeight)
                                }
                            }
                            return (index, await self.innerRecursiveContent(for: pod, weight: partOfWeight, context: context))
                        }
                    }

                    actor _C {
                        var results: [(Int, Data)] = .init()
                        init() {}
                        func append(_ r: (Int, Data)) {
                            results.append(r)
                        }
                    }

                    let c = _C()
                    for await r in group {
                        await c.append(r)
                    }
                    return await c.results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
                }

                let lastResult = nextResults.removeLast()
                var result = nextResults.map { self.update(subconent: $0, isLast: false) }
                result.append(self.update(subconent: lastResult, isLast: true))
                print(pod.name)
                return pod.name.data + Constant.newline + result.joined(separator: Constant.newline)
            }

        }

        return await context.engine.value(for: pod.name) {
            await content(for: pod)
        }
    }
}

private extension String {
    var data: Data {
        self.data(using: .utf8) ?? .init()
    }
}

private extension FileHandle {
    func write(_ content: String) {
        if let data = content.data(using: .utf8) {
            write(data)
        }
    }
}
