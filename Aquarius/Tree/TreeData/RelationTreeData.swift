//
//  RelationTreeData.swift
//  Aquarius
//
//  Created by Crazy凡 on 2024/10/27.
//

import Combine
import Observation
import SwiftUI

@Observable final class RelationTreeData {
    @ObservationIgnored private(set) var start: Pod
    private(set) var selected: Pod?
    private(set) var isReleationLoading: Bool = false
    private(set) var paths: [[String]] = []

    @ObservationIgnored private(set) var pods: [Pod]
    @ObservationIgnored private(set) var associatedPods: [Pod]?
    @ObservationIgnored private(set) var nameToPodCache: [String: Pod]
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

    @ObservationIgnored var associatedOnly = false {
        didSet {
            guard associatedOnly != oldValue else { return }

            loadData()
            loadSearchSuggestions()
        }
    }

    private(set) var showNames: [(pod: Pod, indices: [String.Index]?)] = []
    private(set) var searchSuggestions: [(pod: Pod, indices: [String.Index]?)] = []

    private var task: Task<Void, Never>?

    init(start: Pod, pods: [Pod], nameToPodCache: [String: Pod]) {
        self.start = start
        self.pods = pods
        self.nameToPodCache = nameToPodCache

        loadData()
    }

    func findPaths(
        from start: Pod,
        to endName: String,
        nexts keyPath: KeyPath<Pod, [String]?>,
        pods: [Pod],
        nameToPodCache: [String: Pod]
    ) -> [[String]] {
        var result: [[String]] = []
        var visited: Set<String> = Set()
        var currentPath: [String] = []

        // 缓存计算得到的路径
        var pathCache: [String: [[String]]] = [:]

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
                            // 如果没有缓存，则进行深度搜索
                            dfs(currentPod: nextPod)
                        }
                    }
                }
            }

            // 在当前路径搜索完后缓存结果
            if currentPod.name == start.name {
                pathCache[currentPod.name] = result
            }

            // 回溯
            currentPath.removeLast()
            visited.remove(currentPod.name)
        }

        // 在进行深度优先搜索之前查看缓存
        if let cachedPaths = pathCache[start.name] {
            return cachedPaths
        } else {
            dfs(currentPod: start)
        }

        // 返回计算结果
        return result
    }

    func select(_ pod: Pod) {
        guard pod != selected else { return }
        isReleationLoading = true

        task?.cancel()
        task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            selected = pod

            var paths = findPaths(
                from: start,
                to: pod.name,
                nexts: \.successors,
                pods: associatedOnly ? associatedPods ?? pods : pods,
                nameToPodCache: nameToPodCache
            )
            if paths.isEmpty {
                paths = findPaths(
                    from: start,
                    to: pod.name,
                    nexts: \.predecessors,
                    pods: associatedOnly ? associatedPods ?? pods : pods,
                    nameToPodCache: nameToPodCache
                ).map { $0.reversed() }
            }

            DispatchQueue.main.async {
                self.paths = paths
                self.isReleationLoading = false
            }
        }
    }
}

private extension RelationTreeData {
    // filter pod with searchKey
    func loadData() {
        var tmpShowNodes: [Pod]
        if associatedOnly {
            if let associatedPods {
                tmpShowNodes = associatedPods
            } else {
                var result = Set(arrayLiteral: start)
                var news = [start]
                while !news.isEmpty {
                    result.formUnion(news)
                    let nextLevelNames = Set((news.compactMap(\.predecessors) + news.compactMap(\.successors)).flatMap { $0 })
                        .subtracting(result.map(\.name))
                    if nextLevelNames.isEmpty {
                        break
                    } else {
                        news = nextLevelNames.compactMap { nameToPodCache[$0] }
                    }
                }
                tmpShowNodes = result.sorted(by: { $0.name < $1.name })
                associatedPods = tmpShowNodes
            }
        } else {
            tmpShowNodes = pods
        }

        if searchKey.isEmpty {
            showNames = tmpShowNodes.map { ($0, nil) }
        } else {
            let lowercasedSearchKey = searchKey.lowercased()
            showNames = tmpShowNodes.compactMap { pod in
                if let indies = pod.lowercasedName.fuzzyMatch(lowercasedSearchKey) {
                    (pod, indies)
                } else {
                    nil
                }
            }
        }

        if let node = showNames.first(where: { $0.pod.lowercasedName == searchKey }) {
            select(node.pod)
        }
    }

    func loadSearchSuggestions() {
        guard !searchKey.isEmpty else {
            searchSuggestions = []
            return
        }

        let lowercasedSearchKey = searchKey.lowercased()
        let searchSuggestions = showNames.filter { $0.0.lowercasedName.fuzzyMatch(lowercasedSearchKey) != nil }
        if searchSuggestions.count <= 10 {
            self.searchSuggestions = searchSuggestions
        } else {
            self.searchSuggestions = []
        }
    }
}
