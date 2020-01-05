//
//  DataManager.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
import Foundation
import SwiftyUserDefaults

class DataManager: ObservableObject {
    @Published var treeData: TreeData

    // is on processing
    @Published var isLoading: Bool = false

    private var setting = Setting.shared

    var bookmark: Data = Defaults[\.bookmark] {
        didSet { Defaults[\.bookmark] = bookmark }
    }

    var lockFile: LockFile? {
        didSet {
            if setting.isIgnoreLastModificationDate {
                self.loadData()
            } else {
                checkShouldReloadData(oldLockFile: oldValue) { isNeedReloadData in
                    if isNeedReloadData {
                        self.loadData()
                    }
                }
            }
        }
    }

    private var lastReadDataTime: Date?

    init() {
        self.treeData = TreeData()
    }
}

extension DataManager {
    private func checkShouldReloadData(oldLockFile: LockFile?, _ completion: ((_ isNeedReloadData: Bool) -> Void)?) {
        guard let completion = completion else { return }

        // If is form bookmark or the old and new path do not match, the data must be reloaded.
        if lockFile?.isFromBookMark == true || self.lockFile != oldLockFile {
            completion(true)
            return
        }

        // The data needs to be reloaded. if new path is nil or empty.
        guard let file = lockFile, !file.url.path.isEmpty else {
            completion(false)
            return
        }

        // If read attributes fails, the data needs to be reloaded.
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.url.path),
            let fileModificationDate = attributes[.modificationDate] as? Date,
            let lastReadDataTime = self.lastReadDataTime else {
                completion(true)
                return
        }

        if fileModificationDate.distance(to: lastReadDataTime) < 0 {
            completion(true)
        } else {
            completion(false)
        }
    }

    private func loadData() {
        DispatchQueue.main.async {
            guard let info = self.lockFile else { return }
            self.isLoading = true
            DispatchQueue.global().async {
                self.lastReadDataTime = Date()
                if let lock = DataReader(file: info).readData() {
                    DispatchQueue.main.async {
                        // update lock data
                        self.treeData.lock = lock

                        // update status
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
