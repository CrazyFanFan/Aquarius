//
//  LockBookmark+.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import Foundation

extension LockBookmark {
    func resolvedURL(refreshingStaleBookmark: Bool = false) -> URL? {
        guard let resolved = BookmarkTool.resolve(bookmark) else {
            return nil
        }

        if refreshingStaleBookmark, let refreshedBookmark = resolved.refreshedBookmark {
            bookmark = refreshedBookmark
        }

        return resolved.url
    }

    @discardableResult
    func refreshBookmarkIfNeeded() -> URL? {
        resolvedURL(refreshingStaleBookmark: true)
    }

    var url: URL? {
        resolvedURL()
    }
}
