//
//  LockFileInfo.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/12.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

struct LockFileInfo: Hashable {
    static let preview: LockFileInfo = .init(
        url: Bundle.main.url(forResource: "Podfile", withExtension: "lock")!)

    var url: URL
}
