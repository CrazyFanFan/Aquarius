//
//  RelationTreeData.swift
//  Aquarius
//
//  Created by Crazy凡 on 2024/10/27.
//

import Combine
import Foundation
import Observation
import SwiftUI

enum DisplaySectionGroupType: String, Hashable {
    case all = "All Modules"
    case successors = "Dependent Modules"
    case predecessors = "Requiring Modules"
}

struct RelationSummary: Hashable {
    let nodeCount: Int
    let edgeCount: Int
    let shortestDepth: Int
    let subgraph: RelationSubgraph
}

struct RelationSubgraph: Hashable {
    let levels: [[String]]
    let edges: [RelationEdge]
}

struct RelationEdge: Hashable {
    let from: String
    let to: String
}

@MainActor @Observable final class RelationTreeData {
    nonisolated static let maxPathCount = 20

    @ObservationIgnored private(set) var start: Pod
    private(set) var selected: Pod?
    private(set) var isReleationLoading: Bool = false
    private(set) var isPathSearchLimited: Bool = false
    private(set) var loadsAllPaths: Bool = false
    private(set) var summary: RelationSummary?
    private(set) var paths: [[String]] = []

    @ObservationIgnored private(set) var pods: [Pod]
    @ObservationIgnored private(set) var associatedPods: [(DisplaySectionGroupType, [Pod])]?
    @ObservationIgnored private(set) var nameToPodCache: [String: Pod]
    @ObservationIgnored private(set) var nameToSuccessors: [String: [String]]

    private(set) var showNames: [(group: DisplaySectionGroupType, [(pod: Pod, indices: Set<String.Index>?)])] = []
    private(set) var searchSuggestions: [(pod: Pod, indices: Set<String.Index>?)] = []

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
    @ObservationIgnored private var taskToken: UUID?
    @ObservationIgnored private var selectedGroup: DisplaySectionGroupType?
    @ObservationIgnored private var selectedCacheKey: SelectionCacheKey?
    @ObservationIgnored private var selectedResultCache: [Bool: RelationLoadResult] = [:]

    private struct SelectionCacheKey: Hashable {
        let group: DisplaySectionGroupType
        let podName: String
    }

    private struct RelationLoadResult: Hashable {
        let summary: RelationSummary?
        let paths: [[String]]
        let isLimited: Bool
    }

