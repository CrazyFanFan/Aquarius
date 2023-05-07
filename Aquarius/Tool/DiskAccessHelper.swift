//
//  DiskAccessHelper.swift
//  Aquarius
//
//  Created by Crazy凡 on 2023/5/7.
//

import Foundation
import AppKit

enum DiskAccessHelper {
    static func requireReadAccess(of url: URL) -> URL? {
        let panel = NSOpenPanel()

        // Sets up so user can only select a single directory
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.showsHiddenFiles = false
        panel.title = "Select Cocoapod's Repo Directory"
        panel.prompt = "Select Cocoapod's Repo Directory"
        panel.directoryURL = url

        let response = panel.runModal()
        if response == .OK, let panelURL = panel.url, panelURL.path == url.path {
            return panelURL
        } else {
            return nil
        }
    }
}
