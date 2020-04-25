//
//  Setting.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/4/25.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import Combine
import SwiftyUserDefaults

enum DetailMode: String, CaseIterable, Identifiable, DefaultsSerializable {
    var id: String { self.rawValue }

    case dependencies
    case influence
}

class Setting: ObservableObject {
    static var shared = Setting()

    @Published var isBookmarkEnable: Bool = Defaults[\.isBookmarkEnable] {
        didSet { Defaults[\.isBookmarkEnable] = isBookmarkEnable }
    }

    @Published var isIgnoreLastModificationDate: Bool = Defaults[\.isIgnoreLastModificationDate] {
        didSet {
            Defaults[\.isIgnoreLastModificationDate] = isIgnoreLastModificationDate
        }
    }

    @Published var isIgnoreNodeDeep: Bool = Defaults[\.isIgnoreNodeDeep] {
        didSet {
            Defaults[\.isIgnoreNodeDeep] = isIgnoreNodeDeep
        }
    }

    private init() {}
}
