//
//  TreeContent.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeContent: View {
    @EnvironmentObject var setting: Setting
    @EnvironmentObject var treeData: TreeData

    var body: some View {
        VStack {
            TreeControl()

            List {
                ForEach(treeData.showNodes) { node in
                    TreeView(node: node, isImpactMode: self.treeData.isImpactMode)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                self.treeData.onSeletd(node: node)
                            }
                    }.contextMenu {
                        Button(action: {
                            Pasteboard.write(node.pod.name)
                        }) {
                            Text("Copy")
                        }

                        Button(action: {
                            self.treeData.content(for: node, with: .single) {
                                 Pasteboard.write($0)
                            }
                        }) {
                            Text("Copy child nodes")
                        }

                        Button(action: {
                            self.treeData.content(for: node, with: .recursive) {
                                 Pasteboard.write($0)
                            }
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
