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
        guard let indices, !indices.isEmpty else { return Text(string) }

        let empty = ""
        var result = Text(empty)

        for index in string.indices {
            let char = Text(String(string[index]))
            result = if indices.contains(index) {
                result + char.bold().foregroundColor(.main)
            } else {
                result + char
            }
        }

        return result
    }

     static func more(_ node: TreeNode, isImpactMode: Bool) -> Text {
         if let count = node.nextCount(isImpactMode) {
             if node.isExpanded {
                 Text("⇇·(\(count)) ").foregroundColor(.close)
             } else {
                 Text("⇉·(\(count)) ").foregroundColor(.main)
             }
         } else {
            Text("=·(0) ").foregroundColor(Color.gray.opacity(0.6))
         }
    }

    @inline(__always)
    static func name(_ node: TreeNode) -> some View {
        highlight(string: node.pod.name, indices: node.indices)
    }

    static func nameAndCount(_ node: TreeNode, isImpactMode: Bool, isIgnoreNodeDeep: Bool) -> some View {
        HStack {
            more(node, isImpactMode: isImpactMode).bold()
            name(node)
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
