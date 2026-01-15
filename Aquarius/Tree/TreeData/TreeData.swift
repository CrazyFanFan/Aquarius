//
//  TreeData.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import Combine
import Observation
import SwiftUI

extension String {
    func fuzzyMatch(_ filter: String) -> Set<String.Index>? {
        if filter.isEmpty { return nil }

        func match(_ source: Substring, key: Substring) -> Set<String.Index>? {
            var indices: Set<Index> = []

            if let range = source.range(of: key) {
                var index = range.lowerBound
                while index < range.upperBound {
                    indices.insert(index)
                    index = source.index(after: index)
                }
                return indices
            }

            return nil
        }

        var indices: Set<Index> = []

        // perfect match first.
        if let matchs = match(self[startIndex...], key: filter[filter.startIndex...]) {
            return matchs
        }

        var filterIndex = filter.startIndex
        for index in self.indices {
            if self[index] == filter[filterIndex] {
                indices.insert(index)
                filterIndex = filter.index(after: filterIndex)

                if filterIndex == filter.endIndex { return indices }

                let remainder = filter[filterIndex...]
                let sourceStart = self.index(after: index)
                if let matchs = match(self[sourceStart...], key: remainder) {
                    return indices.union(matchs)
                }
            }
        }
        return nil
    }
}

@MainActor @Observable final class TreeData {
    @ObservationIgnored private var settings: AppSettings = .shared

    private(set) var nodes: [TreeNode] = []
    private(set) var searchSuggestions: [TreeNode] = []
    @ObservationIgnored private(set) var nameToPodCache: [String: Pod] = [:]
    @ObservationIgnored private var buildTreeTask: Task<Void, Never>?
    @ObservationIgnored private var rebuildVisibleTask: Task<Void, Never>?
    @ObservationIgnored private var searchDebounceTask: Task<Void, Never>?
    @ObservationIgnored var asyncShowPodspecTask: Task<Void, Never>?

    private(set) var showNodes: [TreeNode] = []

    private var isIgnoreLastModificationDate: Bool { settings.isIgnoreLastModificationDate }

    var currentCopyingCount: Int = 0
    var isCopying: Bool = false
    var copyMode: CopyingStrategy?
    @ObservationIgnored var copyTask: Task<CopyResult, Never>?
    @ObservationIgnored var copyProgressTask: Task<Void, Never>?
    var copyResult: CopyResult? {
        didSet {
            guard let copyResult else { return }
            switch copyResult {
            case let .file(url): Pasteboard.write(url.path)
            case let .string(string): Pasteboard.write(string)
            default: break
            }
        }
    }

    // load file
    @ObservationIgnored var lockFile: LockFileInfo {
        didSet {
            if isIgnoreLastModificationDate {
                loadFile()
            } else {
                checkShouldReloadData(oldLockFile: oldValue) { if $0 { self.loadFile() } }
            }
        }
    }

    @ObservationIgnored private var lastReadDataTime: Date?
    @ObservationIgnored var lock: PodfileLock? { isSubspeciesShow ? sourceLock : noSubspeciesLock }
    var isLockLoadFailed: Bool = false

    @ObservationIgnored private(set) var sourceLock: PodfileLock?
    @ObservationIgnored private(set) var noSubspeciesLock: PodfileLock?

