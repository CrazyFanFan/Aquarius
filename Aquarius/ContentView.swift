//
//  ContentView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @ObservedObject private var session = AppSession.shared
    @ObservedObject private var settings = AppSettings.shared
    private let store = TreeDataStore.shared
    @State private var selectedData: TreeData?

    var body: some View {
        ZStack {
            NavigationSplitView {
                Sidebar(settings: settings, session: session)
            } detail: {
                if let data = selectedData {
                    TreeContent(settings: settings, treeData: data)
                } else {
                    ContentUnavailableView(
                        "Select a Podfile.lock",
                        systemImage: "paperplane"
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
        .task(id: session.selection?.persistentModelID) {
            guard let selection = session.selection else {
                selectedData = nil
                return
            }
            selection.refreshBookmarkIfNeeded()
            selectedData = store.data(for: selection)
        }
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
