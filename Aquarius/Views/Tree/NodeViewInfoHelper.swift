//
//  NodeViewInfoHelper.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/24.
//

import Foundation
import SwiftUI

enum NodeViewInfoHelper {
    private static func highlight(string: String, indices: Set<String.Index>?) -> some View {
        guard let indices, !indices.isEmpty else { return Text(string) }

        var result = Text("")
        var buffer = ""
        buffer.reserveCapacity(string.count)

        var isHighlighted: Bool? = nil
        var appendedAny = false

        for index in string.indices {
            let current = indices.contains(index)
            if let prev = isHighlighted, prev != current {
                if appendedAny {
                    result = result + (prev ? Text(buffer).bold().foregroundColor(.main) : Text(buffer))
                } else {
                    result = prev ? Text(buffer).bold().foregroundColor(.main) : Text(buffer)
                    appendedAny = true
                }
                buffer.removeAll(keepingCapacity: true)
            }

            buffer.append(string[index])
            isHighlighted = current
        }

        if let last = isHighlighted, !buffer.isEmpty {
            if appendedAny {
                result = result + (last ? Text(buffer).bold().foregroundColor(.main) : Text(buffer))
            } else {
                result = last ? Text(buffer).bold().foregroundColor(.main) : Text(buffer)
            }
        }

        return result
    }

     static func more(_ node: TreeNode, isImpactMode: Bool) -> Text {
         let count = node.nextCount(isImpactMode)
         return if count > 0 {
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

    @inline(__always)
    static func name(_ node: (pod: Pod, indices: Set<String.Index>?)) -> some View {
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
