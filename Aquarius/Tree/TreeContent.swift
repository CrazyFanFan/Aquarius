//
//  TreeContent.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeContent: View {
    @StateObject var treeData: TreeData

    var body: some View {
        // List，用 LazyVGrid 是为了更好的性能
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible())],
                alignment: .center,
                spacing: nil,
                pinnedViews: []
            ) {
                makeItem()
            }
            .padding(5)
            .animation(.linear)
        }
        .sheet(isPresented: $treeData.isPodspecShow, content: {
            PodspecView(podspec: treeData.podspec)
        })
        .frame(minWidth: 1000, minHeight: 400, alignment: .center)
        .modifier(TreeControlModifier(treeData: treeData))
    }

    /// 创建Cell
    /// - Returns: Cell
    @inline(__always)
    private func makeItem() -> some View {
        ForEach(treeData.showNodes) { node in
            SingleDataTreeView(node: node, isImpactMode: self.treeData.isImpact)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.treeData.onSelected(node: node)
                }
                .contextMenu {
                    self.menus(node.pod)
                }
                .frame(maxWidth: .infinity)
        }
    }

    /// Cell 右键菜单
    /// - Parameter pod: 当前点击的 Pod
    /// - Returns: 菜单Items
    @inline(__always)
    private func menus(_ pod: Pod) -> some View {
        typealias MenuItem = (name: String, type: TreeData.NodeContentDeepMode)

        let menus: [MenuItem] = [
            ("Copy", .none),
            ("Copy child nodes", .single),
            ("Copy child nodes (Recursive)", .recursive),
            ("Copy child nodes (Recursive Strip)", .stripRecursive)
        ]

        return Group {
            ForEach(menus, id: \.name) { item in
                Button(LocalizedStringKey(item.name)) {
                    self.treeData.content(for: pod, with: item.type) {
                        Pasteboard.write($0)
                    }
                }
            }

            Button("Show podspec") {
                self.treeData.showPodspec(of: pod)
            }
        }
    }
}

struct TreeContent_Previews: PreviewProvider {
    static var previews: some View {
        TreeContent(treeData: .init(lockFile: .preview))
    }
}
