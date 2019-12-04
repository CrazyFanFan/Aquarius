//
//  Pod.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

struct Pod: Hashable, Codable, Identifiable {
    var id: String { self.name }

    enum Relation: Int, Codable {
        case equal
        case moreThan
        case lessThan
    }

    struct Info: Hashable, Codable {
        var version: String
        var relation: Relation

        var name: String {
            version
        }

        init(version: String) {
            self.version = version
            self.relation = .equal
        }
    }

    var name: String
    var info: Info?
    var dependencies: [String]?

    init(podValue: String) {
        (name, info) = Self.format(podValue: podValue)
    }

    init?(map: [String: [String]]) {
        if let podValue = map.keys.first {
            (name, info) = Self.format(podValue: podValue)
            self.dependencies = map[podValue]?.map { Self.format(podValue: $0).name }
        } else {
            return nil
        }
    }
}

private extension Pod {
    static func format(podValue: String) -> (name: String, version: Info?) {
        if let index = podValue.firstIndex(of: " ") {
            let name = String(podValue[..<index])
            let info: Info = Info(version: String(podValue[index...]).trimmingCharacters(in: .whitespaces))
            return (name, info)
        } else {
            return (podValue, nil)
        }
    }
}