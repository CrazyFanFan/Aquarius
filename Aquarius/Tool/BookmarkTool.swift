//
//  BookmarkTool.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/12.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

enum BookmarkTool {
    struct ResolvedBookmark {
        let url: URL
        let isStale: Bool
        let refreshedBookmark: Data?
    }

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

    static func resolve(_ bookmark: Data?) -> ResolvedBookmark? {
        guard let bookmark else { return nil }

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

            let refreshedBookmark = isStale ? Self.bookmark(for: url) : nil
            return ResolvedBookmark(url: url, isStale: isStale, refreshedBookmark: refreshedBookmark)

        } catch {
            print("Error resolving bookmark:", error)
            return nil
        }
    }

    static func url(for bookmark: Data?) -> (URL, Bool)? {
        guard let resolved = resolve(bookmark) else { return nil }
        return (resolved.url, resolved.isStale)
    }
}
