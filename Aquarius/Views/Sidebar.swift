//
//  Sidebar.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import SwiftUI

struct Sidebar: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Lock.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Lock>

    @StateObject var globalState: GlobalState
    @Binding var selection: Lock?

    @State private var isPresented: Bool = false

    var body: some View {
        List(selection: $selection) {
            showItems()
        }
        .listStyle(SidebarListStyle())
        .toolbar {
            Spacer()
            Button(action: toggleSidebar, label: { Image("c_sidebar.left") })
            Button {
                isPresented.toggle()
            } label: {
                Image("c_gearshape")
            }
            .popover(isPresented: $isPresented) {
                AquariusSettings(config: .shared)
            }
        }
        .frame(minWidth: 250, alignment: .leading)
        .onAppear {
            if globalState.isBookmarkEnable {
                self.selection = items.first
            } else {
                delete(items: Array(items))
            }
        }
    }

    func data(for lock: Lock) -> TreeData? {
        if let data = globalState.cache.object(forKey: lock) {
            return data
        }

        if let url = lock.url {
            let data = TreeData(lockFile: PodfileLockFile(url: url))
            globalState.cache.setObject(data, forKey: lock)

            return data
        }

        return nil
    }

    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

private extension Sidebar {
    func showItems() -> some View {
        ForEach(items) { item in
            if let name = item.name, let data = data(for: item) {
                NavigationLink(destination: TreeContent(treeData: data)) {
                    Text(name)
                }
                .tag(item)
                .contextMenu {
                    Button("Delete") {
                        self.delete(items: [item])
                        if item == self.selection {
                            self.selection = nil
                        }
                    }
                    Button("Copy path") {
                        Pasteboard.write(item.url?.path ?? "")
                    }
                }
            }
        }
    }
}

private extension Sidebar {
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func delete(items: [Lock]) {
        withAnimation {
            items.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(globalState: .shared, selection: .constant(nil))
    }
}
