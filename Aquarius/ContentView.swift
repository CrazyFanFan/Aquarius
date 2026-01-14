//
//  ContentView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @StateObject private var session = AppSession.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var store = TreeDataStore.shared

    var body: some View {
        ZStack {
            NavigationView {
                Sidebar(settings: settings, session: session, store: store)

                if let selection = session.selection, let data = store.data(for: selection) {
                    TreeContent(settings: settings, treeData: data)
                } else {
                    ContentUnavailableView(
                        "Select a Podfile.lock",
                        image: "paperplane"
                    )
                }
            }

            if session.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(x: 1.5, y: 1.5, anchor: .center)
            }
        }
        .modifier(DropModifier(session: session))
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
