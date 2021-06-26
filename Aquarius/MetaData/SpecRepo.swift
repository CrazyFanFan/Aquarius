//
//  SpecRepo.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

struct SpecRepo {
    var repo: String
    var pods: [String]

    init(repo: String, pods: [String]) {
        self.repo = repo
        self.pods = pods
    }
}
