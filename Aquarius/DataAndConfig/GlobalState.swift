//
//  Config.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/26.
//  Copyright © 2021 Crazy凡. All rights reserved.
//

import Combine
import SwiftUI

enum LocationOfCacheFile: String, CaseIterable {
    case system
    case application
}

class GlobalState: ObservableObject {
    static let shared = GlobalState()

    @Published var isLoading: Bool = false

    @AppStorage("isBookmarkEnable") var isBookmarkEnable: Bool = false
    @AppStorage("isIgnoreLastModificationDate") var isIgnoreLastModificationDate: Bool = false
    @AppStorage("isIgnoreNodeDeep") var isIgnoreNodeDeep = false
    @AppStorage("locationOfCacheFile") var locationOfCacheFile: LocationOfCacheFile = .application

     public var cache: NSCache<Lock, TreeData> = .init()
    private init() {}
}
