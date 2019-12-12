//
//  DataAndSettings.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
import Foundation

class DataAndSettings: ObservableObject {
    @Published var lock: Lock = Lock()
    @Published var detail: [[Detail]] = []

    // is on processing
    @Published var isLoading: Bool = false

    @UserDefault(.isRecursive, defaultValue: false)
    var isRecursive: Bool { didSet { tryUpdate() } }

    /// Mark is impact mode
    ///
    ///
    /// When a module depends on another module and the dependent module
    /// changes, the module that depends on that module will be affected.
    /// I call it the impact mode.
    ///
    /// 标记”影响树“
    ///
    /// 如果一个模块A依赖另一模块B，被依赖的模块B发生变化时候，则模块A可能会受到影响，
    /// 递归的找下去，会形成一棵树，我称之为”影响树“
    ///
    @UserDefault(.isImpactMode, defaultValue: false)
    var isImpactMode: Bool { didSet { tryUpdate() } }

    @UserDefault(.bookmark, defaultValue: Data())
    var bookmark: Data

    var lockFile: LockFile? {
        didSet {
            checkShouldReloadData(oldLockFile: oldValue) { isNeedReloadData in
                if isNeedReloadData {
                    self.loadData()
                }
            }
        }
    }

    private var lastReadDataTime: Date?

    private(set) var seletedPods: [Pod] = []

    func tryUpdate() {
        if let pod = seletedPods.first {
            onSelectd(pod: pod, with: 0, ignoreSameValueCheck: true)
        }
    }

    func onSelectd(pod: Pod, with level: Int, ignoreSameValueCheck: Bool = false) {
        if detail.count > level {
            if !ignoreSameValueCheck, let content = detail[level].first?.content {
                switch content {
                case .pod:
                    if content.name == pod.name { return }
                default:
                    break
                }
            }

            detail.removeSubrange(level...)
        }

        if seletedPods.count > level {
            seletedPods.removeSubrange(level...)
            seletedPods.append(pod)
        } else {
            seletedPods.append(pod)
        }

        if isRecursive {
            detail.append(recursive(for: pod, at: level))
        } else {
            detail.append(pod.details(isImpactMode, index: level))
        }
    }
}

// load next level
extension DataAndSettings {
    private func recursive(for pod: Pod, at index: Int) -> [Detail] {
        var result = [String]()
        recursive(nextLevel: pod.nextLevel(isImpactMode), into: &result)
        return [Detail(index: index, content: .pod(pod))] +
            Array(Set(result)).sorted().map { Detail(index: index, content: .nextLevel($0)) }
    }

    private func recursive(nextLevel: [String]?, into result: inout [String]) {
        guard var nextLevel = nextLevel else { return }
        nextLevel.removeAll(where: { result.contains($0) })
        for dependency in nextLevel {
            if let pod = lock.pods.first(where: { $0.name == dependency }) {
                result.append(dependency)
                recursive(nextLevel: pod.nextLevel(isImpactMode), into: &result)
            }
        }
    }
}

extension DataAndSettings {
    private func checkShouldReloadData(oldLockFile: LockFile?, _ completion: ((_ isNeedReloadData: Bool) -> Void)?) {
        guard let completion = completion else { return }

        // If is form bookmark or the old and new path do not match, the data must be reloaded.
        if lockFile?.isFromBookMark == true, self.lockFile != oldLockFile {
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

    private func resetSelectedData() {
        seletedPods = []
        detail = []
    }

    private func loadData() {
        DispatchQueue.main.async {
            self.resetSelectedData()

            guard let info = self.lockFile else { return }
            self.isLoading = true
            DispatchQueue.global().async {
                self.lastReadDataTime = Date()
                if let lock = DataReader(file: info).readData() {
                    DispatchQueue.main.async {
                        // update lock data
                        self.lock = lock

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
