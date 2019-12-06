//
//  Control.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/6.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

struct Control: View {
    @EnvironmentObject var data: UserData

    var body: some View {
        HStack {
            Button("Copy all") {
                let content = self.data.lock.pods
                    .map { $0.name }
                    .joined(separator: "\n")
                Pasteboard.write(content)
                }.font(.system(size: 10))

            Toggle(isOn: self.$data.isRecursive) { Text("Recursive") }
                .font(.system(size: 10))
                .toggleStyle(SwitchToggleStyle())

            Toggle(isOn: self.$data.isImpactMode) { Text("Impact") }
                .font(.system(size: 10))
                .toggleStyle(SwitchToggleStyle())
        }.padding()
    }
}

struct Control_Previews: PreviewProvider {
    static var previews: some View {
        Control()
    }
}
