//
//  TreeView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeView: View {
    @EnvironmentObject var setting: Setting

    var node: TreeNode
    var isImpactMode: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(node.pod.name)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)

                Text(node.pod.info?.name ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                more()
                    .foregroundColor(.primary)
                    .opacity(0.4)
            }

            Color.secondary
                .frame(width: nil, height: 1, alignment: .leading)
                .opacity(node.deep == 0 ? 0.7 : 0.2)
        }.padding(
            .leading,
            CGFloat(
                node.deep > 0 ?
                    (setting.isIgnoreNodeDeep ? 30 : node.deep * 30) :
                    0
            )
        )
    }

    private func more() -> Text {
        guard let count = node.hasMore(isImpactMode) else { return Text("") }
        return Text("\(node.isExpanded ? "▲" : "▼")(\(count))")
    }
}

struct TreeView_Previews: PreviewProvider {
    static var previews: some View {
        TreeView(node: TreeNode(deep: 0, pod: Pod(podValue: "test")), isImpactMode: .random())
    }
}
