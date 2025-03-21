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
            if treeData.isCopying, treeData.copyMode == .recursive {
                copyProgress()
            }

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

                Button("Copy All") {
                    let content = treeData.showNodes
                        .map { (0 ..< $0.deep).map { _ in "\t" }.joined() + $0.pod.name }
                        .joined(separator: "\n")
                    Pasteboard.write(content)
                }

            }.padding(5)
        }
    }
}

private extension PageMenu {
    @MainActor func copyProgress() -> some View {
        HStack {
            Text("Copying...")

            Spacer()

            Text("\(treeData.currentCopyingCount)")
                .frame(width: CGFloat("\(treeData.currentCopyingCount)".count * 12))

            ProgressView().controlSize(.mini)

            Divider().frame(maxHeight: 20)

            Button {
                withAnimation {
                    treeData.cancelCurrentCopyTask()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding(5)
        .background(Color.secondary.opacity(0.2))
    }
}

#Preview {
    PageMenu(treeData: .init(lockFile: .init(url: Bundle.main.url(forResource: "Podfile", withExtension: "lock")!)))
}
