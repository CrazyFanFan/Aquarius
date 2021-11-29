//
//  ContentView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import SwiftUI
import CoreData

private let supportType: String = kUTTypeFileURL as String

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Lock.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Lock>

    @State private var globalState = GlobalState.shared
    @State private var isTargeted: Bool = false

    @State private var selection: Lock?

    @State private var isPresented: Bool = false

    var body: some View {
        ZStack {
            NavigationView {
                List(selection: $selection) {
                    showItems()
                }
                .listStyle(SidebarListStyle())
                .toolbar {
                    Spacer()
                    Button(action: toggleSidebar, label: { Image("c_sidebar.left") })
                    Settings(config: .shared)
                }
                .frame(minWidth: 250, alignment: .leading)

                Text("Select a Podfile.lock")
            }

            if globalState.isLoading {
                ActivityIndicator()
                    .frame(width: 50, height: 50, alignment: .center)
            }
        }
        .onOpenURL { addItem(with: $0) }
        .onDrop(of: globalState.isLoading ? [] : [supportType], isTargeted: $isTargeted) {
            self.loadPath(from: $0)
        }
        .onAppear {
            if globalState.isBookmarkEnable {
                self.selection = items.first
            } else {
                delete(items: Array(items))
            }

        }
    }
}

private extension ContentView {
    func showItems() -> some View {
        ForEach(items) { item in
            if let name = item.name, let data = data(for: item) {
                NavigationLink {
                    TreeContent(treeData: data)
                } label: {
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

    func data(for item: Lock) -> TreeData? {
        if let data = globalState.cache.object(forKey: item) { return data }

        if let url = item.url {
            return TreeData(lockFile: PodfileLockFile(url: url))
        }

        return nil
    }

    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

private extension ContentView {

    func addItem(with url: URL) {
        withAnimation {
            if items.contains(where: { $0.url?.absoluteString == url.absoluteString }) {
                return
            }

            guard let bookmark = BookmarkTool.bookmark(for: url) else {
                // tod, show error.
                return
            }

            let newItem = Lock(context: viewContext)
            newItem.timestamp = Date()
            newItem.id = UUID()
            newItem.previous = items.last?.id
            newItem.bookmark = bookmark
            newItem.name = url
                .absoluteString
                .components(separatedBy: "/")
                .suffix(2)
                .joined(separator: "/")

            items.last?.next = newItem.id

            do {
                try viewContext.save()
                selection = newItem
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

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

private extension ContentView {
    private func loadPath(from items: [NSItemProvider]) -> Bool {
        guard let item = items.first(where: { $0.canLoadObject(ofClass: URL.self) }) else { return false }
        item.loadItem(forTypeIdentifier: supportType, options: nil) { (data, error) in
            if let _ = error {
                // TODO error
                return
            }

            guard let urlData = data as? Data,
                  let urlString = String(data: urlData, encoding: .utf8),
                  let url = URL(string: urlString),
                  url.lastPathComponent == "Podfile.lock" else {
                      // TODO error
                      return
                  }

            addItem(with: url)
        }
        return true
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
