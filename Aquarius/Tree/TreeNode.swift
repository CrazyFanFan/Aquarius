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

    func copy(with deep: Int, isImpactMode: Bool) -> TreeNode {
        TreeNode(
            deep: deep,
            pod: pod,
            successors: isImpactMode ? nil : successors?.map { $0.copy(with: deep + 1, isImpactMode: isImpactMode) },
            predecessors: isImpactMode ? predecessors?.map { $0.copy(with: deep + 1, isImpactMode: isImpactMode) } : nil
        )
    }

    func hasMore(_ isImpact: Bool = false) -> Int? {
        isImpact ? pod.predecessors?.count : pod.successors?.count
    }
}

extension TreeNode: Identifiable {
    var id: Int { (hashValue << 1) + (isExpanded ? 0 : 1) }
}
