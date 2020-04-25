//
//  TreeControl.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/4/24.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeControl: View {
    @EnvironmentObject private var setting: Setting
    @EnvironmentObject var data: DataManager

    var body: some View {
        VStack {
            SearchBar(searchText: $data.treeData.searchText)

            HStack {
                Text("Total: \(data.treeData.showNodes.filter { $0.deep == 0 }.count)")
                    .foregroundColor(.primary)
                    .font(.headline)

                Spacer()

                Toggle(isOn: $setting.isIgnoreNodeDeep) {
                    Text("Ignore subnode deep")
                }

                Spacer()

                Picker("", selection: $data.treeData.detailMode) {
                    ForEach(DetailMode.allCases) {
                        Text(NSLocalizedString($0.rawValue, comment: ""))
                            .tag($0)
                    }
                }
                .labelsHidden()
                .scaledToFit()

                Spacer()

                Button("Copy all") {
                    let content = self.data.treeData.showNodes
                        .map { (0..<$0.deep).map { _ in "\t" }.joined() + $0.pod.name }
                        .joined(separator: "\n")
                    Pasteboard.write(content)
                }
            }
        }
    }
}

struct TreeControl_Previews: PreviewProvider {
    static var previews: some View {
        TreeControl()
    }
}
