//
//  AquariusApp.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI
import SwiftData

@main
struct AquariusApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext) // TOOD: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
                .modelContainer(for: LockBookmark.self)
                 #if DEBUG
                 .preferredColorScheme(Bool.random() ? .dark : .light) // for debug
                 #endif
        }
        .commands {
            SidebarCommands()

            // 禁用创建新的Window
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}
        }

        Settings {
            AquariusSettings(global: .shared)
        }
    }
}