    @ObservationIgnored var searchKey = "" {
        didSet {
            guard searchKey != oldValue else { return }

            let value = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)

            if searchKey != value {
                searchKey = value
            }

            searchDebounceTask?.cancel()
            let snapshot = searchKey
            searchDebounceTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard let self, !Task.isCancelled else { return }
                guard self.searchKey == snapshot else { return }
                if snapshot.isEmpty {
                    self.rebuildVisibleNodes(isImpact: self.isImpact)
                } else {
                    self.loadData(isImpact: self.isImpact, resetIsExpanded: false)
                }
                self.loadSearchSuggestions()
            }
        }
    }

    var detailMode: DetailMode = AppSettings.shared.detailMode {
        didSet {
            guard detailMode != oldValue else { return }
            if searchKey.isEmpty {
                rebuildVisibleNodes(isImpact: isImpact)
            } else {
                loadData(isImpact: isImpact, resetIsExpanded: false)
            }
        }
    }

    var orderRule: OrderBy = AppSettings.shared.orderRule {
        didSet {
            guard orderRule != oldValue else { return }
            if searchKey.isEmpty {
                rebuildVisibleNodes(isImpact: isImpact)
            } else {
                loadData(isImpact: isImpact, resetIsExpanded: false)
            }
        }
    }

    var isImpact: Bool { detailMode == .predecessors }

    // for show Podspec
    var isPodspecViewShow: Bool = false
    @ObservationIgnored var podspec: PodspecInfo?
    @ObservationIgnored var podspecCache: [Pod: PodspecInfo] = [:]

    var isSubspeciesShow: Bool {
        didSet {
            guard isSubspeciesShow != oldValue else { return }
            buildTree()
        }
    }

    init(lockFile: LockFileInfo) {
        self.lockFile = lockFile
        isSubspeciesShow = false
        isSubspeciesShow = settings.isSubspeciesShow

        loadFile()
    }

    func onSelected(node: TreeNode) {
        rebuildVisibleTask?.cancel()
        searchDebounceTask?.cancel()
        guard node.hasMore(isImpact: isImpact) else { return }

        node.isExpanded = !node.isExpanded

        if node.isExpanded {
            updateNext(for: node, isImpact: isImpact)
        }

        if searchKey.isEmpty {
            updateShowNodesIncrementally(for: node, isImpact: isImpact)
        } else {
            loadData(isImpact: isImpact)
        }
    }
}

// MARK: - Load File

private extension TreeData {
    func checkShouldReloadData(oldLockFile: LockFileInfo?, _ completion: ((_ isNeedReloadData: Bool) -> Void)?) {
        guard let completion else { return }

        // If is form bookmark or the old and new path do not match, the data must be reloaded.
        if lockFile != oldLockFile {
            completion(true)
            return
        }

        let file = lockFile

        // The data needs to be reloaded. if new path is empty.
        guard !file.url.path.isEmpty else {
            completion(false)
            return
        }

        // If read attributes fails, the data needs to be reloaded.
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.url.path),
              let fileModificationDate = attributes[.modificationDate] as? Date,
              let lastReadDataTime else {
                  completion(true)
                  return
              }

        if fileModificationDate.distance(to: lastReadDataTime) < 0 {
            completion(true)
        } else {
            completion(false)
        }
    }

    func loadFile() {
        let file = lockFile
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await Task.detached(priority: .userInitiated) {
                DataReader(file: file).readData()
            }.value
            if Task.isCancelled { return }

            self.lastReadDataTime = Date()
            if let (sourceLock, noSubspeciesLock) = result {
                self.sourceLock = sourceLock
                self.noSubspeciesLock = noSubspeciesLock
                self.buildTree()
                self.isLockLoadFailed = false
            } else {
                self.isLockLoadFailed = true
            }
        }
    }
}

// MARK: - load show data

