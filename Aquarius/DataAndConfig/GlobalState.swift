//
//  GlobalState.swift
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

extension Dictionary: RawRepresentable where Key: Codable, Value: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Key: Value].self, from: data) else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
}

// 接下来需要在 TreeData 内置页面内配置，并且优化逻辑；
// 优先访问全局配置，全局配置失效则访问页面内配置

final class GlobalState: ObservableObject {
    static let shared = GlobalState()

    @MainActor @Published var selection: LockBookmark?

    @MainActor @Published var isLoading: Bool = false

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
    @AppStorage("isSubspeciesShow") var isSubspeciesShow: Bool = false

    @AppStorage("newListStyle") var useNewListStyle: Bool = false

    @AppStorage("repoBookMark") var repoBookMark: [URL: Data] = [:]

    public var cache: NSCache<LockBookmark, TreeData> = .init()
    private init() {}
}

extension GlobalState {
    func data(for lock: LockBookmark) -> TreeData? {
        if let data = cache.object(forKey: lock), data.lock != nil {
            return data
        }

        if let url = lock.url {
            let data = TreeData(lockFile: LockFileInfo(url: url))
            cache.setObject(data, forKey: lock)

            return data
        }

        return nil
    }
}
