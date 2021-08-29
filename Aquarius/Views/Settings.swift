//
//  Settings.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI

struct Settings: View {
    @StateObject var config: GlobalState

    var body: some View {
        Menu {
            Toggle("Bookmark", isOn: $config.isBookmarkEnable)

            Toggle("Ignore Last Modification Date", isOn: $config.isIgnoreLastModificationDate)
            Picker("Indentation: ", selection: $config.isIgnoreNodeDeep) {
                ForEach([true, false], id: \.self) {
                    Text($0 ? "Ignore" : "Automatic").tag($0)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .scaledToFit()
        } label: {
            Label("Settings", image: "c_gearshape")
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings(config: .shared)
    }
}
