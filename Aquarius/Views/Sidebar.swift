//
//  Sidebar.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import SwiftUI
import SwiftData

struct Sidebar: View {
    // TOOD: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.modelContext) private var swiftDataViewContext

    // TOOD: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Lock.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Lock>
    @Query(sort: \LockBookmark.timestamp, order: .forward)
    private var newItems: [LockBookmark]

    @StateObject var global: GlobalState

    @State private var isPresented: Bool = false

    var body: some View {
        List(newItems, id: \.self, selection: $global.selection) {
            view(for: $0)
        }
        .listStyle(SidebarListStyle())
        .toolbar {
            Spacer()
            Button(action: toggleSidebar, label: { Image(systemName: "sidebar.left") })
            Button {
                isPresented.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
            .popover(isPresented: $isPresented) {
                AquariusSettings(global: .shared)
            }
        }
        .frame(minWidth: 250, alignment: .leading)
        .onAppear {
            // TOOD: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
            migrateFromCoreData()
            if global.isBookmarkEnable {
                global.selection = newItems.first
            } else {
                delete(items: Array(newItems))
            }
        }
    }

    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

private extension Sidebar {
    func view(for item: LockBookmark) -> some View {
        NavigationLink {
            if let data = global.data(for: item) {
                TreeContent(global: global, treeData: data)
            } else {
                Text("""
                    Failed to parse Podfile.lock.
                    Check the files for conflicts or other formatting exceptions.
                    """)
            }
        } label: {
            Text(item.name ?? "Unknow")
        }
        .contextMenu {
            Button("Delete") {
                self.delete(items: [item])
                if item == global.selection {
                    global.selection = nil
                }
            }

            Button("Copy path") {
                Pasteboard.write(item.url?.path ?? "")
            }

            if let url = item.url {
                Button("Show in finder") {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
            }
        }
    }
}

private extension Sidebar {
    private func delete(items: [LockBookmark]) {
        withAnimation {
            items.forEach(swiftDataViewContext.delete)
        }
    }

    // TOOD: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
    private func migrateFromCoreData() {
        items.forEach { lock in
            guard let bookmark = lock.bookmark, let id = lock.id, let timestamp = lock.timestamp else { return }
            swiftDataViewContext.insert(LockBookmark(
                bookmark: bookmark,
                id: id,
                name: lock.name,
                next: lock.next,
                previous: lock.previous,
                timestamp: timestamp
            ))

            viewContext.delete(lock)
        }
        try? viewContext.save()
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(global: .shared)
    }
}

#Preview {
    Sidebar(global: .shared)
}
