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

private extension String {
    func fuzzyMatch(_ filter: String) -> [String.Index]? {
        func match(_ source: Substring, key: Substring) -> [String.Index]? {
            if let range = source.range(of: key) {
                var result: [String.Index] = []
                var index = range.lowerBound
                while index < range.upperBound {
                    result.append(index)
                    index = source.index(after: index)
                }
                return result
            }

            return nil
        }

        var indexs: [Index] = []
        if filter.isEmpty { return nil }

        // perfect match first.
        if let matchs = match(self[self.startIndex...], key: filter[filter.startIndex...]) {
            return matchs
        }

        var remainder = filter[...].utf8
        for index in utf8.indices {
            let char = utf8[index]
            if char == remainder[remainder.startIndex] {
                indexs.append(index)
                remainder.removeFirst()

                // try perfect match.
                if let matchs = match(self[index...], key: filter[remainder.startIndex...]) {
                    return indexs + matchs
                }

                if remainder.isEmpty { return indexs }
            }
        }
        return nil
    }
}

@Observable final class TreeData {
    private var global: GlobalState = .shared

    private var podToNodeCache: [Pod: TreeNode] = [:]
    private var nameToNodeCache: [String: TreeNode] = [:]
    private var nodes: [TreeNode] = []
    private(set) var searchSuggestions: [TreeNode] = []
    private(set) var nameToPodCache: [String: Pod] = [:]
    private var buildTreeTask: Task<Void, Never>?

    private var loadShowNodesTmp: [TreeNode] = []
    @MainActor private(set) var showNodes: [TreeNode] = []

    private var isIgnoreLastModificationDate: Bool { global.isIgnoreLastModificationDate }

    /// for copy
    @MainActor var copyProgress: Double = 0 {
        didSet {
            if copyProgress == 0 || copyProgress == 1 || copyProgress - displayCopyProgress > 0.01 {
                displayCopyProgress = copyProgress
            }
        }
    }

    @MainActor var displayCopyProgress: Double = 0
    @MainActor var isCopying: Bool = false
    @ObservationIgnored var copyTask: Task<Void, Error>?

    @MainActor var copyResult: (content: String, isWriteToFile: Bool)?

    // load file
    @ObservationIgnored var lockFile: LockFileInfo {
        didSet {
            if isIgnoreLastModificationDate {
                self.loadFile()
            } else {
                checkShouldReloadData(oldLockFile: oldValue) { isNeedReloadData in
                    if isNeedReloadData {
                        self.loadFile()
                    }
                }
            }
        }
    }

    private var lastReadDataTime: Date?
    var lock: PodfileLock? { isSubspeciesShow ? sourceLock : noSubspeciesLock }
    @MainActor var isLockLoadFailed: Bool = false

    @ObservationIgnored private(set) var sourceLock: PodfileLock?
    @ObservationIgnored private(set) var noSubspeciesLock: PodfileLock?

    @ObservationIgnored var searchKey = "" {
        didSet {
            guard searchKey != oldValue else { return }

            let value = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)

            if searchKey != value {
                searchKey = value
            }

            loadData(isImpact: isImpact, resetIsExpanded: true)
            loadSearchSuggestions()
        }
    }

    var detailMode: DetailMode = GlobalState.shared.detailMode {
        didSet { if detailMode != oldValue { loadData(isImpact: isImpact, resetIsExpanded: true) } }
    }

    var orderRule: OrderBy = GlobalState.shared.orderRule {
        didSet { if orderRule != oldValue { loadData(isImpact: isImpact, resetIsExpanded: false) } }
    }

    var isImpact: Bool { detailMode == .predecessors }

    // for show Podspec
    @ObservationIgnored var podspec: PodspecInfo?
    @MainActor var isPodspecShow: Bool = false

    @ObservationIgnored var podspecCache: [Pod: PodspecInfo] = [:]

    var isSubspeciesShow: Bool {
        didSet { if isSubspeciesShow != oldValue { buildTree() }}
    }

    init(lockFile: LockFileInfo) {
        self.lockFile = lockFile
        self.isSubspeciesShow = false
        self.isSubspeciesShow = global.isSubspeciesShow

        self.loadFile()
    }

    func onSelected(node: TreeNode) {
        guard node.hasMore(isImpact: isImpact) else { return }

        node.isExpanded = !node.isExpanded

        updateNext(for: node, isImpact: isImpact)
        loadData(isImpact: isImpact)
    }

    func runWithMainActor(_ action: @Sendable @escaping @MainActor () -> Void) {
        Task {
            await MainActor.run(body: action)
        }
    }
}

