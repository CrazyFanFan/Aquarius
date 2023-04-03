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
                        text($0, ("list.bullet", "Ignore"), ("list.bullet.indent", "Automatic"), $0)
                    }
                }

                Picker("Location of cache file", selection: $global.locationOfCacheFile) { // 缓存路径
                    ForEach(LocationOfCacheFile.allCases, id: \.rawValue) {
                        text($0 == .system, ("gear", $0.rawValue.capitalized), ("app", $0.rawValue.capitalized), $0)
                    }
                }

                if #available(macOS 13, *) {
                    Picker("List view style", selection: $global.useNewListStyle) {
                        ForEach([true, false], id: \.self) {
                            text($0, ("tablecells", "Columns"), ("list.triangle", "Single Column"), $0)
                        }
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

private extension AquariusSettings {

    typealias ItmeInfo = (imageName: String, message: String)

    @inline(__always)
    func text(_ info: ItmeInfo) -> Text {
        // Split for localized
        Text("\(Image(systemName: info.imageName)) ") + Text(LocalizedStringKey(info.message))
    }

    func text<TAG: Hashable>(
        _ condition: Bool,
        _ trueInfo: ItmeInfo,
        _ falseInfo: ItmeInfo,
        _ tag: TAG
    ) -> some View {
        (condition ? text(trueInfo) : text(falseInfo)).tag(tag)
    }
}

struct AquariusSettings_Previews: PreviewProvider {
    static var previews: some View {
        AquariusSettings(global: .shared)
    }
}
