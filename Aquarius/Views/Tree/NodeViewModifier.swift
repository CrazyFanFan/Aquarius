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

    @State private var isReleationShow: Bool = false

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
            .sheet(isPresented: $isReleationShow) {
                RelationView(
                    pod: node.pod,
                    data: .init(
                        start: node.pod,
                        pods: treeData.lock?.pods ?? [],
                        nameToPodCache: treeData.nameToPodCache
                    )
                )
            }
    }
}

private extension NodeViewModifier {
    /// Cell 右键菜单
    /// - Parameter pod: 当前点击的 Pod
    /// - Returns: 菜单Items
    @MainActor
    @inline(__always)
    func menus(_ pod: Pod) -> some View {
        typealias MenuItem = (name: String, type: TreeData.CopyingStrategy)

        let menus: [MenuItem] = [
            ("Copy", TreeData.CopyingStrategy.nameOnly),
            ("Copy child nodes", .children),
            ("Copy child nodes (Recursive)", .recursive),
            ("Copy child nodes (Recursive, Prune)", .pruneRecursive)
        ]

        return Group {
            Text("Copy Operations").font(.headline)

            ForEach(menus, id: \.name) { item in
                Button(LocalizedStringKey(item.name)) {
                    copy(with: pod, and: item.type)
                }
            }

            Divider()
            Text("View Information").font(.headline)
            Button("Show Podspec") {
                self.treeData.showPodspec(of: pod)
            }

            Divider()
            Text("Relation Management").font(.headline)
            Button("Relation") {
                isReleationShow.toggle()
            }
        }
    }

    @MainActor
    func copy(with pod: Pod, and type: TreeData.CopyingStrategy) {
        treeData.cancelCurrentCopyTask()
        treeData.startCopyStatus(with: pod, and: type)
    }
}
