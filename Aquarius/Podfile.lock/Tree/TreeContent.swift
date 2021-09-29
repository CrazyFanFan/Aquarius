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
        List {
            // 顶部控制View
            Section(header: TreeControl(treeData: treeData)) {
                ForEach(treeData.showNodes) { node in
                    TreeView(node: node, isImpactMode: self.treeData.isImpactMode)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.treeData.onSeletd(node: node)
                        }
                        .contextMenu {
                            self.menus(node.pod)
                        }
                }
            }
        }
        .animation(.easeIn)
        .padding(.top)
        .frame(minWidth: 550, alignment: .center)
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

        return ForEach(menus, id: \.0) { item in
            Button(NSLocalizedString(item.name, comment: item.name)) {
                self.treeData.content(for: pod, with: item.type) {
                    Pasteboard.write($0)
                }
            }
        }
    }
}

struct TreeContent_Previews: PreviewProvider {
    static var previews: some View {
        TreeContent(treeData: .init())
    }
}
