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
    private var fileURL: URL?

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    func readData(_ isFromBookMark: Bool) -> Lock? {
        guard let fileURL = fileURL else { return nil }

        if isFromBookMark {
            guard fileURL.startAccessingSecurityScopedResource() else { return nil }
        }

        defer {
            if isFromBookMark {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let lockContent: String
        do {
            lockContent = try String(contentsOf: fileURL)
        } catch {
            print(error)
            return nil
        }

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
        var infecteds = [String: [String]]()
        for content in pods {
            if let string = content as? String {
                lock.pods.append(Pod(podValue: string))
            } else if let map = content as? [String: [String]] {
                if let pod = Pod(map: map) {
                    lock.pods.append(pod)
                    pod.dependencies?.forEach { (name) in
                        var content = infecteds[name] ?? []
                        content.append(pod.name)
                        infecteds[name] = content
                    }
                }
            } else {
                print(content)
            }
        }

        infecteds.forEach { arg in
            if let index = lock.pods.firstIndex(where: { $0.name == arg.key }) {
                lock.pods[index].infecteds = arg.value
            }
        }
        return true
    }
}
