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

struct DropViewInnerView: View {
    @AppStorage("isBookmarkEnable") private var isBookmarkEnable: Bool = false
    @AppStorage("isIgnoreLastModificationDate") private var isIgnoreLastModificationDate: Bool = false

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Toggle("Bookmark", isOn: $isBookmarkEnable)
                    Toggle("Ignore Last Modification Date", isOn: $isIgnoreLastModificationDate)
                }
                .font(.system(size: 10))
                Spacer()
            }.padding()

            Spacer()

            Text("Drag the Podfile.lock here!")
                .frame(minWidth: 250, maxWidth: 250, maxHeight: .infinity)
        }
    }
}

struct DropView: View {
    @StateObject var data: TreeData
    @AppStorage("isBookmarkEnable") private var isBookmarkEnable: Bool = false

    @State private var isTargeted: Bool = false

    var body: some View {
        ZStack {
            DropViewInnerView()
                .onDrop(of: data.isLoading ? [] : [supportType], isTargeted: $isTargeted) {
                    self.loadPath(from: $0)
                }
                .onAppear {
                    // check bookmark
                    guard isBookmarkEnable, let (url, isStale) = BookmarkTool.url(for: data.bookmark) else {
                        return
                    }

                    data.lockFile = PodfileLockFile(isFromBookMark: true, url: url)

                    // Bookmark is stale, need to save a new one...
                    if isStale, let bookmark = BookmarkTool.bookmark(for: url) {
                        self.data.bookmark = bookmark
                    }
                }

            // Show cover view.
            if isTargeted {
                Color.green.opacity(0.03)
            }
        }
        .frame(minWidth: 250, maxWidth: 250, maxHeight: .infinity)

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
                DispatchQueue.main.async {
                    self.data.bookmark = bookmark
                }
            }

            self.data.lockFile = PodfileLockFile(isFromBookMark: false, url: url)
        }
        return true
    }
}

struct DropView_Previews: PreviewProvider {
    static var previews: some View {
        DropView(data: .init())
    }
}
