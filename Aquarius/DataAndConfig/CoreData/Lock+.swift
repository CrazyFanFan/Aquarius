//
//  Lock+.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/27.
//

import Foundation

extension Lock {
    var url: URL? {
        guard let (url, isStale) = BookmarkTool.url(for: bookmark), !isStale else {
            return nil
        }

        return url
    }
}
