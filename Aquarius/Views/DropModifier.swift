//
//  DropModifier.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DropModifier: ViewModifier {
    @Environment(\.modelContext) private var swiftDataViewContext

    @Query(sort: \LockBookmark.timestamp, order: .forward)
    private var items: [LockBookmark]

    @ObservedObject var session: AppSession
    @State private var isTargeted: Bool = false
    @State private var errorMessage: String?

    private static let supportType = UTType.fileURL

    func body(content: Self.Content) -> some View {
        content
        .onOpenURL { addItem(with: $0) }
        .onDrop(
            of: session.isLoading ? [] : [Self.supportType],
            isTargeted: $isTargeted
        ) {
            loadPath(from: $0)
        }
        .alert("Unable to Open File", isPresented: errorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

private extension DropModifier {
    var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    func addItem(with url: URL) {
        guard url.lastPathComponent == "Podfile.lock" else {
            errorMessage = "Please open a Podfile.lock file."
            return
        }

        withAnimation {
            if let existingItem = items.first(where: { $0.url?.absoluteString == url.absoluteString }) {
                session.selection = existingItem
                return
            }

            guard let bookmark = BookmarkTool.bookmark(for: url) else {
                errorMessage = "Aquarius could not get permission to access this file."
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
                timestamp: Date()
            )

            items.last?.next = newItem.id

            swiftDataViewContext.insert(newItem)
            session.selection = newItem
        }
    }
}

private extension DropModifier {
    private func loadPath(from items: [NSItemProvider]) -> Bool {
        guard let item = items.first(where: { $0.canLoadObject(ofClass: URL.self) }) else {
            errorMessage = "The dropped item is not a file URL."
            return false
        }

        item.loadItem(forTypeIdentifier: Self.supportType.identifier, options: nil) { data, error in
            if let error {
                Task { @MainActor in
                    errorMessage = error.localizedDescription
                }
                return
            }

            guard let urlData = data as? Data,
                  let urlString = String(data: urlData, encoding: .utf8),
                  let url = URL(string: urlString),
                  url.lastPathComponent == "Podfile.lock" else {
                      Task { @MainActor in
                          errorMessage = "Please drop a Podfile.lock file."
                      }
                      return
                  }

            Task { @MainActor in
                addItem(with: url)
            }
        }
        return true
    }
}

struct DropModifier_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .frame(width: 100, height: 100)
            .modifier(DropModifier(session: .shared))
    }
}

#Preview {
    EmptyView()
        .frame(width: 100, height: 100)
        .background(Color.red.opacity(0.1))
        .modifier(DropModifier(session: .shared))
}
