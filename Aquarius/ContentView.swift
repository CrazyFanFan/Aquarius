//
//  ContentView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @StateObject private var global = GlobalState.shared

    var body: some View {
        ZStack {
            NavigationView {
                Sidebar(global: global)

                if let selection = global.selection, let data = global.data(for: selection) {
                    TreeContent(global: global, treeData: data)
                } else {
                    ContentUnavailableView(
                        "Select a Podfile.lock",
                        image: "paperplane")
                }
            }

            if global.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(x: 1.5, y: 1.5, anchor: .center)
            }
        }
        .modifier(DropModifier(global: global))
    }
}

#Preview {
    ContentView()
    // TOOD: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .modelContainer(for: LockBookmark.self)
#if DEBUG
        .preferredColorScheme(Bool.random() ? .dark : .light) // for debug
#endif
}
