//
//  TreeData.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

struct TreeData {
    private var podToNodeCache: [Pod: TreeNode] = [:]
    private var dependenceToNodeCache: [String: TreeNode] = [:]
    private var nodes: [TreeNode] = []

    private var __showNodes: [TreeNode] = []
    private(set) var showNodes: [TreeNode] = []

    var lock: Lock? {
        didSet { buildTree() }
    }

    var searchText = "" {
        didSet {
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
    var detailMode: DetailMode = Defaults[\.detailMode] {
        didSet {
            Defaults[\.detailMode] = detailMode
            self.isImpactMode = detailMode == .influence
        }
    }

    var isImpactMode: Bool = Defaults[\.detailMode] == .influence {
        didSet {
            loadData(isImpactMode: isImpactMode, resetIsExpanded: true)
        }
    }

    init() {}

    mutating func onSeletd(node: TreeNode) {
        node.isExpanded = !node.isExpanded

        getNextLevel(node: node, isImpactMode: isImpactMode)
        loadData(isImpactMode: isImpactMode)
    }
}

private extension TreeData {
    mutating func buildTree() {
        nodes.removeAll()

        // top level
        lock?.pods.forEach { (pod) in
            let node = TreeNode(deep: 0, pod: pod)
            podToNodeCache[pod] = node
            nodes.append(node)
        }
        loadData(isImpactMode: isImpactMode)
    }

    func namesToNodes(deep: Int, names: [String]?) -> [TreeNode]? {
        names?.compactMap { (dependence) -> TreeNode? in
            if let node = dependenceToNodeCache[dependence]?.copy(with: deep, isImpactMode: isImpactMode) {
                return node
            }

            if let pod = self.lock?.pods.first(where: { $0.name == dependence }),
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

    mutating func loadData(isImpactMode: Bool, resetIsExpanded: Bool = false) {
        __showNodes.removeAll()

        if resetIsExpanded {
            nodes.forEach { $0.isExpanded = false }
        }

        traverse(nodes, isImpactMode: isImpactMode)
    }

    private mutating func traverse(_ nodes: [TreeNode], isImpactMode: Bool) {
        for node in nodes {
            if self.searchText.isEmpty ||
                node.deep > 0 ||
                node.pod.name.lowercased().contains(self.searchText.lowercased()) {
                __showNodes.append(node)

                if node.isExpanded, let subNodes = isImpactMode ? node.infecteds : node.dependencies {
                    traverse(subNodes, isImpactMode: isImpactMode)
                }
            }
        }

        showNodes = __showNodes
    }
}

extension TreeData {
    enum NodeContentDeepMode {
        case none
        case single
        case recursive
    }

    func content(for node: TreeNode, with deepMode: NodeContentDeepMode) -> String {
        switch deepMode {
        case .none:
            return node.pod.name
        case .single:
            if var next = node.pod.nextLevel(isImpactMode) {
                if next.count == 1 {
                    return node.pod.name + "\n└── " + next.joined()
                } else {
                    let last = next.removeLast()
                    return node.pod.name + "\n├── " + next.joined(separator: "\n├── ") + "\n└── " + last
                }
            }
            return node.pod.name

        case .recursive:
            var temp = node.pod.name
            if let nodes = namesToNodes(deep: node.deep + 1, names: node.pod.nextLevel(isImpactMode)) {
                if nodes.count == 1 {
                    temp = temp + "\n└── " +
                        content(for: nodes.first!, with: deepMode)
                        .split(separator: "\n")
                        .joined(separator: "\n    ")
                } else {
                    var nexts = nodes.map { self.content(for: $0, with: .recursive) }
                    let last = nexts.removeLast()

                    let next = nexts
                        .map { ("├── " + $0).split(separator: "\n").joined(separator: "\n│   ") }
                        .joined(separator: "\n")
                        + "\n"
                        + ("└── " + last).split(separator: "\n").joined(separator: "\n    ")

                    temp = temp + "\n" + next
                }
            }
            return temp
        }
    }
}
