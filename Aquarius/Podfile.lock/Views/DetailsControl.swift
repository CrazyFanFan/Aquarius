//
//  DetailsControl.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/6.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

struct DetailsControl: View {
    @EnvironmentObject var data: DataAndSettings

    var body: some View {
        HStack {
            Text("Total: \(data.detail.reduce(into: 0, { $0 += $1.count }))")
                .foregroundColor(.primary)
                .font(.headline)

            Spacer()

            Toggle(isOn: self.$data.isRecursive) { Text("Recursive") }

            Spacer()

            Picker("", selection: self.$data.detailMode) {
                ForEach(DetailMode.allCases) {
                    Text(NSLocalizedString($0.rawValue, comment: ""))
                        .tag($0)
                }
            }.labelsHidden()
                .scaledToFit()

            Spacer()

            Button("Copy all") {
                let content = self.data.detail
                    .map { $0.map { $0.content.name }.joined(separator: "\n") }
                    .joined(separator: "\n")
                Pasteboard.write(content)
            }
        }
    }
}

struct DetailsControl_Previews: PreviewProvider {
    static var previews: some View {
        DetailsControl()
    }
}
