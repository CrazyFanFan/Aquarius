//
//  Sidebar.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import SwiftData
import SwiftUI

struct Sidebar: View {
    // TODO: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.modelContext) private var swiftDataViewContext

    // TODO: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Lock.timestamp, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<Lock>
    @Query(sort: \LockBookmark.timestamp, order: .forward)
    private var newItems: [LockBookmark]

    @ObservedObject var settings: AppSettings
    @ObservedObject var session: AppSession

    @State private var isPresented: Bool = false
    @State private var didRunInitialUpdate = false

    var body: some View {
        List(newItems, id: \.self, selection: $session.selection) {
            view(for: $0)
        }
        .listStyle(SidebarListStyle())
        .toolbar {
            Button {
                isPresented.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
            .popover(isPresented: $isPresented) {
                AquariusSettings(settings: settings)
            }
        }
        .frame(minWidth: 250, alignment: .leading)
        .onAppear {
            guard !didRunInitialUpdate else { return }
            didRunInitialUpdate = true
            Task { @MainActor in
                await Task.yield()
                // TODO: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
                migrateFromCoreData()
                if settings.isBookmarkEnable {
                    session.selection = session.selection ?? newItems.first
                } else {
                    delete(items: Array(newItems))
                }
            }
        }
    }
}

private extension Sidebar {
    func view(for item: LockBookmark) -> some View {
        NavigationLink(value: item) {
            Text(item.name ?? "Unknown")
        }
        .contextMenu {
            Button("Delete") {
                self.delete(items: [item])
                if item == session.selection {
                    session.selection = nil
                }
            }

            Button("Copy Path") {
                Pasteboard.write(item.url?.path ?? "")
            }

            if let url = item.url {
                Button("Show in Finder") {
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
            try? swiftDataViewContext.save()
        }
    }

    // TODO: CoreData 迁移到 SwiftData 的代码，未来某一天应该删除
    private func migrateFromCoreData() {
        let existingIDs = Set(newItems.map(\.id))
        var migratedLocks: [Lock] = []

        for lock in items {
            guard let bookmark = lock.bookmark, let id = lock.id, let timestamp = lock.timestamp else { continue }
            migratedLocks.append(lock)

            guard !existingIDs.contains(id) else { continue }
            swiftDataViewContext.insert(LockBookmark(
                bookmark: bookmark,
                id: id,
                name: lock.name,
                next: lock.next,
                previous: lock.previous,
                timestamp: timestamp
            ))
        }

        guard !migratedLocks.isEmpty else { return }

        do {
            try swiftDataViewContext.save()
            migratedLocks.forEach(viewContext.delete)
            try viewContext.save()
        } catch {
            swiftDataViewContext.rollback()
            viewContext.rollback()
        }
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar(settings: .shared, session: .shared)
    }
}

#Preview {
    Sidebar(settings: .shared, session: .shared)
}
