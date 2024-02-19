//
//  Details.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

enum DetailContent {
    case pod(Pod)
    case nextLevel(String)
}

extension DetailContent {
    var name: String {
        switch self {
        case let .pod(pod):
            pod.name
        case let .nextLevel(name):
            name
        }
    }
}

struct Detail: Identifiable {
    var id: String { content.name + "\(index)" }

    var index: Int
    var content: DetailContent
}
