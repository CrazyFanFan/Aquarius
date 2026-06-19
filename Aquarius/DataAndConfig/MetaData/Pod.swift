//
//  Pod.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

extension Pod {
    //    enum Relation: Int, Codable {
    //        case equal
    //        case moreThan
    //        case lessThan
    //    }

    struct Info: Hashable, Codable {
        var version: String
        // var relation: Relation

        var name: String {
            version
        }

        init(version: String) {
            self.version = version
            // self.relation = .equal
        }
    }
}

final class Pod {
    let name: String
    let nameData: Data
    let lowercasedName: String
    let info: Info?
    let successors: [String]
    let predecessors: [String]

    init(name: String, info: Info?, successors: [String] = [], predecessors: [String] = []) {
        self.name = name
        nameData = .init(name.utf8)
        lowercasedName = name.lowercased()
        self.info = info
        self.successors = successors
        self.predecessors = predecessors
    }

    convenience init(podValue: String) {
        let (name, info) = Self.format(podValue: podValue)
        self.init(name: name, info: info)
    }

    convenience init?(map: [String: [String]]) {
        if let podValue = map.keys.first {
            let (name, info) = Self.format(podValue: podValue)
            let successors = map[podValue, default: []].map { Self.format(podValue: $0).name }
            self.init(name: name, info: info, successors: successors)
        } else {
            return nil
        }
    }

}

extension Pod: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(info)
        hasher.combine(name)
        hasher.combine(successors)
        hasher.combine(predecessors)
    }

    static func == (lhs: Pod, rhs: Pod) -> Bool {
        if lhs.info == rhs.info,
        lhs.name == rhs.name,
        lhs.successors == rhs.successors,
        lhs.predecessors == rhs.predecessors {
            return true
        }
        return false
    }
}

private extension Pod {
    static func format(podValue: String) -> (name: String, version: Info?) {
        if let index = podValue.firstIndex(of: " ") {
            let name = String(podValue[..<index])
            let info = Info(version: String(podValue[index...]).trimmingCharacters(in: .whitespaces))
            return (name, info)
        } else {
            return (podValue, nil)
        }
    }
}

extension Pod {
    func nextLevel(_ isImpactMode: Bool) -> [String] {
        isImpactMode ? predecessors : successors
    }
}

extension Pod: @unchecked Sendable {}

// extension Pod {
//    func details(_ isImpactMode: Bool, index: Int) -> [Detail] {
//        let result = [Detail(index: index, content: .pod(self))]
//        if let nextLevel = self.nextLevel(isImpactMode) {
//            return result + nextLevel.map { Detail(index: index, content: .nextLevel($0)) }
//        } else {
//            return result
//        }
//    }
// }
