//
//  DropView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
import SwiftUI

private let supportType: String = kUTTypeFileURL as String

struct DropView: View {
    @EnvironmentObject var data: DataAndSettings
    @State private var isTargeted: Bool = false

    var body: some View {
        VStack {
            Text("Drag the Podfile.lock here!")
                .frame(minWidth: 250, maxWidth: 250, maxHeight: .infinity)
                .onDrop(of: data.isLoading ? [] : [supportType], isTargeted: $isTargeted) {
                    self.loadPath(from: $0)
            }
        }.onAppear {
            // check bookmark
            if let (url, isStale) = BookmarkTool.url(for: self.data.bookmark) {
                self.data.lockFile = LockFile(isFromBookMark: true, url: url)

                // Bookmark is stale, need to save a new one...
                if isStale, let bookmark = BookmarkTool.bookmark(for: url) {
                    self.data.bookmark = bookmark
                }
            }
        }
    }

    private func loadPath(from items: [NSItemProvider]) -> Bool {
        guard let item = items.first(where: { $0.canLoadObject(ofClass: URL.self) }) else { return false }
        item.loadItem(forTypeIdentifier: supportType, options: nil) { (data, error) in
            if let _ = error {
                // TODO error
                return
            }

            guard let urlData = data as? Data,
                let urlString = String(data: urlData, encoding: .utf8),
                let url = URL(string: urlString) else {
                    // TODO error
                    return
            }

            guard url.lastPathComponent == "Podfile.lock" else {
                // TODO error
                return
            }

            if let bookmark = BookmarkTool.bookmark(for: url) {
                self.data.bookmark = bookmark
            }

            self.data.lockFile = LockFile(isFromBookMark: false, url: url)
        }
        return true
    }
}

struct DropView_Previews: PreviewProvider {
    static var previews: some View {
        DropView()
    }
}