private extension TreeData {
    @MainActor func buildTree() {
        nodes.removeAll()
        podspecCache.removeAll()
        nameToPodCache.removeAll()

        buildTreeTask?.cancel()
        let lockPods = lock?.pods ?? []
        let isImpactSnapshot = isImpact
        buildTreeTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let (nameToPod, topNodes) = await Task.detached(priority: .userInitiated) { () -> ([String: Pod], [TreeNode]) in
                var nameToPod: [String: Pod] = [:]
                nameToPod.reserveCapacity(lockPods.count)
                var topNodes: [TreeNode] = []
                topNodes.reserveCapacity(lockPods.count)

                for pod in lockPods {
                    nameToPod[pod.name] = pod
                    topNodes.append(TreeNode(deep: 0, pod: pod))
                }
                return (nameToPod, topNodes)
            }.value

            if Task.isCancelled { return }
            self.nameToPodCache = nameToPod
            self.nodes = topNodes
            self.loadData(isImpact: isImpactSnapshot)
        }
    }

    @MainActor func namesToNodes(deep: Int, names: [String]?) -> [TreeNode]? {
        names?.compactMap { dependence -> TreeNode? in
            if let pod = nameToPodCache[dependence],
               let node = Optional(TreeNode(deep: deep, pod: pod)) {
                return node
            }

            assertionFailure("find dependency without node")
            return nil
        }
    }

    @inline(__always)
    @MainActor func updateNext(for nodes: [TreeNode], isImpact: Bool) {
        for node in nodes {
            updateNext(for: node, isImpact: isImpact)
        }
    }

    @MainActor func updateNext(for node: TreeNode, isImpact: Bool) {
        if isImpact {
            if node.predecessors == nil {
                node.predecessors = namesToNodes(deep: node.deep + 1, names: node.pod.predecessors)
            }
        } else {
            if node.successors == nil {
                node.successors = namesToNodes(deep: node.deep + 1, names: node.pod.successors)
            }
        }
    }

    @MainActor func loadData(isImpact: Bool, resetIsExpanded: Bool = false) {
        if resetIsExpanded {
            resetExpandedState(nodes)
        }

        var tmpNodes = nodes

        if !searchKey.isEmpty {
            let lowerKey = searchKey.lowercased()
            tmpNodes = nodes.compactMap { node in
                guard let indices = node.pod.lowercasedName.fuzzyMatch(lowerKey) else { return nil }
                node.indices = indices
                return node
            }
        } else {
            for node in nodes {
                node.indices = nil
            }
        }

        let sortClosure = orderRule.sortClosure(isImpact: isImpact)

        tmpNodes.sort(by: sortClosure)

        var result: [TreeNode] = []
        result.reserveCapacity(tmpNodes.count)
        traverse(tmpNodes, isImpact: isImpact, sortClosure: sortClosure, output: &result)
        showNodes = result
    }

    @MainActor private func traverse(
        _ nodes: [TreeNode],
        isImpact: Bool,
        sortClosure: OrderBy.SortClosure,
        output: inout [TreeNode]
    ) {
        for node in nodes {
            output.append(node)

            if node.isExpanded, let subNodes = isImpact ? node.predecessors : node.successors {
                traverse(
                    subNodes.sorted(by: sortClosure),
                    isImpact: isImpact,
                    sortClosure: sortClosure,
                    output: &output
                )
            }
        }
    }

    @MainActor func resetExpandedState(_ nodes: [TreeNode]) {
        var stack: [TreeNode] = nodes
        while let node = stack.popLast() {
            node.isExpanded = false
            if let next = node.successors { stack.append(contentsOf: next) }
            if let next = node.predecessors { stack.append(contentsOf: next) }
        }
    }

    @MainActor func updateShowNodesIncrementally(for node: TreeNode, isImpact: Bool) {
        guard let index = showNodes.firstIndex(where: { $0 === node }) else {
            loadData(isImpact: isImpact)
            return
        }

        if node.isExpanded {
            var insertion: [TreeNode] = []
            let sortClosure = orderRule.sortClosure(isImpact: isImpact)
            let children = (isImpact ? node.predecessors : node.successors)?.sorted(by: sortClosure) ?? []
            appendVisible(children, isImpact: isImpact, sortClosure: sortClosure, output: &insertion)
            showNodes.insert(contentsOf: insertion, at: index + 1)
        } else {
            let baseDeep = node.deep
            var end = index + 1
            while end < showNodes.count, showNodes[end].deep > baseDeep { end += 1 }
            if end > index + 1 {
                showNodes.removeSubrange((index + 1)..<end)
            }
        }
    }

    @MainActor private func appendVisible(
        _ nodes: [TreeNode],
        isImpact: Bool,
        sortClosure: OrderBy.SortClosure,
        output: inout [TreeNode]
    ) {
        for node in nodes {
            output.append(node)
            if node.isExpanded {
                updateNext(for: node, isImpact: isImpact)
                let next = (isImpact ? node.predecessors : node.successors)?.sorted(by: sortClosure) ?? []
                appendVisible(next, isImpact: isImpact, sortClosure: sortClosure, output: &output)
            }
        }
    }

    @MainActor func rebuildVisibleNodes(isImpact: Bool) {
        rebuildVisibleTask?.cancel()
        let roots = nodes
        let orderRule = orderRule
        rebuildVisibleTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await Task.detached(priority: .userInitiated) {
                Self.buildVisibleNodes(roots: roots, orderRule: orderRule, isImpact: isImpact)
            }.value
            if Task.isCancelled { return }
            self.showNodes = result
        }
    }

    @MainActor func loadSearchSuggestions() {
        guard !searchKey.isEmpty else {
            searchSuggestions = []
            return
        }

        let lowercasedSearchKey = searchKey.lowercased()
        let searchSuggestions = nodes.filter { $0.pod.lowercasedName.fuzzyMatch(lowercasedSearchKey) != nil }
        if searchSuggestions.count <= 25 {
            self.searchSuggestions = searchSuggestions
        } else {
            self.searchSuggestions = []
        }
    }
}

