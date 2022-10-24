//
//  AquariusSettings.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI

struct AquariusSettings: View {
    @StateObject var global: GlobalState

    var body: some View {
        Form {
            Section {
                Toggle("Bookmark", isOn: $global.isBookmarkEnable) // 书签
                Toggle("Ignore Last Modified time", isOn: $global.isIgnoreLastModificationDate) // 忽略最后修改时间

                Picker("Indentation", selection: $global.isIgnoreNodeDeep) { // 缩进
                    ForEach([true, false], id: \.self) {
                        Text($0 ? "Ignore" : "Automatic").tag($0)
                    }
                }

                Picker("Location of cache file", selection: $global.locationOfCacheFile) { // 缓存路径
                    ForEach(LocationOfCacheFile.allCases, id: \.rawValue) {
                        Text(LocalizedStringKey($0.rawValue.capitalized)).tag($0)
                    }
                }
            } header: {
                Text("Global Settings")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Divider()

            Section {
                PageCommonSettings(
                    orderRule: $global.orderRule,
                    detailMode: $global.detailMode,
                    isSubspeciesShow: $global.isIgnoreNodeDeep
                )
            } header: {
                Text("Default Settings")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } footer: {
                Text("""
                    This is the default setting that will be followed
                    when a new file is opened.
                    The Settings on the details page will override the
                    global Settings, but killing the app will lose this.
                    """
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            Divider()

            Button("Clean the cache") {
                Utils.clear()
            }
        }
        .padding()
        .navigationTitle("Preferences")
        .fixedSize()
    }
}

struct AquariusSettings_Previews: PreviewProvider {
    static var previews: some View {
        AquariusSettings(global: .shared)
    }
}
