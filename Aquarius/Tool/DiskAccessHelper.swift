//
//  DiskAccessHelper.swift
//  Aquarius
//
//  Created by Crazy凡 on 2023/5/7.
//

import AppKit
import Foundation

enum DiskAccessHelper {
    @MainActor static func requireReadAccess(
        of url: URL,
        directoryURL: URL? = nil,
        title: String = "Select Cocoapod's Repo Root Directory",
        prompt: String = "Select Cocoapod's Repo Root Directory",
        allowsEnclosingDirectory: Bool = false
    ) -> URL? {
        let panel = NSOpenPanel()

        // Sets up so user can only select a single directory
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = false
        panel.title = title
        panel.prompt = prompt
        panel.directoryURL = directoryURL ?? url
        panel.representedURL = url

        let response = panel.runModal()
        if response == .OK, let panelURL = panel.url,
           panelURL.path == url.path || (allowsEnclosingDirectory && url.isDescendant(of: panelURL)) {
            return panelURL
        } else {
            return nil
        }
    }
}

private extension URL {
    func isDescendant(of directoryURL: URL) -> Bool {
        let pathComponents = standardizedFileURL.pathComponents
        let directoryPathComponents = directoryURL.standardizedFileURL.pathComponents

        guard pathComponents.count >= directoryPathComponents.count else {
            return false
        }

        return zip(pathComponents, directoryPathComponents).allSatisfy(==)
    }
}
