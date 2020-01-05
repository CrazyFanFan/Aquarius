//
//  Keys.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/1/6.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
    var isRecursive: DefaultsKey<Bool> {
        .init("isRecursive", defaultValue: false)
    }

    var detailMode: DefaultsKey<DetailMode> {
        .init("detailMode", defaultValue: .dependencies)
    }

    var bookmark: DefaultsKey<Data> {
        .init("bookmark", defaultValue: Data())
    }

    var isBookmarkEnable: DefaultsKey<Bool> {
        .init("isBookmarkEnable", defaultValue: true)
    }

    var isIgnoreLastModificationDate: DefaultsKey<Bool> {
        .init("isIgnoreLastModificationDate", defaultValue: false)
    }

    var isIgnoreNodeDeep: DefaultsKey<Bool> {
        .init("isIgnoreNodeDeep", defaultValue: false)
    }
}
