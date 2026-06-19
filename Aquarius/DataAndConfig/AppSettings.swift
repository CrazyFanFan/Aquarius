import SwiftUI

enum LocationOfCacheFile: String, CaseIterable {
    case system
    case application
}

extension Dictionary: @retroactive RawRepresentable where Key: Codable, Value: Codable {
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

final class AppSettings: ObservableObject, @unchecked Sendable {
    static let shared = AppSettings()

    @AppStorage("detailMode") var detailMode: DetailMode = .predecessors
    @AppStorage("orderRule") var orderRule: OrderBy = .alphabeticalAscending

    @AppStorage("isBookmarkEnable") var isBookmarkEnable: Bool = false
    @AppStorage("isIgnoreLastModificationDate") var isIgnoreLastModificationDate: Bool = false
    @AppStorage("isIgnoreNodeDeep") var isIgnoreNodeDeep = false
    @AppStorage("locationOfCacheFile") var locationOfCacheFile: LocationOfCacheFile = .application
    @AppStorage("isSubspeciesShow") var isSubspeciesShow: Bool = false

    @AppStorage("newListStyle") var useNewListStyle: Bool = false

    @AppStorage("repoBookMark") var repoBookMark: [URL: Data] = [:]
    @AppStorage("podspecAccessBookmarks") var podspecAccessBookmarks: [URL: Data] = [:]

    private init() {}
}
