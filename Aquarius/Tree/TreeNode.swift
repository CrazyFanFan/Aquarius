//
//  TreeNode.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import Foundation

class TreeNode: NSObject {
    var pod: Pod
    var successors: [TreeNode]?
    var predecessors: [TreeNode]?

    var deep: Int
    var isExpanded: Bool = false

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

    func nextCount(_ isImpact: Bool = false) -> Int? {
        isImpact ? pod.predecessors?.count : pod.successors?.count
    }
}

extension TreeNode: Identifiable {
    var id: Int { (hashValue << 1) + (isExpanded ? 0 : 1) }
}
