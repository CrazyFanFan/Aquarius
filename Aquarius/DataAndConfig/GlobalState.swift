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

// 接下来需要在 TreeData 内置页面内配置，并且优化逻辑；
// 优先访问全局配置，全局配置失效则访问页面内配置

class GlobalState: ObservableObject {
    static let shared = GlobalState()

    @Published var isLoading: Bool = false

    /// Mark is impact mode
    ///
    ///
    /// When a module depends on another module and the dependent module
    /// changes, the module that depends on that module will be affected.
    /// I call it the impact mode.
    ///
    /// 标记”影响树“
    ///
    /// 如果一个模块A依赖另一模块B，被依赖的模块B发生变化时候，则模块A可能会受到影响，
    /// 递归的找下去，会形成一棵树，我称之为”影响树“
    ///
    @AppStorage("detailMode") var detailMode: DetailMode = .predecessors
    @AppStorage("orderRule") var orderRule: OrderBy = .alphabeticalAscending

    @AppStorage("isBookmarkEnable") var isBookmarkEnable: Bool = false
    @AppStorage("isIgnoreLastModificationDate") var isIgnoreLastModificationDate: Bool = false
    @AppStorage("isIgnoreNodeDeep") var isIgnoreNodeDeep = false
    @AppStorage("locationOfCacheFile") var locationOfCacheFile: LocationOfCacheFile = .application
    @AppStorage("isSubspecShow") var isSubspecShow: Bool = false

    public var cache: NSCache<Lock, TreeData> = .init()
    private init() {}
}
