//
//  ContentView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var globalState = GlobalState.shared
    @State private var selection: Lock?

    var body: some View {
        ZStack {
            NavigationView {
                Sidebar(globalState: globalState, selection: $selection)

                Text("Select a Podfile.lock")
            }

            if globalState.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(x: 1.5, y: 1.5, anchor: .center)
            }
        }
        .modifier(DropModifier(globalState: globalState, selection: $selection))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
