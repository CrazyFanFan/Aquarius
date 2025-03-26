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
    var name: String
    lazy var nameData: Data = .init(name.utf8)
    var lowercasedName: String
    var info: Info?
    var successors: [String]?
    var predecessors: [String]?

    init(podValue: String) {
        (name, info) = Self.format(podValue: podValue)
        lowercasedName = name.lowercased()
    }

    init?(map: [String: [String]]) {
        if let podValue = map.keys.first {
            (name, info) = Self.format(podValue: podValue)
            successors = map[podValue]?.map { Self.format(podValue: $0).name }
        } else {
            return nil
        }
        lowercasedName = name.lowercased()
    }

    func copy() -> Pod {
        let new = Pod(podValue: name)

        new.info = info
        new.successors = successors
        new.predecessors = predecessors

        return new
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
    func nextLevel(_ isImpactMode: Bool) -> [String]? {
        isImpactMode ? predecessors : successors
    }
}

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
