//
//  TreeView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let yOffset = rect.size.height / 2
        path.move(to: CGPoint(x: 0, y: yOffset))
        path.addLine(to: CGPoint(x: rect.width, y: yOffset))
        return path
    }
}

struct TreeView: View {
    @AppStorage("isIgnoreNodeDeep") private var isIgnoreNodeDeep = false

    var node: TreeNode
    var isImpactMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                more()?.bold()

                Text(node.pod.name).foregroundColor(.primary)
                Spacer()
                Text((node.pod.info?.name ?? ""))
                    .padding(EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5))
                    .foregroundColor(.secondary)
            }

            Line()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 7]))
                .frame(height: 1, alignment: .trailing)
                .foregroundColor(.secondary)
        }
        .font(.system(size: 14))
        .padding(
            .leading,
            CGFloat(node.deep > 0 ? (isIgnoreNodeDeep ? 30 : node.deep * 30) : 0)
        )
    }

    private func more() -> Text? {
        guard let count = node.hasMore(isImpactMode) else {
            return Text("=·(0) ").foregroundColor(Color.gray.opacity(0.6))
        }

        if node.isExpanded {
            return Text("⇇·(\(count)) ").foregroundColor(Color.red.opacity(0.6))
        } else {
            return Text("⇉·(\(count)) ").foregroundColor(Color.green.opacity(0.6))
        }
    }
}

struct TreeView_Previews: PreviewProvider {
    static var previews: some View {
        TreeView(node: TreeNode(deep: 0, pod: Pod(podValue: "test")), isImpactMode: .random())
    }
}
