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
    @StateObject var globalState: GlobalState

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
            .animation(.default, value: treeData.showNodes)
        }
        .sheet(isPresented: $treeData.isPodspecShow, content: {
            PodspecView(podspec: treeData.podspec)
        })
        .searchable(text: $treeData.searchKey)
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
            ("Copy child nodes (Recursive, Strip)", .stripRecursive)
        ]

        return Group {
            ForEach(menus, id: \.name) { item in
                Button(LocalizedStringKey(item.name)) {
                    copy(with: pod, and: item.type)
                }
            }

            Button("Show podspec") {
                self.treeData.showPodspec(of: pod)
            }
        }
    }

    private func copy(with pod: Pod, and type: TreeData.NodeContentDeepMode) {
        treeData.copyTask?.cancel()

        treeData.copyTask = Task.detached(priority: .medium) {
            DispatchQueue.main.async {
                globalState.isCopying = true
            }
            defer {
                DispatchQueue.main.async {
                    globalState.isCopying = false
                }
            }

            guard let content = await treeData.copy(for: pod, with: type), !Task.isCancelled else {
                return
            }

            Pasteboard.write(content)
        }
    }
}

struct TreeContent_Previews: PreviewProvider {
    static var previews: some View {
        TreeContent(treeData: .init(lockFile: .preview), globalState: .shared)
    }
}
