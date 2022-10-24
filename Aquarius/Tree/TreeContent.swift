//
//  TreeContent.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeContent: View {
    @StateObject var lock: Lock
    @StateObject var global: GlobalState
    @StateObject private var treeData: TreeData

    init?(lock: Lock, global: GlobalState) {
        guard let data = global.data(for: lock) else {
            return nil
        }

        _lock = StateObject(wrappedValue: lock)
        _global = StateObject(wrappedValue: global)
        _treeData = StateObject(wrappedValue: data)
    }

    var body: some View {
        // List，用 LazyVGrid 是为了更好的性能
        if global.selection != nil {
            mainContent()
        } else {
            Text("Select a Podfile.lock")
        }
    }
}

private extension TreeContent {
    func mainContent() -> some View {
        VStack {
            HStack {
                PageControl(treeData: treeData)
            }
            .padding(5)

            Divider()

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
        }
        .sheet(isPresented: $treeData.isPodspecShow, content: {
            PodspecView(podspec: treeData.podspec)
        })
        .searchable(text: $treeData.searchKey)
        .frame(minWidth: 1000, minHeight: 400, alignment: .center)
    }

    /// 创建Cell
    /// - Returns: Cell
    @inline(__always)
    func makeItem() -> some View {
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

    func copy(with pod: Pod, and type: TreeData.NodeContentDeepMode) {
        treeData.cancelCurrentCopyTask()
        treeData.startCopyStatus(with: pod, and: type)
    }
}

struct TreeContent_Previews: PreviewProvider {
    static var previews: some View {
        TreeContent(lock: .init(), global: .shared)
    }
}
