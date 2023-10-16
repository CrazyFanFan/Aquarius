//
//  DropModifier.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import CoreData
import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct DropModifier: ViewModifier {
    @Environment(\.modelContext) private var swiftDataViewContext

    @Query(sort: \LockBookmark.timestamp, order: .forward)
    private var items: [LockBookmark]

    @StateObject var global: GlobalState
    @State private var isTargeted: Bool = false

    private static let supportType = UTType.fileURL

    func body(content: Self.Content) -> some View {
        content
        .onOpenURL { addItem(with: $0) }
        .onDrop(
            of: global.isLoading ? [] : [Self.supportType],
            isTargeted: $isTargeted
        ) {
            self.loadPath(from: $0)
        }
    }
}

private extension DropModifier {
    func addItem(with url: URL) {
        withAnimation {
            if items.contains(where: { $0.url?.absoluteString == url.absoluteString }) {
                return
            }

            guard let bookmark = BookmarkTool.bookmark(for: url) else {
                // tod, show error.
                return
            }

            let newItem = LockBookmark(
                bookmark: bookmark,
                id: UUID(),
                name: url
                    .absoluteString
                    .components(separatedBy: "/")
                    .suffix(2)
                    .joined(separator: "/"),
                previous: items.last?.id,
                timestamp: Date())

            items.last?.next = newItem.id

            swiftDataViewContext.insert(newItem)
        }
    }
}

private extension DropModifier {
    private func loadPath(from items: [NSItemProvider]) -> Bool {
        guard let item = items.first(where: { $0.canLoadObject(ofClass: URL.self) }) else { return false }
        item.loadItem(forTypeIdentifier: Self.supportType.identifier, options: nil) { (data, error) in
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

struct DropModifier_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .frame(width: 100, height: 100)
            .modifier(DropModifier(global: .shared))
    }
}
