import Foundation

@MainActor final class TreeDataStore: ObservableObject {
    static let shared = TreeDataStore()

    private let cache: NSCache<LockBookmark, TreeData> = .init()

    private init() {}

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

