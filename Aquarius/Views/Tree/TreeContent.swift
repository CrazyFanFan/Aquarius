//
//  TreeContent.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeContent: View {
    @StateObject var global: GlobalState
    @StateObject var treeData: TreeData

    @State private var isFullVersionShow: Bool = false

    @State private var tableAnimation: Animation?

    var body: some View {
        if global.selection != nil {
            if treeData.isLockLoadFailed {
                Text("""
                Failed to parse Podfile.lock.
                Check the files for conflicts or other formatting exceptions.
                """)
            } else {
                mainContent() // main content
            }
        } else {
            Text("Select a Podfile.lock") // Default info when selection is nil
        }
    }
}

private extension TreeContent {
    func mainContent() -> some View {
        VStack {
            HStack {
                PageControl(treeData: treeData) // Top operation bar
            }
            .padding(5)

            Divider()

            if global.useNewListStyle, #available(macOS 13, *) {
                tableContent()
            } else {
                SingleColumn()
            }
        }
        .sheet(isPresented: $treeData.isPodspecShow) {
            PodspecView(podspec: treeData.podspec)
        }
        .searchable(text: $treeData.searchKey) {
            if !treeData.searchSuggestions.isEmpty {
                ForEach(treeData.searchSuggestions, id: \.self) { node in
                    NodeViewInfoHelper.name(node).searchCompletion(node.pod.name)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 400, alignment: .center)
    }

    /// Columns style
    @available(macOS 13, *)
    func tableContent() -> some View {
        Table(treeData.showNodes) {
            TableColumn("Nodes") { node in
                NodeViewInfoHelper.nameAndCount(
                    node,
                    isImpactMode: treeData.isImpact,
                    isIgnoreNodeDeep: global.isIgnoreNodeDeep
                )
                .modifier(NodeViewModifier(treeData: treeData, node: node))
            }

            TableColumn("Version") { node in
                NodeViewInfoHelper.version(node)
            }
            .width(ideal: 60, max: 220)
        }
        .animation(tableAnimation, value: treeData.showNodes)
        .onAppear { self.tableAnimation = .default }
    }

    /// Single column
    func SingleColumn() -> some View {
        ScrollView {
            // List，用 LazyVGrid 是为了更好的性能
            LazyVGrid(
                columns: [GridItem(.flexible())],
                alignment: .center,
                spacing: nil,
                pinnedViews: []
            ) {
                ForEach(treeData.showNodes) { node in
                    NodeView(global: global, node: node, isImpactMode: self.treeData.isImpact)
                        .modifier(NodeViewModifier(treeData: treeData, node: node))
                }
            }
            .padding(5)
            .animation(.default, value: treeData.showNodes)
        }
    }
}

struct TreeContent_Previews: PreviewProvider {
    static var previews: some View {
        TreeContent(global: .shared, treeData: .init(lockFile: .preview))
    }
}
