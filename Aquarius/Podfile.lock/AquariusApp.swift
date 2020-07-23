//
//  AquariusApp.swift
//  Aquarius
//
//  Created by Crazy凡 on 2020/6/29.
//  Copyright © 2020 Crazy凡. All rights reserved.
//

import SwiftUI

@main
struct AquariusApp: App {
    var body: some Scene {
        WindowGroup {
            LockRootView()
                .environmentObject(TreeData())
                .environmentObject(Setting.shared)
        }
    }
}
