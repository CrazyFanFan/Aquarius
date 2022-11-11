//
//  BookmarkTool.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/12.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

class BookmarkTool {
    private static var cache: [Data: (URL, Bool)] = [:]

    static func bookmark(for url: URL) -> Data? {
        do {
            return try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("Failed to save bookmark data for \(url)", error)
            return nil
        }
    }

    static func url(for bookmark: Data?) -> (URL, Bool)? {
        guard let bookmark = bookmark else { return nil }
        if let result = cache[bookmark] { return result }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // bookmarks could become stale as the OS changes
                print("Bookmark is stale, need to save a new one... ")
            }

            let result = (url, isStale)
            cache[bookmark] = result

            return result

        } catch {
            print("Error resolving bookmark:", error)
            return nil
        }
    }
}
