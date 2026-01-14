import SwiftUI

@MainActor final class AppSession: ObservableObject {
    static let shared = AppSession()

    @Published var selection: LockBookmark?
    @Published var isLoading: Bool = false

    private init() {}
}

