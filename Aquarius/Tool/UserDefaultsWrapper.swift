//
//  UserDefaultsWrapper.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/6.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
import Foundation

enum UserDefaultKey: String {
    case isRecursive
    case isImpactMode
    case bookmark
    case isBookmarkEnable
    case isIgnoreLastModificationDate
}

@propertyWrapper
struct UserDefault<ValueType> {
    let key: UserDefaultKey
    let defaultValue: ValueType

    init(_ key: UserDefaultKey, defaultValue: ValueType) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: ValueType {
        get {
            return UserDefaults.standard.object(forKey: key.rawValue) as? ValueType ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key.rawValue)
        }
    }
}
