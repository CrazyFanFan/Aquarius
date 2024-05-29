//
//  PageMenu.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import SwiftUI

struct PageMenu: View {
    @State var treeData: TreeData
    @State private var isShow: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text("Total: \(treeData.showNodes.filter { $0.deep == 0 }.count)")
                    .foregroundColor(.primary)
                    .font(.headline)

                Spacer()

                PageCommonSettings(
                    orderRule: $treeData.orderRule,
                    detailMode: $treeData.detailMode,
                    isSubspeciesShow: $treeData.isSubspeciesShow
                )
                .fixedSize()

                Button("Copy all") {
                    let content = treeData.showNodes
                        .map { (0 ..< $0.deep).map { _ in "\t" }.joined() + $0.pod.name }
                        .joined(separator: "\n")
                    Pasteboard.write(content)
                }
            }

            if treeData.isCopying, treeData.copyMode == .recursive {
                copyProgress()
            }
        }.padding(5)
    }
}

private extension PageMenu {
    @MainActor func copyProgress() -> some View {
        HStack {
            Text("Copying...")
            Divider().frame(maxHeight: 20)
            ProgressView(value: treeData.displayCopyProgress).progressViewStyle(.linear)
            Text(String(format: "%0.2f%%", treeData.displayCopyProgress * 100))

            Divider().frame(maxHeight: 20)

            Button {
                treeData.cancelCurrentCopyTask()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding([.leading, .trailing], 3.5)
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
        }
    }
}

#Preview {
    PageMenu(treeData: .init(lockFile: .init(url: Bundle.main.url(forResource: "Podfile", withExtension: "lock")!)))
}
