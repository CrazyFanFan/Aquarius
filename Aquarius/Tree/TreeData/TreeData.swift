//
//  TreeData.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI
import Combine

class TreeData: ObservableObject {
    private var global: GlobalState = .shared

    private var podToNodeCache: [Pod: TreeNode] = [:]
    private var nameToNodeCache: [String: TreeNode] = [:]
    private var nodes: [TreeNode] = []
    private(set) var nameToPodCache: [String: Pod] = [:]

    private var loadShowNodesTmp: [TreeNode] = []
    @Published private(set) var showNodes: [TreeNode] = []

    private var isIgnoreLastModificationDate: Bool { global.isIgnoreLastModificationDate }

    /// for copy
    var copyProgress: Double = 0 {
        didSet {
            if copyProgress == 0 || copyProgress == 1 || copyProgress - displayCopyProgress > 0.01 {
                displayCopyProgress = copyProgress
            }
        }
    }
    @Published var displayCopyProgress: Double = 0
    @Published var isCopying: Bool = false
    var copyTask: Task<Void, Error>?

    @Published var copyResult: (content: String, isWriteToFile: Bool)?

    // load file
    var lockFile: LockFileInfo? {
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
    @Published var isLockLoadFailed: Bool = false

    private(set) var sourceLock: PodfileLock?
    private(set) var noSubspeciesLock: PodfileLock?

    var searchKey = "" {
        didSet {
            let value = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)

            if searchKey != value {
                searchKey = value
            }

            loadData(isImpact: isImpact, resetIsExpanded: true)
        }
    }

    @Published var detailMode: DetailMode = GlobalState.shared.detailMode {
        didSet { if detailMode != oldValue { loadData(isImpact: isImpact, resetIsExpanded: true) } }
    }

    @Published var orderRule: OrderBy = GlobalState.shared.orderRule {
        didSet { if orderRule != oldValue { loadData(isImpact: isImpact, resetIsExpanded: false) } }
    }

    var isImpact: Bool { detailMode == .predecessors }

    private(set) var queue = DispatchQueue(label: "aquarius_data_parse_queue")

    // for show Podspec
    var podspec: PodspecInfo?
    @Published var isPodspecShow: Bool = false

    var podspecCache: [Pod: PodspecInfo] = [:]

    @Published var isSubspeciesShow: Bool {
        didSet { if isSubspeciesShow != oldValue { buildTree() }}
    }

    init(lockFile: LockFileInfo) {
        self.lockFile = lockFile
        self.isSubspeciesShow = global.isSubspeciesShow

        self.loadFile()
    }

    func onSelected(node: TreeNode) {
        guard node.hasMore(isImpact: isImpact) else { return }

        node.isExpanded = !node.isExpanded

        updateNext(for: node, isImpact: isImpact)
        loadData(isImpact: isImpact)
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

        // The data needs to be reloaded. if new path is nil or empty.
        guard let file = lockFile, !file.url.path.isEmpty else {
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
        DispatchQueue.main.async {
            guard let info = self.lockFile else { return }
            self.queue.async {
                self.lastReadDataTime = Date()
                if let (sourceLock, noSubspeciesLock) = DataReader(file: info).readData() {
                    DispatchQueue.main.async {
                        // update lock data
                        self.sourceLock = sourceLock
                        self.noSubspeciesLock = noSubspeciesLock
                        self.buildTree()
                        self.isLockLoadFailed = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLockLoadFailed = true
                    }
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

        queue.async {
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

            assert(false, "find dependency without node")
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
            tmpNodes = nodes.filter { $0.pod.name.lowercased().contains(lowerKey) }
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

        DispatchQueue.main.async {
            self.showNodes = self.loadShowNodesTmp
        }
    }
}

private func < (lhs: Int?, rhs: Int?) -> Bool {
    switch (lhs, rhs) {
    case (.some, .none), (.none, .none): return false
    case (.none, .some): return true
    case (.some(let a), .some(let b)): return a < b
    }
}

fileprivate extension OrderBy {
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
