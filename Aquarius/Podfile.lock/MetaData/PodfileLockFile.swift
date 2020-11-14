//
//  LockFileInfo.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/12.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

struct PodfileLockFile: Hashable {
    var isFromBookMark: Bool
    var url: URL
}
