//
//  NodeViewInfoHelper.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/24.
//

import Foundation
import SwiftUI

enum NodeViewInfoHelper {
    private static func highlight(string: String, indices: [String.Index]?) -> some View {
        guard let indices = indices, !indices.isEmpty else { return Text(string) }

        var result = Text("")

        for index in string.indices {
            let char = Text(String(string[index]))
            if indices.contains(index) {
                result = result + char.bold().foregroundColor(.main)
            } else {
                result = result + char
            }
        }

        return result
    }

     static func more(_ node: TreeNode, isImpactMode: Bool) -> Text {
        guard let count = node.nextCount(isImpactMode) else {
            return Text("=·(0) ").foregroundColor(Color.gray.opacity(0.6))
        }

        if node.isExpanded {
            return Text("⇇·(\(count)) ").foregroundColor(.close)
        } else {
            return Text("⇉·(\(count)) ").foregroundColor(.main)
        }
    }

    static func nameAndCount(_ node: TreeNode, isImpactMode: Bool, isIgnoreNodeDeep: Bool) -> some View {
        HStack {
            more(node, isImpactMode: isImpactMode).bold()
            highlight(string: node.pod.name, indices: node.indices)
            Spacer()
        }
        .padding(.leading, CGFloat(node.deep > 0 ? (isIgnoreNodeDeep ? 30 : node.deep * 30) : 0))
    }

    static func version(_ node: TreeNode) -> some View {
        Text((node.pod.info?.name ?? ""))
            .padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 5))
            .foregroundColor(.secondary)
    }
}
