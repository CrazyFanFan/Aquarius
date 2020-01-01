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
                .font(.title)
            Spacer()

            Group {
                Toggle(isOn: self.$data.isRecursive) { Text("Recursive") }
                Spacer()
                Toggle(isOn: self.$data.isImpactMode) { Text("Impact") }
                    .toggleStyle(SwitchToggleStyle())
            }.font(.system(size: 10))

            Spacer()

            Button("Copy all") {
                let content = self.data.detail
                    .map { $0.map { $0.content.name }.joined(separator: "\n") }
                    .joined(separator: "\n")
                Pasteboard.write(content)
            }.font(.system(size: 10))
        }
    }
}

struct DetailsControl_Previews: PreviewProvider {
    static var previews: some View {
        DetailsControl()
    }
}
