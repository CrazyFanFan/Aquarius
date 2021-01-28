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
    @Published var isLoading: Bool = false

    private var podToNodeCache: [Pod: TreeNode] = [:]
    private var dependenceToNodeCache: [String: TreeNode] = [:]
    private var nodes: [TreeNode] = []

    private var innerShowNodes: [TreeNode] = []
    @Published private(set) var showNodes: [TreeNode] = []

    private var copyFormatedStringCache: [CacheKey: String] = [:]
    private var nameToPodCache: [String: Pod] = [:]

    @AppStorage("isIgnoreLastModificationDate") private var isIgnoreLastModificationDate: Bool = false
    @AppStorage("bookmark") var bookmark: Data?

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

    var podfileLock: PodfileLock? {
        didSet { buildTree() }
    }

    var searchText = "" {
        didSet {
            let value = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            if searchText != value {
                searchText = value
            }

            loadData(isImpactMode: isImpactMode, resetIsExpanded: true)
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
    @AppStorage("detailMode") var detailMode: DetailMode = .influence {
        didSet {
            if detailMode != oldValue {
                buildTree()
            }
        }
    }

    var isImpactMode: Bool { detailMode == .influence }

    private var queue = DispatchQueue(label: "aquarius_data_parse_quque")

    init() {}

    func onSeletd(node: TreeNode) {
        node.isExpanded = !node.isExpanded

        getNextLevel(node: node, isImpactMode: isImpactMode)
        loadData(isImpactMode: isImpactMode)
    }
}

// MARK: - Load File
private extension TreeData {
    func checkShouldReloadData(oldLockFile: PodfileLockFile?, _ completion: ((_ isNeedReloadData: Bool) -> Void)?) {
        guard let completion = completion else { return }

        // If is form bookmark or the old and new path do not match, the data must be reloaded.
        if lockFile?.isFromBookMark == true || self.lockFile != oldLockFile {
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
            self.isLoading = true
            self.queue.async {
                self.lastReadDataTime = Date()
                if let lock = DataReader(file: info).readData() {
                    DispatchQueue.main.async {
                        // update lock data
                        self.podfileLock = lock

                        // update status
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
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
        queue.async {
            // top level
            self.podfileLock?.pods.forEach { (pod) in
                self.nameToPodCache[pod.name] = pod
                let node = TreeNode(deep: 0, pod: pod)
                self.podToNodeCache[pod] = node
                self.nodes.append(node)
            }
            self.loadData(isImpactMode: self.isImpactMode)
        }
    }

    func namesToNodes(deep: Int, names: [String]?) -> [TreeNode]? {
        names?.compactMap { (dependence) -> TreeNode? in
            if let node = dependenceToNodeCache[dependence]?.copy(with: deep, isImpactMode: isImpactMode) {
                return node
            }

            if let pod = self.podfileLock?.pods.first(where: { $0.name == dependence }),
               let node = podToNodeCache[pod]?.copy(with: deep, isImpactMode: isImpactMode) {
                return node
            }

            assert(false, "find dependency without node")
            return nil
        }
    }

    func getNextLevel(nodes: [TreeNode], isImpactMode: Bool) {
        nodes.forEach { getNextLevel(node: $0, isImpactMode: isImpactMode) }
    }

    func getNextLevel(node: TreeNode, isImpactMode: Bool) {
        if !isImpactMode {
            node.dependencies = namesToNodes(deep: node.deep + 1, names: node.pod.dependencies)
        } else {
            node.infecteds = namesToNodes(deep: node.deep + 1, names: node.pod.infecteds)
        }
    }

    func loadData(isImpactMode: Bool, resetIsExpanded: Bool = false) {
        innerShowNodes.removeAll()

        if resetIsExpanded {
            nodes.forEach { $0.isExpanded = false }
        }

        traverse(nodes, isImpactMode: isImpactMode)
    }

    private func traverse(_ nodes: [TreeNode], isImpactMode: Bool) {
        for node in nodes {
            if self.searchText.isEmpty ||
                node.deep > 0 ||
                node.pod.name.lowercased().contains(self.searchText.lowercased()) {
                innerShowNodes.append(node)

                if node.isExpanded, let subNodes = isImpactMode ? node.infecteds : node.dependencies {
                    traverse(subNodes, isImpactMode: isImpactMode)
                }
            }
        }

        DispatchQueue.main.async {
            self.showNodes = self.innerShowNodes
        }
    }
}

// MARK: - Data Copy
extension TreeData {
    enum NodeContentDeepMode: Hashable {
        case none
        case single
        case recursive
        case stripRecursive
    }

    struct CacheKey: Hashable {
        var name: String
        var mode: NodeContentDeepMode
        var impact: Bool
    }

    func content(for node: Pod, with deepMode: NodeContentDeepMode, completion: ((String) -> Void)?) {
        guard let completion = completion else { return }

        let checkMode: (_ isRecursiveHandler: () -> Void) -> Void = { handler in
            switch deepMode {
            case .recursive: handler()
            default: break
            }
        }

        checkMode { self.isLoading = true }

        queue.async {
            self.copyFormatedStringCache.removeAll()
            completion(self.innerContent(for: node, with: deepMode))
            self.copyFormatedStringCache.removeAll()

            DispatchQueue.main.async {
                checkMode { self.isLoading = false }
            }
        }
    }

    private func innerContent(for node: Pod, with deepMode: NodeContentDeepMode) -> String {
        let key = CacheKey(name: node.name, mode: deepMode, impact: isImpactMode)
        if let result = copyFormatedStringCache[key] { return result }

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
            return node.name
        case .single:
            var result: String = node.name
            if var next = node.nextLevel(isImpactMode) {
                result += formatNames(&next)
            }
            return result

        case .recursive:
            var result = node.name

            if let nodes = node.nextLevel(isImpactMode)?.compactMap({ nameToPodCache[$0] }) {
                if nodes.count == 1 {
                    result = result + "\n└── " +
                        innerContent(for: nodes.first!, with: deepMode)
                        .split(separator: "\n")
                        .joined(separator: "\n    ")
                } else {
                    var nexts = nodes.map { self.innerContent(for: $0, with: .recursive) }
                    let last = nexts.removeLast()

                    let next = nexts
                        .map { ("├── " + $0).split(separator: "\n").joined(separator: "\n│   ") }
                        .joined(separator: "\n")
                        + "\n"
                        + ("└── " + last).split(separator: "\n").joined(separator: "\n    ")

                    result = result + "\n" + next
                }
            }
            copyFormatedStringCache[key] = result
            return result

        case .stripRecursive:
            var subnames = node.nextLevel(isImpactMode) ?? []
            var index = 0

            while index < subnames.count {
                subnames += nameToPodCache[subnames[index]]?
                    .nextLevel(isImpactMode)?
                    .filter({ !subnames.contains($0) }) ?? []
                index += 1
            }

            return node.name + formatNames(&subnames)
        }
    }
}