// MARK: - Load File
private extension TreeData {
    func checkShouldReloadData(oldLockFile: LockFileInfo?, _ completion: ((_ isNeedReloadData: Bool) -> Void)?) {
        guard let completion = completion else { return }

        // If is form bookmark or the old and new path do not match, the data must be reloaded.
        if self.lockFile != oldLockFile {
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
              let lastReadDataTime = self.lastReadDataTime else {
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
        Task {
            self.lastReadDataTime = Date()
            if let (sourceLock, noSubspeciesLock) = DataReader(file: lockFile).readData() {
                // update lock data
                self.sourceLock = sourceLock
                self.noSubspeciesLock = noSubspeciesLock
                self.buildTree()
                runWithMainActor {
                    self.isLockLoadFailed = false
                }
            } else {
                runWithMainActor {
                    self.isLockLoadFailed = true
                }
            }
        }
    }
}

// MARK: - load show data
private extension TreeData {
    func buildTree() {
        nodes.removeAll()
        podspecCache.removeAll()
        nameToPodCache.removeAll()
        podToNodeCache.removeAll()

        buildTreeTask?.cancel()
        buildTreeTask = Task.detached {
            // top level
            self.lock?.pods.forEach { (pod) in
                self.nameToPodCache[pod.name] = pod
                let node = TreeNode(deep: 0, pod: pod)
                self.podToNodeCache[pod] = node
                self.nodes.append(node)
            }
            self.loadData(isImpact: self.isImpact)
        }
    }

    func namesToNodes(deep: Int, names: [String]?) -> [TreeNode]? {
        names?.compactMap { (dependence) -> TreeNode? in
            if let node = nameToNodeCache[dependence]?.copy(with: deep, isImpact: isImpact) {
                return node
            }

            if let pod = self.lock?.pods.first(where: { $0.name == dependence }),
               let node = podToNodeCache[pod]?.copy(with: deep, isImpact: isImpact) {
                return node
            }

            assertionFailure("find dependency without node")
            return nil
        }
    }

    @inline(__always)
    func updateNext(for nodes: [TreeNode], isImpact: Bool) {
        nodes.forEach { updateNext(for: $0, isImpact: isImpact) }
    }

    func updateNext(for node: TreeNode, isImpact: Bool) {
        if isImpact {
            node.predecessors = namesToNodes(deep: node.deep + 1, names: node.pod.predecessors)
        } else {
            node.successors = namesToNodes(deep: node.deep + 1, names: node.pod.successors)
        }
    }

    func loadData(isImpact: Bool, resetIsExpanded: Bool = false) {
        loadShowNodesTmp.removeAll()

        if resetIsExpanded {
            nodes.forEach { $0.isExpanded = false }
        }

        var tmpNodes = nodes

        if !self.searchKey.isEmpty {
            let lowerKey = self.searchKey.lowercased()
            tmpNodes = nodes.compactMap { node in
                guard let indices = node.pod.lowercasedName.fuzzyMatch(lowerKey) else { return nil }
                node.indices = indices
                return node
            }
        } else {
            nodes.forEach { $0.indices = nil }
        }

        let sortClosure = orderRule.sortClosure(isImpact: isImpact)

        tmpNodes.sort(by: sortClosure)

        traverse(tmpNodes, isImpact: isImpact, sortClosure: sortClosure)
    }

    private func traverse(
        _ nodes: [TreeNode],
        isImpact: Bool,
        sortClosure: OrderBy.SortClosure
    ) {
        for node in nodes {
            loadShowNodesTmp.append(node)

            if node.isExpanded, let subNodes = isImpact ? node.predecessors : node.successors {
                traverse(
                    subNodes.sorted(by: sortClosure),
                    isImpact: isImpact,
                    sortClosure: sortClosure
                )
            }
        }

        runWithMainActor {
            self.showNodes = self.loadShowNodesTmp
        }
    }

    func loadSearchSuggestions() {
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

private func < (lhs: Int?, rhs: Int?) -> Bool {
    switch (lhs, rhs) {
    case (.some, .none), (.none, .none): return false
    case (.none, .some): return true
    case (.some(let lhsValue), .some(let rhsValue)): return lhsValue < rhsValue
    }
}

private extension OrderBy {
    typealias SortClosure = (_ lhs: TreeNode, _ rhs: TreeNode) -> Bool

    func sortClosure(isImpact: Bool) -> SortClosure {
        switch self {
        case .alphabeticalAscending:
            return { $0.pod.name < $1.pod.name }
        case .alphabeticalDescending:
            return { $0.pod.name > $1.pod.name }
        case .numberAscending:
            return { $0.pod.nextLevel(isImpact)?.count < $1.pod.nextLevel(isImpact)?.count }
        case .numberDescending:
            return { !($0.pod.nextLevel(isImpact)?.count < $1.pod.nextLevel(isImpact)?.count) }
        }
    }
}
