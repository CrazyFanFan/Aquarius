//
//  TreeControl.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/4/24.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeControl: View {
    @AppStorage("isIgnoreNodeDeep") private var isIgnoreNodeDeep: Bool = false
    @StateObject var treeData: TreeData

    var body: some View {
        VStack {
            SearchBar(searchText: $treeData.searchText)

            HStack(alignment: .center) {
                Text("Total: \(treeData.showNodes.filter { $0.deep == 0 }.count)")
                    .foregroundColor(.primary)
                    .font(.headline)

                Divider()

                Picker("Indentation: ", selection: $isIgnoreNodeDeep) {
                    ForEach([true, false], id: \.self) {
                        Text($0 ? "Ignore" : "Automatic").tag($0)
                    }
                }.scaledToFit()

                Divider()

                Picker("Model: ", selection: $treeData.detailMode) {
                    ForEach(DetailMode.allCases) {
                        Text(NSLocalizedString($0.rawValue, comment: "")).tag($0)
                    }
                }
                .scaledToFit()

                Spacer()

                Button("Copy all") {
                    let content = self.treeData.showNodes
                        .map { (0..<$0.deep).map { _ in "\t" }.joined() + $0.pod.name }
                        .joined(separator: "\n")
                    Pasteboard.write(content)
                }
            }.frame(maxHeight: 25)

            Divider()
        }
    }
}

struct TreeControl_Previews: PreviewProvider {
    static var previews: some View {
        TreeControl(treeData: .init())
    }
}
