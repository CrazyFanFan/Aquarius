//
//  NodeView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct NodeView: View {
    @StateObject var global: GlobalState

    var node: TreeNode
    var isImpactMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                NodeViewInfoHelper.nameAndCount(
                    node,
                    isImpactMode: isImpactMode,
                    isIgnoreNodeDeep: global.isIgnoreNodeDeep
                )
                NodeViewInfoHelper.version(node)
            }

            Divider()
        }
        .font(.system(size: 14))
    }
}

struct SingleDataTreeView_Previews: PreviewProvider {
    static var previews: some View {
        NodeView(global: .shared, node: TreeNode(deep: 0, pod: Pod(podValue: "test")), isImpactMode: .random())
    }
}
