//
//  Data.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
class UserData: ObservableObject {
    @Published var lock: PodfileLock = PodfileLock()
    @Published var detail: [Detail] = []
    @Published var isRecursive: Bool = false

    private var seletedPods: [Pod] = []

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

    private func loadDetail() {
        var result = [Detail]()
        for (index, pod) in seletedPods.enumerated() {
            result.append(Detail(index: index, content: .pod(pod)))
            if let dependencies = pod.dependencies {
                result += dependencies.map { Detail(index: index, content: .dependencie($0)) }
            }
        }
        detail = result
    }

    private func recursive() -> [Detail] {
        guard let pod = seletedPods.first else { return [] }
        var result = [String]()
        recursive(dependencie: pod.dependencies, into: &result)
        return [Detail(index: 0, content: .pod(pod))] +
            Array(Set(result)).sorted().map { Detail(index: 0, content: .dependencie($0)) }
    }

    private func recursive(dependencie: [String]?, into result: inout [String]) {
        guard var dependencie = dependencie else { return }
        dependencie.removeAll(where: { result.contains($0) })
        for dependency in dependencie {
            if let pod = lock.pods.first(where: { $0.name == dependency }) {
                result.append(dependency)
                recursive(dependencie: pod.dependencies, into: &result)
            }
        }
    }
}
