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
    var dependencies: [TreeNode]?
    var infecteds: [TreeNode]?

    var deep: Int
    var isExpanded: Bool = false

    init(deep: Int, pod: Pod, dependencies: [TreeNode]? = nil, infecteds: [TreeNode]? = nil) {
        self.deep = deep
        self.pod = pod
        self.dependencies = dependencies
        self.infecteds = infecteds
    }

    func copy(with deep: Int, isImpactMode: Bool) -> TreeNode {
        TreeNode(
            deep: deep,
            pod: pod,
            dependencies: isImpactMode ? nil : dependencies?.map { $0.copy(with: deep + 1, isImpactMode: isImpactMode) },
            infecteds: isImpactMode ? infecteds?.map { $0.copy(with: deep + 1, isImpactMode: isImpactMode) } : nil
        )
    }

    func hasMore(_ isImpact: Bool = false) -> Int? {
        isImpact ? pod.infecteds?.count : pod.dependencies?.count
    }
}

extension TreeNode: Identifiable {
    var id: Int { (hashValue << 1) + (isExpanded ? 0 : 1) }
}