private extension TreeData {
    nonisolated static func buildVisibleNodes(
        roots: [TreeNode],
        orderRule: OrderBy,
        isImpact: Bool
    ) -> [TreeNode] {
        let sortedRoots = roots.sorted { lhs, rhs in
            compare(lhs, rhs, orderRule: orderRule, isImpact: isImpact)
        }

        var result: [TreeNode] = []
        result.reserveCapacity(sortedRoots.count)

        var stack: [TreeNode] = Array(sortedRoots.reversed())
        while let node = stack.popLast() {
            result.append(node)
            guard node.isExpanded else { continue }
            let children = (isImpact ? node.predecessors : node.successors) ?? []
            guard !children.isEmpty else { continue }
            let sortedChildren = children.sorted { lhs, rhs in
                compare(lhs, rhs, orderRule: orderRule, isImpact: isImpact)
            }
            stack.append(contentsOf: sortedChildren.reversed())
        }

        return result
    }

    nonisolated static func compare(_ lhs: TreeNode, _ rhs: TreeNode, orderRule: OrderBy, isImpact: Bool) -> Bool {
        switch orderRule {
        case .alphabeticalAscending:
            lhs.pod.name < rhs.pod.name
        case .alphabeticalDescending:
            lhs.pod.name > rhs.pod.name
        case .numberAscending:
            (lhs.pod.nextLevel(isImpact)?.count ?? 0) < (rhs.pod.nextLevel(isImpact)?.count ?? 0)
        case .numberDescending:
            !((lhs.pod.nextLevel(isImpact)?.count ?? 0) < (rhs.pod.nextLevel(isImpact)?.count ?? 0))
        }
    }
}

private func < (lhs: Int?, rhs: Int?) -> Bool {
    switch (lhs, rhs) {
    case (.some, .none), (.none, .none): false
    case (.none, .some): true
    case let (.some(lhsValue), .some(rhsValue)): lhsValue < rhsValue
    }
}

private extension OrderBy {
    typealias SortClosure = (_ lhs: TreeNode, _ rhs: TreeNode) -> Bool

    func sortClosure(isImpact: Bool) -> SortClosure {
        switch self {
        case .alphabeticalAscending: { $0.pod.name < $1.pod.name }
        case .alphabeticalDescending: { $0.pod.name > $1.pod.name }
        case .numberAscending: { $0.pod.nextLevel(isImpact)?.count < $1.pod.nextLevel(isImpact)?.count }
        case .numberDescending: { !($0.pod.nextLevel(isImpact)?.count < $1.pod.nextLevel(isImpact)?.count) }
        }
    }
}
