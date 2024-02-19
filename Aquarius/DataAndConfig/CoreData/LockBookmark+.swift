//
//  LockBookmark+.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import Foundation

extension LockBookmark {
    var url: URL? {
        guard let (url, _) = BookmarkTool.url(for: bookmark) else {
            return nil
        }

        return url
    }
}
