//
//  GlobalState.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/6/26.
//  Copyright © 2021 Crazy凡. All rights reserved.
//

import SwiftUI

final class GlobalState: ObservableObject {
    static let shared = GlobalState()

    let settings = AppSettings.shared
    let session = AppSession.shared
    let store = TreeDataStore.shared

    private init() {}
}

extension GlobalState {
    @MainActor var selection: LockBookmark? {
        get { session.selection }
        set { session.selection = newValue }
    }

    @MainActor var isLoading: Bool {
        get { session.isLoading }
        set { session.isLoading = newValue }
    }

    var detailMode: DetailMode {
        get { settings.detailMode }
        set { settings.detailMode = newValue }
    }

    var orderRule: OrderBy {
        get { settings.orderRule }
        set { settings.orderRule = newValue }
    }

    var isBookmarkEnable: Bool {
        get { settings.isBookmarkEnable }
        set { settings.isBookmarkEnable = newValue }
    }

    var isIgnoreLastModificationDate: Bool {
        get { settings.isIgnoreLastModificationDate }
        set { settings.isIgnoreLastModificationDate = newValue }
    }

    var isIgnoreNodeDeep: Bool {
        get { settings.isIgnoreNodeDeep }
        set { settings.isIgnoreNodeDeep = newValue }
    }

    var locationOfCacheFile: LocationOfCacheFile {
        get { settings.locationOfCacheFile }
        set { settings.locationOfCacheFile = newValue }
    }

    var isSubspeciesShow: Bool {
        get { settings.isSubspeciesShow }
        set { settings.isSubspeciesShow = newValue }
    }

    var useNewListStyle: Bool {
        get { settings.useNewListStyle }
        set { settings.useNewListStyle = newValue }
    }

    var repoBookMark: [URL: Data] {
        get { settings.repoBookMark }
        set { settings.repoBookMark = newValue }
    }

    @MainActor func data(for lock: LockBookmark) -> TreeData? { store.data(for: lock) }
}
