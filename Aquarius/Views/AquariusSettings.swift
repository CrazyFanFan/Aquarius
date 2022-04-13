//
//  AquariusSettings.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI

struct AquariusSettings: View {
    @StateObject var config: GlobalState

    var body: some View {
        Form {
            Group{
                Toggle("Bookmark", isOn: $config.isBookmarkEnable)
                Toggle("Ignore Last Modified time", isOn: $config.isIgnoreLastModificationDate)
            }
            .toggleStyle(.switch)

            Picker("Indentation", selection: $config.isIgnoreNodeDeep) {
                ForEach([true, false], id: \.self) {
                    Text($0 ? "Ignore" : "Automatic").tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .scaledToFill()
        .navigationTitle("Settings")
        .frame(width: 350)
    }
}

struct AquariusSettings_Previews: PreviewProvider {
    static var previews: some View {
        AquariusSettings(config: .shared)
    }
}
