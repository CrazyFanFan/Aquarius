//
//  Data.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine

class DataAndSettings: ObservableObject {
    @Published var lock: Lock = Lock()
    @Published var detail: [Detail] = []

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

    private var seletedPods: [Pod] = []

    func tryUpdate() {
        if let pod = seletedPods.first {
            onSelectd(pod: pod, with: 0)
        }
    }

    func onSelectd(pod: Pod, with level: Int) {
        if seletedPods.count > level {
            seletedPods.removeSubrange(level...)
            seletedPods.append(pod)
        } else {
            seletedPods.append(pod)
        }

        if level == 0, isRecursive {
            self.detail = recursive()
        } else {
            loadDetail()
        }
    }
}

// load dependencies
extension DataAndSettings {
    private func loadDetail() {
        var result = [Detail]()
        for (index, pod) in seletedPods.enumerated() {
            result.append(Detail(index: index, content: .pod(pod)))
            if let nextLevel = pod.nextLevel(isImpactMode) {
                result += nextLevel.map { Detail(index: index, content: .nextLevel($0)) }
            }
        }
        detail = result
    }

    private func recursive() -> [Detail] {
        guard let pod = seletedPods.first else { return [] }
        var result = [String]()
        recursive(nextLevel: pod.nextLevel(isImpactMode), into: &result)
        return [Detail(index: 0, content: .pod(pod))] +
            Array(Set(result)).sorted().map { Detail(index: 0, content: .nextLevel($0)) }
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
