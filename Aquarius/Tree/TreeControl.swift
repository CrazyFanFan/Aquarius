//
//  TreeControl.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/4/24.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

struct TreeControlModifier: ViewModifier {
    @StateObject var treeData: TreeData

    func body(content: Self.Content) -> some View {
        content.toolbar {
            if treeData.isCopying {
                copyProgress()
            }

            Text("Total: \(treeData.showNodes.filter { $0.deep == 0 }.count)")
                .foregroundColor(.primary)
                .font(.headline)

            Picker("Sort by:", selection: $treeData.orderRule) {
                ForEach(OrderBy.allCases, id: \.self) { rule in
                    HStack {
                        Image("arrow.up.arrow.down.square.fill")
                        Text(rule.rawValue)
                    }.tag(rule)
                }
            }

            Picker("Model:", selection: $treeData.detailMode) {
                ForEach(DetailMode.allCases) {
                    Text(NSLocalizedString($0.rawValue.capitalized, comment: "")).tag($0)
                }
            }
            .scaledToFit()

            Button("Copy all") {
                let content = self.treeData.showNodes
                    .map { (0..<$0.deep).map { _ in "\t" }.joined() + $0.pod.name }
                    .joined(separator: "\n")
                Pasteboard.write(content)
            }
        }
    }
}

private extension TreeControlModifier {
    func copyProgress() -> some View {
        HStack {
            ProgressView(value: treeData.displayCopyProgress) {
                Text("Copying...")
                    .font(.system(size: 10))
            } currentValueLabel: {
                Text(String(format: "%0.2f%%", treeData.displayCopyProgress * 100))
            }.progressViewStyle(.linear)

            Button {
                treeData.cancelCurrentCopyTask()
            } label: {
                Image("xmark.circle.fill")
            }
        }
    }
}
