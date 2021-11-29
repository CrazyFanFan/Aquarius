//
//  Constants.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/6.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import Foundation

enum DetailMode: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case successors
    case predecessors
}

enum OrderBy: String, CaseIterable {
    case alphabeticalAscending = "A → Z"
    case alphabeticalDescending = "Z → A"
    case numberAscending = "0 → 9"
    case numberDescending = "9 → 0"
}
