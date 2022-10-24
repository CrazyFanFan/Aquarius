//
//  ContentView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var global = GlobalState.shared

    var body: some View {
        ZStack {
            NavigationView {
                Sidebar(global: global)

                if let selection = global.selection {
                    TreeContent(lock: selection, global: global)
                } else {
                    Text("Select a Podfile.lock")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
