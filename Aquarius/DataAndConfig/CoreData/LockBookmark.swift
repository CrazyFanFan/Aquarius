//
//  LockBookmark.swift
//  Aquarius
//
//  Created by Crazy凡 on 2023/10/16.
//
//

import Foundation
import SwiftData

/// Lock for SwiftData
@Model class LockBookmark {
    var bookmark: Data
    var id: UUID
    var name: String?
    var next: UUID?
    var previous: UUID?
    var timestamp: Date

    init(
        bookmark: Data,
        id: UUID = UUID(),
        name: String? = nil,
        next: UUID? = nil,
        previous: UUID? = nil,
        timestamp: Date = .now
    ) {
        self.bookmark = bookmark
        self.id = id
        self.name = name
        self.next = next
        self.previous = previous
        self.timestamp = timestamp
    }
}
