//
//  Pasteboard.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import AppKit
import Foundation

class Pasteboard {
    private static let pasteboard = NSPasteboard.general

    static func write(_ string: String) {
        pasteboard.setString(string, forType: .string)
    }
}
