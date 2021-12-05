//
//  TreeData+Copy.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/12/4.
//

import Foundation

// MARK: - Data Copy
extension TreeData {
    enum NodeContentDeepMode: Hashable {
        case none
        case single
        case recursive
        case stripRecursive
    }

    struct CacheKey: Hashable {
        var name: String
        var mode: NodeContentDeepMode
        var impact: Bool
    }

    func content(for node: Pod, with deepMode: NodeContentDeepMode, completion: ((String) -> Void)?) {
        guard let completion = completion else { return }

        let checkMode: (_ isRecursiveHandler: () -> Void) -> Void = { handler in
            switch deepMode {
            case .recursive: handler()
            default: break
            }
        }

        checkMode { GlobalState.shared.isLoading = true }

        queue.async {
            var cache: [CacheKey: String] = [:]

            completion(self.innerContent(for: node, with: deepMode, cache: &cache))
            cache.removeAll()

            DispatchQueue.main.async {
                checkMode { GlobalState.shared.isLoading = false }
            }
        }
    }

    private func innerContent(
        for node: Pod,
        with deepMode: NodeContentDeepMode,
        cache: inout [CacheKey: String]
    ) -> String {
        let key = CacheKey(name: node.name, mode: deepMode, impact: isImpact)
        if let result = cache[key] { return result }

        func formatNames(_ input: inout [String]) -> String {
            if input.isEmpty { return "" }

            if input.count == 1 {
                return ("\n└── " + input.joined())
            } else {
                let last = input.removeLast()
                return ("\n├── " + input.joined(separator: "\n├── ") + "\n└── " + last)
            }
        }

        switch deepMode {
        case .none:
            return node.name
        case .single:
            var result: String = node.name
            if var next = node.nextLevel(isImpact) {
                result += formatNames(&next)
            }
            return result

        case .recursive:
            var result = node.name

            if let nodes = node.nextLevel(isImpact)?.compactMap({ nameToPodCache[$0] }) {
                if nodes.count == 1 {
                    result = result + "\n└── " +
                    innerContent(for: nodes.first!, with: deepMode, cache: &cache)
                        .split(separator: "\n")
                        .joined(separator: "\n    ")
                } else {
                    var nexts = nodes.map { self.innerContent(for: $0, with: .recursive, cache: &cache) }
                    let last = nexts.removeLast()

                    let next = nexts
                        .map { ("├── " + $0).split(separator: "\n").joined(separator: "\n│   ") }
                        .joined(separator: "\n")
                    + "\n"
                    + ("└── " + last).split(separator: "\n").joined(separator: "\n    ")

                    result = result + "\n" + next
                }
            }
            cache[key] = result
            return result

        case .stripRecursive:
            var subnames = node.nextLevel(isImpact) ?? []
            var index = 0

            while index < subnames.count {
                subnames += nameToPodCache[subnames[index]]?
                    .nextLevel(isImpact)?
                    .filter({ !subnames.contains($0) }) ?? []
                index += 1
            }

            return node.name + formatNames(&subnames)
        }
    }
}
