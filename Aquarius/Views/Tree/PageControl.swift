//
//  PageControl.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import SwiftUI

struct PageControl: View {
    @StateObject var treeData: TreeData
    @State private var isShow: Bool = false

    var body: some View {
        if treeData.isCopying {
            copyProgress()
        }

        Text("Total: \(treeData.showNodes.filter { $0.deep == 0 }.count)")
            .foregroundColor(.primary)
            .font(.headline)

        Spacer()

        /*
        Button {
            isShow.toggle()
        } label: {
            Image(systemName: "gearshape.2")
        }
        .popover(isPresented: $isShow) {
            Form {
                PageCommonSettings(
                    orderRule: $treeData.orderRule,
                    detailMode: $treeData.detailMode,
                    isSubspeciesShow: $treeData.isSubspeciesShow
                )
            }
            .padding(5)
        }*/
        PageCommonSettings(
            orderRule: $treeData.orderRule,
            detailMode: $treeData.detailMode,
            isSubspeciesShow: $treeData.isSubspeciesShow
        )
        .fixedSize()

        Button("Copy all") {
            let content = self.treeData.showNodes
                .map { (0..<$0.deep).map { _ in "\t" }.joined() + $0.pod.name }
                .joined(separator: "\n")
            Pasteboard.write(content)
        }
    }
}

private extension PageControl {
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

struct PageControl_Previews: PreviewProvider {
    static var previews: some View {
        PageControl(treeData: .init(lockFile: .init(url: Bundle.main.url(forResource: "Podfile", withExtension: "lock")!)))
    }
}
