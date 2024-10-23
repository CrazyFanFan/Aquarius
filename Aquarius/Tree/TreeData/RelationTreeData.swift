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
    private(set) var path: [Pod] = []

    @ObservationIgnored private(set) var pods: [Pod]
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

    func select(_ pod: Pod) {
        guard pod != selected else { return }
        isReleationLoading = true

        task?.cancel()
        task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            self.selected = pod
            var path: [Pod] = []

            func dfs(_ current: Pod, path: inout [Pod], keyPath: KeyPath<Pod, [String]?>) -> Bool {
                if Task.isCancelled { return false }

                path.append(current)

                if current == selected {
                    return true
                }

                if let nexts = current[keyPath: keyPath] {
                    for next in nexts {
                        if let nextPod = nameToPodCache[next] {
                            if dfs(nextPod, path: &path, keyPath: keyPath) {
                                return true
                            }
                        }
                    }
                }
                path.removeLast()
                return false
            }

            _ = dfs(start, path: &path, keyPath: \.successors) || dfs(start, path: &path, keyPath: \.predecessors)
            DispatchQueue.main.async {
                self.path = path
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
