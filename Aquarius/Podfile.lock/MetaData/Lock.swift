//
//  PodfileLock.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation

enum LockRootKey: String {
    case pods = "PODS"
    case dependencies = "DEPENDENCIES"
    case specRepos = "SPEC REPOS"
    case externalSources = "EXTERNAL SOURCES"
    case checkoutOptions = "CHECKOUT OPTIONS"
    case specChecksums = "SPEC CHECKSUMS"
    case cocoapods = "COCOAPODS"
}

struct Lock {
    var pods: [Pod] = []
    var dependencies: [Pod] = []
    var specRepos: [SpecRepo] = []
    var externalSources: [String: [String: String]] = [:]
    var checkoutOptions: [String: [String: String]] = [:]
    var specChecksums: [String: String] = [:]
    var cocoapods: String = ""
}
