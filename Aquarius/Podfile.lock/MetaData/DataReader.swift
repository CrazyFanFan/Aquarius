//
//  DataReader.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation
import Yams

class DataReader {
    private var path: String?

    init(path: String?) {
        self.path = path
    }

    func readData() -> Lock? {
        guard let path = path else { return nil }

        guard let lockContent = try? String(contentsOfFile: path) else { return nil }

        let yaml: [String: Any]
        do {
            yaml = try Yams.load(yaml: lockContent) as? [String: Any] ?? [:]
        } catch {
            print(error)
            return nil
        }

        var lock = Lock()
        if let pods = yaml[LockRootKey.pods.rawValue] as? [Any] {
            readPods(from: pods, with: &lock)
        }

        if let dependencies = yaml[LockRootKey.dependencies.rawValue] as? [String] {
            lock.dependencies = dependencies.map { Pod(podValue: $0) }
        }

        if let specRepos = yaml[LockRootKey.specRepos.rawValue] as? [String: [String]] {
            lock.specRepos = specRepos.map { SpecRepo(repo: $0, pods: $1) }
        }

        // TODO: more info
        return lock
    }

    @discardableResult
    private func readPods(from pods: [Any], with lock: inout Lock) -> Bool {
        for content in pods {
            if let string = content as? String {
                lock.pods.append(Pod(podValue: string))
            } else if let map = content as? [String: [String]] {
                if let pod = Pod(map: map) {
                    lock.pods.append(pod)
                }
            } else {
                print(content)
            }
        }
        return true
    }
}
