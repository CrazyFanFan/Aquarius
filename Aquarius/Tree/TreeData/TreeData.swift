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
    // is on processing
    private var podToNodeCache: [Pod: TreeNode] = [:]
    private var nameToNodeCache: [String: TreeNode] = [:]
    private var nodes: [TreeNode] = []

    private var loadShowNodesTmp: [TreeNode] = []
    @Published private(set) var showNodes: [TreeNode] = []

    private(set) var nameToPodCache: [String: Pod] = [:]

    @AppStorage("isIgnoreLastModificationDate") private var isIgnoreLastModificationDate: Bool = false
    @AppStorage("bookmark") var bookmark: Data?

    /// for copy
    @Published var copyProgress: Double = 0
    var copyTask: Task<Void, Error>?

    @Published var copyResult: (content: String, isWriteToFile: Bool)?

    var lockFile: PodfileLockFile? {
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

    private(set) var podfileLock: PodfileLock? {
        didSet { buildTree() }
    }

    var searchKey = "" {
        didSet {
            let value = searchKey.trimmingCharacters(in: .whitespacesAndNewlines)

            if searchKey != value {
                searchKey = value
            }

            loadData(isImpact: isImpact, resetIsExpanded: true)
        }
    }

    /// Mark is impact mode
    ///
    ///
    /// When a module depends on another module and the dependent module
    /// changes, the module that depends on that module will be affected.
    /// I call it the impact mode.
    ///
    /// 标记”影响树“
    ///
    /// 如果一个模块A依赖另一模块B，被依赖的模块B发生变化时候，则模块A可能会受到影响，
    /// 递归的找下去，会形成一棵树，我称之为”影响树“
    ///
    @AppStorage("detailMode") var detailMode: DetailMode = .predecessors {
        didSet {
            if detailMode != oldValue {
                loadData(isImpact: isImpact, resetIsExpanded: true)
            }
        }
    }

    @AppStorage("orderRule") var orderRule: OrderBy = .alphabeticalAscending {
        didSet {
            if orderRule != oldValue {
                loadData(isImpact: isImpact, resetIsExpanded: false)
            }
        }
    }

    var isImpact: Bool { detailMode == .predecessors }

    private(set) var queue = DispatchQueue(label: "aquarius_data_parse_queue")

    // for show podspec
    var podspec: PodspecInfo?
    @Published var isPodspecShow: Bool = false

    var podspecCache: [Pod: PodspecInfo] = [:]

    init(lockFile: PodfileLockFile) {
        self.lockFile = lockFile
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
    func checkShouldReloadData(oldLockFile: PodfileLockFile?, _ completion: ((_ isNeedReloadData: Bool) -> Void)?) {
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
                if let lock = DataReader(file: info).readData() {
                    DispatchQueue.main.async {
                        // update lock data
                        self.podfileLock = lock
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
        queue.async {
            // top level
            self.podfileLock?.pods.forEach { (pod) in
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

            if let pod = self.podfileLock?.pods.first(where: { $0.name == dependence }),
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
