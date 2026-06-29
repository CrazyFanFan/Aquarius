//
//  AquariusSettings.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI

struct AquariusSettings: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Bookmark", isOn: $settings.isBookmarkEnable) // 书签
                Toggle("Ignore Modification Date", isOn: $settings.isIgnoreLastModificationDate) // 忽略修改时间

                Picker("Indentation", selection: $settings.isIgnoreNodeDeep) { // 缩进
                    ForEach([true, false], id: \.self) {
                        text($0, ("list.bullet", "Ignore"), ("list.bullet.indent", "Automatic"), $0)
                    }
                }

                Picker("Cache Location", selection: $settings.locationOfCacheFile) { // 缓存位置
                    ForEach(LocationOfCacheFile.allCases, id: \.rawValue) {
                        text($0 == .system, ("gear", $0.rawValue.capitalized), ("app", $0.rawValue.capitalized), $0)
                    }
                }

                if #available(macOS 13, *) {
                    Picker("List view style", selection: $settings.useNewListStyle) {
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
                    orderRule: $settings.orderRule,
                    detailMode: $settings.detailMode,
                    isSubspeciesShow: $settings.isSubspeciesShow
                )
            } header: {
                Text("Default Settings")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } footer: {
                Text("""
                    These are the defaults used when you open a new file.
                    Changes made on the details page won't modify the global settings.
                    Detail-page changes reset when you quit the app.
                    """
                )
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            Divider()

            Button("Clear Cache") {
                Utils.clear()
            }

            Button("Open Cache Folder") {
                Utils.openTheCacheDirectory()
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

    func text(
        _ condition: Bool,
        _ trueInfo: ItmeInfo,
        _ falseInfo: ItmeInfo,
        _ tag: some Hashable
    ) -> some View {
        (condition ? text(trueInfo) : text(falseInfo)).tag(tag)
    }
}

#Preview {
    AquariusSettings(settings: .shared)
}
