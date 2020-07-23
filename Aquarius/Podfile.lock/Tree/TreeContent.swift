//
//  TreeContent.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeContent: View {
    @EnvironmentObject var treeData: TreeData

    var body: some View {
        VStack {
            TreeControl().padding([.top, .trailing])
            List {
                ForEach(treeData.showNodes) { node in
                    TreeView(node: node, isImpactMode: self.treeData.isImpactMode)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                self.treeData.onSeletd(node: node)
                            }
                        }.contextMenu {
                            Button("Copy") { Pasteboard.write(node.pod.name) }

                            Button("Copy child nodes") {
                                self.treeData.content(for: node, with: .single) {
                                    Pasteboard.write($0)
                                }
                            }

                            Button("Copy child nodes (Recursive)") {
                                self.treeData.content(for: node, with: .recursive) {
                                    Pasteboard.write($0)
                                }
                            }
                        }
                }
            }
        }.frame(minWidth: 450, alignment: .center)
    }
}

struct TreeContent_Previews: PreviewProvider {
    static var previews: some View {
        TreeContent()
    }
}
