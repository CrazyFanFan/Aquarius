//
//  TreeView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeView: View {
    @AppStorage("isIgnoreNodeDeep") private var isIgnoreNodeDeep = false

    var node: TreeNode
    var isImpactMode: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                more()?.bold()

                Text(node.pod.name).foregroundColor(.primary)

                Spacer()

                Text((node.pod.info?.name ?? ""))
                    .padding(EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5))
                    .foregroundColor(.secondary)
                    .background(Color.green.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 3.5))
            }

            Color.secondary
                .frame(width: nil, height: 1, alignment: .leading)
        }
        .font(.system(size: 14))
        .padding(
            .leading,
            CGFloat(node.deep > 0 ? (isIgnoreNodeDeep ? 30 : node.deep * 30) : 0)
        ).animation(.none)
    }

    private func more() -> Text? {
        guard let count = node.hasMore(isImpactMode) else { return nil }

        if node.isExpanded {
            return Text("⇇·(\(count)) ").foregroundColor(Color.red.opacity(0.7))
        } else {
            return Text("⇉·(\(count)) ").foregroundColor(Color.green.opacity(0.7))
        }
    }
}

struct TreeView_Previews: PreviewProvider {
    static var previews: some View {
        TreeView(node: TreeNode(deep: 0, pod: Pod(podValue: "test")), isImpactMode: .random())
    }
}
