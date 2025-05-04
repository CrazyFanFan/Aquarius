//
//  TreeNode.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import Foundation

final class TreeNode: NSObject {
    var pod: Pod
    var successors: [TreeNode]?
    var predecessors: [TreeNode]?

    var deep: Int
    var isExpanded: Bool = false

    var indices: Set<String.Index>?

    init(deep: Int, pod: Pod, successors: [TreeNode]? = nil, predecessors: [TreeNode]? = nil) {
        self.deep = deep
        self.pod = pod
        self.successors = successors
        self.predecessors = predecessors
    }

    func copy(with deep: Int, isImpact: Bool) -> TreeNode {
        TreeNode(
            deep: deep,
            pod: pod,
            successors: isImpact ? nil : successors?.map { $0.copy(with: deep + 1, isImpact: isImpact) },
            predecessors: isImpact ? predecessors?.map { $0.copy(with: deep + 1, isImpact: isImpact) } : nil
        )
    }

    @inline(__always)
    func nextCount(_ isImpact: Bool) -> Int? {
        isImpact ? pod.predecessors?.count : pod.successors?.count
    }

    func hasMore(isImpact: Bool) -> Bool {
        if let count = nextCount(isImpact), count != 0 {
            return true
        }

        return false
    }
}

extension TreeNode: Identifiable {
    var id: Int { (hashValue << 1) + (isExpanded ? 0 : 1) }
}
