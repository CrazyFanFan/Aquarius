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

    private var seletedPods: [Pod] = []

    func onSelectd(pod: Pod, with level: Int) {
        if seletedPods.count > level {
            seletedPods.removeSubrange(level...)
            seletedPods.append(pod)
        } else {
            seletedPods.append(pod)
        }

        loadDetail()
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
}
