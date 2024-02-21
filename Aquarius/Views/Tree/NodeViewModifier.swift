//
//  NodeViewModifier.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/24.
//

import SwiftUI

struct NodeViewModifier: ViewModifier {
    @State var treeData: TreeData
    var node: TreeNode

    func body(content: Self.Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                treeData.onSelected(node: node)
            }
            .contextMenu {
                menus(node.pod)
            }
            .frame(maxWidth: .infinity)
    }
}

private extension NodeViewModifier {
    /// Cell 右键菜单
    /// - Parameter pod: 当前点击的 Pod
    /// - Returns: 菜单Items
    @MainActor
    @inline(__always)
    func menus(_ pod: Pod) -> some View {
        typealias MenuItem = (name: String, type: TreeData.NodeContentDeepMode)

        let menus: [MenuItem] = [
            ("Copy", .none),
            ("Copy child nodes", .single),
            ("Copy child nodes (Recursive)", .recursive),
            ("Copy child nodes (Recursive, Strip)", .stripRecursive)
        ]

        return Group {
            ForEach(menus, id: \.name) { item in
                Button(LocalizedStringKey(item.name)) {
                    copy(with: pod, and: item.type)
                }
            }

            Button("Show Podspec") {
                self.treeData.showPodspec(of: pod)
            }
        }
    }

    @MainActor
    func copy(with pod: Pod, and type: TreeData.NodeContentDeepMode) {
        treeData.cancelCurrentCopyTask()
        treeData.startCopyStatus(with: pod, and: type)
    }
}
