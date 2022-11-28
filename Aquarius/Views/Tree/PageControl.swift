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
        Text("Total: \(treeData.showNodes.filter { $0.deep == 0 }.count)")
            .foregroundColor(.primary)
            .font(.headline)

        Spacer()

        if treeData.isCopying {
            copyProgress()
        }

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
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(RoundedRectangle(cornerRadius: 5))
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(lineWidth: 1)
                .opacity(0.5)
        }
    }
}

struct PageControl_Previews: PreviewProvider {
    static var previews: some View {
        PageControl(treeData: .init(lockFile: .init(url: Bundle.main.url(forResource: "Podfile", withExtension: "lock")!)))
    }
}
