//
//  TreeContent.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/5.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeContent: View {
    @State var global: GlobalState
    @State var treeData: TreeData

    @State private var isFullVersionShow: Bool = false

    var body: some View {
#if DEBUG
        if #available(macOS 14.1, *) {
            AnyView {
                Self._logChanges()
            }
        }
#endif

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
    @MainActor func mainContent() -> some View {
        VStack {
            tips().animation(.easeInOut, value: treeData.copyResult)

            PageMenu(treeData: treeData) // Top operation bar

            Divider()

            if global.useNewListStyle, #available(macOS 13, *) {
                tableContent()
            } else {
                singleColumn()
            }
        }
        .sheet(isPresented: $treeData.isPodspecViewShow) {
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
    @MainActor
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
        .animation(.linear, value: treeData.showNodes)
    }

    /// Single column
    @MainActor func singleColumn() -> some View {
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

#Preview {
    TreeContent(global: .shared, treeData: .init(lockFile: .preview))
}
