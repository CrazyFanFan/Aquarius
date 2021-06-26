//
//  AquariusApp.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI

@main
struct AquariusApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
