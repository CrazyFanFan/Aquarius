//
//  TreeContent.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeContent: View {
    @EnvironmentObject var data: DataManager
    @EnvironmentObject var setting: Setting

    var body: some View {
        List {
            Section(header: TreeControl()) {
                ForEach(data.treeData.showNodes) { node in
                    TreeView(node: node, isImpactMode: self.data.treeData.isImpactMode)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                self.data.treeData.onSeletd(node: node)
                            }
                    }.contextMenu {
                        Button(action: {
                            Pasteboard.write(node.pod.name)
                        }) {
                            Text("Copy")
                        }

                        Button(action: {
                            Pasteboard.write(self.data.treeData.content(for: node, with: .single))
                        }) {
                            Text("Copy child nodes")
                        }

                        Button(action: {
                            Pasteboard.write(self.data.treeData.content(for: node, with: .recursive))
                        }) {
                            Text("Copy child nodes (Recursive)")
                        }
                    }
                }
            }
        }.frame(minWidth: 400, alignment: .center)
    }
}

struct TreeContent_Previews: PreviewProvider {
    static var previews: some View {
        TreeContent()
    }
}