    actor PathCache {
        private var cache: [String: [[String]]] = [:]
        private var continuations: [String: [UUID: CheckedContinuation<[[String]], Error>]] = [:]

        func cache(_ paths: [[String]], for node: String) {
            cache[node] = paths

            if let continuations = continuations.removeValue(forKey: node) {
                for continuation in continuations.values {
                    continuation.resume(returning: paths)
                }
            }
        }

        func fail(_ error: Error, for node: String) {
            if let continuations = continuations.removeValue(forKey: node) {
                for continuation in continuations.values {
                    continuation.resume(throwing: error)
                }
            }
        }

        func pathsOrWait(for node: String) async throws -> [[String]]? {
            if let paths = cache[node] {
                return paths
            }
            if continuations[node] != nil {
                return try await wait(for: node)
            }
            continuations[node] = [:]
            return nil
        }

        private func cancelContinuation(_ id: UUID, for node: String) {
            if let continuation = continuations[node]?.removeValue(forKey: id) {
                continuation.resume(throwing: CancellationError())
            }

            if continuations[node]?.isEmpty == true {
                continuations.removeValue(forKey: node)
            }
        }

        private func wait(for node: String) async throws -> [[String]] {
            let id = UUID()

            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    if continuations[node] != nil {
                        continuations[node]?[id] = continuation
                    } else {
                        continuations[node] = [id: continuation]
                    }
                }
            } onCancel: {
                Task {
                    await self.cancelContinuation(id, for: node)
                }
            }
        }
    }

    struct StackFrame {
        let currentNode: String
        let path: [String]
    }

    init(start: Pod, pods: [Pod], nameToPodCache: [String: Pod]) {
        self.start = start
        self.pods = pods
        self.nameToPodCache = nameToPodCache
        nameToSuccessors = nameToPodCache.reduce(into: [:]) { partialResult, pair in
            partialResult[pair.key] = pair.value.successors
        }

        loadData()
    }

    @inline(__always)
    nonisolated static func summarizeRelation(
        from startName: String,
        to endName: String,
        graph: [String: [String]]
    ) throws -> RelationSummary? {
        try Task.checkCancellation()

        let reverseGraph = graph.reduce(into: [String: [String]]()) { partialResult, item in
            for nextNode in item.value {
                partialResult[nextNode, default: []].append(item.key)
            }
        }
        let reachableFromStart = try reachableNodes(from: startName, graph: graph)
        let canReachEnd = try reachableNodes(from: endName, graph: reverseGraph)
        let relationNodes = reachableFromStart.intersection(canReachEnd)

        guard relationNodes.contains(startName), relationNodes.contains(endName) else {
            return nil
        }

        guard let shortestDepth = try shortestDepth(from: startName, to: endName, graph: graph) else {
            return nil
        }

        let subgraph = try makeSubgraph(from: startName, relationNodes: relationNodes, graph: graph)

        return RelationSummary(
            nodeCount: relationNodes.count,
            edgeCount: subgraph.edges.count,
            shortestDepth: shortestDepth,
            subgraph: subgraph
        )
    }

    @inline(__always)
    nonisolated static func makeSubgraph(
        from startName: String,
        relationNodes: Set<String>,
        graph: [String: [String]]
    ) throws -> RelationSubgraph {
        var edges: [RelationEdge] = []
        for node in relationNodes.sorted() {
            for nextNode in graph[node] ?? [] where relationNodes.contains(nextNode) {
                edges.append(RelationEdge(from: node, to: nextNode))
            }
        }

        var depths = [startName: 0]
        var queue = [startName]
        var head = 0

        while head < queue.count {
            try Task.checkCancellation()

            let node = queue[head]
            head += 1
            guard let depth = depths[node] else { continue }

            for nextNode in graph[node] ?? [] where relationNodes.contains(nextNode) {
                if depths[nextNode] == nil {
                    depths[nextNode] = depth + 1
                    queue.append(nextNode)
                }
            }
        }

        let maxDepth = depths.values.max() ?? 0
        let levels = (0 ... maxDepth).map { depth in
            depths
                .filter { $0.value == depth }
                .map(\.key)
                .sorted()
        }

        return RelationSubgraph(levels: levels, edges: edges)
    }

    @inline(__always)
    nonisolated static func reachableNodes(from startName: String, graph: [String: [String]]) throws -> Set<String> {
        var result = Set([startName])
        var queue = [startName]
        var head = 0

        while head < queue.count {
            try Task.checkCancellation()

            let node = queue[head]
            head += 1

            for nextNode in graph[node] ?? [] {
                if result.insert(nextNode).inserted {
                    queue.append(nextNode)
                }
            }
        }

        return result
    }

    @inline(__always)
    nonisolated static func shortestDepth(
        from startName: String,
        to endName: String,
        graph: [String: [String]]
    ) throws -> Int? {
        var visited = Set([startName])
        var queue = [(node: startName, depth: 0)]
        var head = 0

        while head < queue.count {
            try Task.checkCancellation()

            let item = queue[head]
            head += 1

            if item.node == endName {
                return item.depth
            }

            for nextNode in graph[item.node] ?? [] {
                if visited.insert(nextNode).inserted {
                    queue.append((node: nextNode, depth: item.depth + 1))
                }
            }
        }

        return nil
    }

    @inline(__always)
    nonisolated static func findPaths(
        from startName: String,
        to endName: String,
        graph: [String: [String]]
    ) throws -> (paths: [[String]], isLimited: Bool) {
        try Task.checkCancellation()

        var result: [[String]] = []
        var queue: [[String]] = [[startName]]
        var head = 0

        while head < queue.count {
            try Task.checkCancellation()

            let path = queue[head]
            head += 1
            guard let node = path.last else { continue }

            if node == endName {
                result.append(path)
                if result.count >= maxPathCount {
                    return (result, true)
                }
                continue
            }

            for nextNode in graph[node] ?? [] {
                if !path.contains(nextNode) {
                    queue.append(path + [nextNode])
                }
            }
        }

        return (result, false)
    }

    @inline(__always)
    nonisolated static func findAllPaths(
        from startName: String,
        to endName: String,
        graph: [String: [String]]
    ) async throws -> [[String]] {
        try await findAllPaths(from: startName, to: endName, graph: graph, pathCache: PathCache())
    }

    nonisolated static func findAllPaths(
        from startName: String,
        to endName: String,
        graph: [String: [String]],
        pathCache: PathCache
    ) async throws -> [[String]] {
        try Task.checkCancellation()

        var result: [[String]] = []
        var stack = [StackFrame(currentNode: startName, path: [startName])]

        while !stack.isEmpty {
            try Task.checkCancellation()

            let frame = stack.removeLast()
            let currentNode = frame.currentNode
            let path = frame.path

            if currentNode == endName {
                result.append(path)
                continue
            }

            if let cachedPaths = try await pathCache.pathsOrWait(for: currentNode) {
                if !cachedPaths.isEmpty {
                    result.append(contentsOf: cachedPaths.map { path + $0 })
                }
                continue
            }

            guard let nextNodes = graph[currentNode], !nextNodes.isEmpty else {
                await pathCache.cache([], for: currentNode)
                continue
            }

            do {
                let currentResult = try await withThrowingTaskGroup(of: (Int, [[String]]).self) { taskGroup in
                    for (index, nextNode) in nextNodes.enumerated() {
                        taskGroup.addTask {
                            let paths = try await findAllPaths(from: nextNode, to: endName, graph: graph, pathCache: pathCache)
                            return (index, paths)
                        }
                    }

                    var tmp: [Int: [[String]]] = [:]

                    for try await (index, paths) in taskGroup {
                        tmp[index] = paths
                    }

                    return tmp.sorted { $0.key < $1.key }.flatMap(\.value)
                }

                result += currentResult.map { path + $0 }
                await pathCache.cache(currentResult, for: currentNode)
            } catch {
                await pathCache.fail(error, for: currentNode)
                throw error
            }
        }

        return result
    }

    func select(_ group: DisplaySectionGroupType, _ pod: Pod) {
        guard pod != selected else { return }
        loadsAllPaths = false
        loadPaths(group: group, pod: pod, loadsAllPaths: false, clearsExistingResult: true)
    }

    func setLoadsAllPaths(_ value: Bool) {
        guard value != loadsAllPaths else { return }
        loadsAllPaths = value

        guard let selected, let selectedGroup else { return }

        loadPaths(group: selectedGroup, pod: selected, loadsAllPaths: value, clearsExistingResult: false)
    }

    private func loadPaths(
        group: DisplaySectionGroupType,
        pod: Pod,
        loadsAllPaths: Bool,
        clearsExistingResult: Bool
    ) {
        isReleationLoading = true

        task?.cancel()
        selected = pod
        selectedGroup = group
        let cacheKey = SelectionCacheKey(group: group, podName: pod.name)
        if selectedCacheKey != cacheKey {
            selectedCacheKey = cacheKey
            selectedResultCache = [:]
        }
        if let cachedResult = selectedResultCache[loadsAllPaths] {
            summary = cachedResult.summary
            paths = cachedResult.paths
            isPathSearchLimited = cachedResult.isLimited
            isReleationLoading = false
            task = nil
            taskToken = nil
            return
        }
        if clearsExistingResult {
            paths = []
            summary = nil
            isPathSearchLimited = false
        }
        let token = UUID()
        taskToken = token
        let startName = start.name
        let endName = pod.name
        let graph = nameToSuccessors
        task = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                var result: (paths: [[String]], isLimited: Bool) = ([], false)
                var summary: RelationSummary?
                switch group {
                case .all:
                    summary = try Self.summarizeRelation(from: startName, to: endName, graph: graph)
                    if summary != nil {
                        result = try await Self.findPaths(from: startName, to: endName, graph: graph, loadsAllPaths: loadsAllPaths)
                    }
                    if result.paths.isEmpty {
                        try Task.checkCancellation()
                        summary = try Self.summarizeRelation(from: endName, to: startName, graph: graph)
                        if summary != nil {
                            result = try await Self.findPaths(from: endName, to: startName, graph: graph, loadsAllPaths: loadsAllPaths)
                        }
                    }
                case .successors:
                    summary = try Self.summarizeRelation(from: startName, to: endName, graph: graph)
                    if summary != nil {
                        result = try await Self.findPaths(from: startName, to: endName, graph: graph, loadsAllPaths: loadsAllPaths)
                    }
                case .predecessors:
                    summary = try Self.summarizeRelation(from: endName, to: startName, graph: graph)
                    if summary != nil {
                        result = try await Self.findPaths(from: endName, to: startName, graph: graph, loadsAllPaths: loadsAllPaths)
                    }
                }

                try Task.checkCancellation()
                await MainActor.run {
                    guard let self, self.taskToken == token, !Task.isCancelled else { return }
                    self.summary = summary
                    self.paths = result.paths
                    self.isPathSearchLimited = result.isLimited
                    self.selectedResultCache[loadsAllPaths] = RelationLoadResult(
                        summary: summary,
                        paths: result.paths,
                        isLimited: result.isLimited
                    )
                    self.isReleationLoading = false
                    self.task = nil
                    self.taskToken = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard let self, self.taskToken == token else { return }
                    self.isReleationLoading = false
                    self.task = nil
                    self.taskToken = nil
                }
            } catch {
                await MainActor.run {
                    guard let self, self.taskToken == token, !Task.isCancelled else { return }
                    self.summary = nil
                    self.paths = []
                    self.isPathSearchLimited = false
                    self.isReleationLoading = false
                    self.task = nil
                    self.taskToken = nil
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        taskToken = nil
        isReleationLoading = false
        isPathSearchLimited = false
        summary = nil
        selectedResultCache = [:]
        selectedCacheKey = nil
    }

    @inline(__always)
    private nonisolated static func findPaths(
        from startName: String,
        to endName: String,
        graph: [String: [String]],
        loadsAllPaths: Bool
    ) async throws -> (paths: [[String]], isLimited: Bool) {
        if loadsAllPaths {
            let paths = try await findAllPaths(from: startName, to: endName, graph: graph)
            return (paths, false)
        }

        return try findPaths(from: startName, to: endName, graph: graph)
    }
}

private extension RelationTreeData {
    /// filter pod with searchKey
    func loadData() {
        var tmpShowNodes: [(DisplaySectionGroupType, [Pod])]
        if associatedOnly {
            if let associatedPods {
                tmpShowNodes = associatedPods
            } else {
                func collectAssociatedPods(start: Pod, keyPath: KeyPath<Pod, [String]>) -> [Pod] {
                    var result = Set(arrayLiteral: start)
                    var nexts = [start]

                    while !nexts.isEmpty {
                        let nextNames = Set(nexts.flatMap { $0[keyPath: keyPath] })
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
                    (.successors, collectAssociatedPods(start: start, keyPath: \.successors)),
                    (.predecessors, collectAssociatedPods(start: start, keyPath: \.predecessors))
                ]
                associatedPods = tmpShowNodes
            }
        } else {
            tmpShowNodes = [(.all, pods)]
        }

        if searchKey.isEmpty {
            showNames = tmpShowNodes.map { ($0.0, $0.1.map { ($0, Set<String.Index>?.none) }) }
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
                    select(group.group, pair.pod)
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
