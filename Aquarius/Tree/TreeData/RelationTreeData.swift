//
//  RelationTreeData.swift
//  Aquarius
//
//  Created by Crazy凡 on 2024/10/27.
//

import Combine
import Observation
import SwiftUI

enum DisplaySectionGroupType: String, Hashable {
    case all = "All Modules"
    case successors = "Dependent Modules"
    case predecessors = "Requiring Modules"
}

@Observable final class RelationTreeData {
    @ObservationIgnored private(set) var start: Pod
    private(set) var selected: Pod?
    private(set) var isReleationLoading: Bool = false
    private(set) var paths: [[String]] = []

    @ObservationIgnored private(set) var pods: [Pod]
    @ObservationIgnored private(set) var associatedPods: [(DisplaySectionGroupType, [Pod])]?
    @ObservationIgnored private(set) var nameToPodCache: [String: Pod]

    private(set) var showNames: [(group: DisplaySectionGroupType, [(pod: Pod, indices: [String.Index]?)])] = []
    private(set) var searchSuggestions: [(pod: Pod, indices: [String.Index]?)] = []

    @ObservationIgnored var searchKey = "" {
        didSet {
            guard searchKey != oldValue else { return }

            let value = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)

            if searchKey != value {
                searchKey = value
            }

            loadData()
            loadSearchSuggestions()
        }
    }

    @ObservationIgnored var associatedOnly = true {
        didSet {
            guard associatedOnly != oldValue else { return }

            loadData()
            loadSearchSuggestions()
        }
    }

    @ObservationIgnored private var task: Task<Void, Never>?
    // @ObservationIgnored var pathCache = LRUMemoryCache<String, [[String]]>(maxCost: 1024, maxCount: 2 * 1024 * 1024 * 1024)

    init(start: Pod, pods: [Pod], nameToPodCache: [String: Pod]) {
        self.start = start
        self.pods = pods
        self.nameToPodCache = nameToPodCache

        loadData()
    }

    /**
    func findPaths1(
        from startName: String,
        to endName: String,
        nexts keyPath: KeyPath<Pod, [String]?>,
        pods: [Pod],
        nameToPodCache: [String: Pod]
    ) -> [[String]] {
        guard let start = nameToPodCache[startName] else { return [] }
        var result: [[String]] = []
        var visited: Set<String> = Set()
        var currentPath: [String] = []

        func dfs(currentPod: Pod) {
            if Task.isCancelled { return }

            visited.insert(currentPod.name)
            currentPath.append(currentPod.name)

            if currentPod.name == endName {
                result.append(currentPath)
            } else {
                if let nexts = currentPod[keyPath: keyPath] {
                    for nextPodName in nexts {
                        guard let nextPod = nameToPodCache[nextPodName] else { continue }
                        if !visited.contains(nextPod.name) {
                            dfs(currentPod: nextPod)
                        }
                    }
                }
            }

            if currentPod.name == start.name {
                pathCache[currentPod.name] = result
            }

            currentPath.removeLast()
            visited.remove(currentPod.name)
        }

        if let cachedPaths = pathCache[start.name] {
            return cachedPaths
        } else {
            dfs(currentPod: start)
        }

        return result
    }

    func findPaths2(
        from startName: String,
        to endName: String,
        nexts keyPath: KeyPath<Pod, [String]?>,
        pods: [Pod],
        nameToPodCache: [String: Pod]
    ) -> [[String]] {
        guard let start = nameToPodCache[startName] else { return [] }

        var result: [[String]] = []

        // 使用栈来模拟递归调用过程
        var stack: [(pod: Pod, path: [String])] = [(start, [start.name])]
        var visited: [String: Int] = [:] // 跟踪每个节点当前路径中访问的次数

        while !stack.isEmpty {
            if Task.isCancelled {
                return []
            }

            let (currentPod, currentPath) = stack.removeLast()

            // 跟踪访问次数
            visited[currentPod.name, default: 0] += 1

            if currentPod.name == endName {
                result.append(currentPath)
            } else {
                if let nextPods = currentPod[keyPath: keyPath] {
                    // 逆序遍历子节点，以保证顺序处理时栈顶的元素是第一个子节点
                    for nextPodName in nextPods.reversed() {
                        if let nextPod = nameToPodCache[nextPodName], !currentPath.contains(nextPodName) {
                            stack.append((nextPod, currentPath + [nextPodName]))
                        }
                    }
                }
            }

            // 回溯操作，如果当前节点访问完成，减少访问计数
            visited[currentPod.name, default: 0] -= 1
            if visited[currentPod.name] == 0 {
                visited.removeValue(forKey: currentPod.name)
            }
        }

        return result
    } */

    // 用于缓存计算过的路径
    actor PathCache {
        private var cache: [String: [[String]]] = [:]
        private var continuations: [String: [CheckedContinuation<[[String]], Never>]] = [:]

        func paths(for node: String) async -> [[String]]? {
            if let result = cache[node] {
                return result
            }
            return nil
        }

        func cache(_ paths: [[String]], for node: String) {
            cache[node] = paths

            if let conts = continuations.removeValue(forKey: node) {
                for cont in conts {
                    cont.resume(returning: paths)
                }
            }
        }

        func wait(for node: String) async -> [[String]]? {
            await withCheckedContinuation { continuation in
                if continuations[node] != nil {
                    continuations[node]?.append(continuation)
                } else {
                    continuations[node] = [continuation]
                }
            }
        }
    }

    struct StackFrame {
        let currentNode: String
        let path: [String]
    }

    @inline(__always)
    func findPaths(
        from startName: String,
        to endName: String,
        next keyPath: KeyPath<Pod, [String]?>,
        pods: [Pod],
        nameToPodCache: [String: Pod]
    ) async -> [[String]] {
        await findPaths(from: startName, to: endName, keyPath: keyPath, nameToPodCache: nameToPodCache, pathCache: PathCache())
    }

    func findPaths(
        from start: String,
        to end: String,
        keyPath: KeyPath<Pod, [String]?>,
        nameToPodCache: [String: Pod],
        pathCache: PathCache
    ) async -> [[String]] {
        if Task.isCancelled { return [] }

        var result: [[String]] = []
        var stack: [StackFrame] = [StackFrame(currentNode: start, path: [start])]

        while !stack.isEmpty {
            let frame = stack.removeLast()
            let currentNode = frame.currentNode
            let path = frame.path

            if currentNode == end {
                result.append(path)
                continue
            }

            if let cachedPaths = await pathCache.paths(for: currentNode) {
                if !cachedPaths.isEmpty {
                    result.append(contentsOf: cachedPaths.map { path + $0 })
                }
                continue
            }

            guard let currentPod = nameToPodCache[currentNode],
                    let nextNodes = currentPod[keyPath: keyPath],
                    !nextNodes.isEmpty else {
                await pathCache.cache([], for: currentNode)
                continue
            }

            let currentResult = await withTaskGroup(of: (Int, [[String]]).self) { taskGroup in
                for (index, nextNode) in nextNodes.enumerated() {
                    taskGroup.addTask {
                        if let cachedPaths = await pathCache.paths(for: nextNode) {
                            (index, cachedPaths)
                        } else {
                            await (index, self.findPaths(
                                from: nextNode,
                                to: end,
                                keyPath: keyPath,
                                nameToPodCache: nameToPodCache,
                                pathCache: pathCache
                            ))
                        }
                    }
                }

                var tmp: [Int: [[String]]] = [:]

                for await (index, subPaths) in taskGroup {
                    tmp[index] = subPaths
                }

                return tmp.sorted(by: { $0.key < $1.key }).flatMap(\.value)
            }

            result += currentResult.map { path + $0 }
            await pathCache.cache(currentResult, for: currentNode)
        }

        return result
    }

    func select(_ group: DisplaySectionGroupType, _ pod: Pod, pods: [Pod]) async {
        guard pod != selected else { return }
        isReleationLoading = true

        task?.cancel()
        task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            selected = pod

            @Sendable func nexts(_ start: Pod, _ end: Pod, keyPath: KeyPath<Pod, [String]?>) async -> [[String]] {
                await findPaths(
                    from: start.name,
                    to: end.name,
                    next: keyPath,
                    pods: pods,
                    nameToPodCache: nameToPodCache
                )
            }

            var paths: [[String]] = []
            switch group {
            case .all:
                paths = await nexts(start, pod, keyPath: \.successors)
                if paths.isEmpty {
                    paths = await nexts(pod, start, keyPath: \.successors)
                }
            case .successors:
                paths = await nexts(start, pod, keyPath: \.successors)
            case .predecessors:
                paths = await nexts(pod, start, keyPath: \.successors)
            }

            let tmp = paths
            if Task.isCancelled { return }
            await MainActor.run {
                self.paths = tmp
                self.isReleationLoading = false
            }
        }
    }

    func cancel() {
        task?.cancel()
    }
}

private extension RelationTreeData {
    // filter pod with searchKey
    func loadData() {
        var tmpShowNodes: [(DisplaySectionGroupType, [Pod])]
        if associatedOnly {
            if let associatedPods {
                tmpShowNodes = associatedPods
            } else {
                func associatedPods(start: Pod, keyPath: KeyPath<Pod, [String]?>) -> [Pod] {
                    var result = Set(arrayLiteral: start)
                    var nexts = [start]

                    while !nexts.isEmpty {
                        let nextNames = Set(nexts.compactMap { $0[keyPath: keyPath] }.flatMap { $0 })
                            .subtracting(result.map(\.name))

                        if nextNames.isEmpty {
                            break
                        } else {
                            nexts = nextNames.compactMap { nameToPodCache[$0] }
                            result.formUnion(nexts)
                        }
                    }

                    return result.sorted(by: { $0.name < $1.name })
                }

                tmpShowNodes = [
                    (.successors, associatedPods(start: start, keyPath: \.successors)),
                    (.predecessors, associatedPods(start: start, keyPath: \.predecessors))
                ]
            }
        } else {
            tmpShowNodes = [(.all, pods)]
        }

        if searchKey.isEmpty {
            showNames = tmpShowNodes.map { ($0.0, $0.1.map { ($0, [String.Index]?.none) }) }
        } else {
            let lowercasedSearchKey = searchKey.lowercased()
            showNames = tmpShowNodes.compactMap { group, pods in
                (group, pods.compactMap { pod in
                    if let indies = pod.lowercasedName.fuzzyMatch(lowercasedSearchKey) {
                        (pod, indies)
                    } else {
                        nil
                    }
                })
            }
        }

        for group in showNames {
            for pair in group.1 {
                if pair.0.name == searchKey {
                    Task.detached {
                        await self.select(group.group, pair.pod, pods: group.1.map(\.pod))
                    }
                    return
                }
            }
        }
    }

    func loadSearchSuggestions() {
        guard !searchKey.isEmpty else {
            searchSuggestions = []
            return
        }

        let lowercasedSearchKey = searchKey.lowercased()
        let searchSuggestions = showNames.map(\.1)
            .flatMap { $0 }
            .compactMap {
                if let indices = $0.0.lowercasedName.fuzzyMatch(lowercasedSearchKey) {
                    ($0.0, indices)
                } else {
                    nil
                }
            }

        if searchSuggestions.count <= 10 {
            self.searchSuggestions = searchSuggestions
        } else {
            self.searchSuggestions = []
        }
    }
}
