//
//  DataReader.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation
import Yams
// 可以用系统组件，先只给一层数据
final class DataReader {
    private var file: LockFileInfo

    init(file: LockFileInfo) {
        self.file = file
    }

    func readData() -> (lock: PodfileLock, noSubspeciesLock: PodfileLock)? {
        guard file.url.startAccessingSecurityScopedResource() else { return nil }

        defer {
            file.url.stopAccessingSecurityScopedResource()
        }

        let lockContent: String
        do {
            lockContent = try String(contentsOf: file.url)
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

        var lock = PodfileLock()
        if let pods = yaml[PodfileLockRootKey.pods.rawValue] as? [Any] {
            readPods(from: pods, with: &lock)
        }

//        if let dependencies = yaml[PodfileLockRootKey.dependencies.rawValue] as? [String] {
//            lock.dependencies = dependencies.map { Pod(podValue: $0) }
//        }
//
        if let specRepos = yaml[PodfileLockRootKey.specRepos.rawValue] as? [String: [String]] {
            lock.specRepos = specRepos.map { SpecRepo(repo: $0, pods: $1) }
        }

        if let externalSources = yaml[PodfileLockRootKey.externalSources.rawValue] as? [String: [String: String]] {
            lock.externalSources = externalSources
        }

        if let checkoutOptions = yaml[PodfileLockRootKey.checkoutOptions.rawValue] as? [String: [String: String]] {
            lock.checkoutOptions = checkoutOptions
        }

        // TODO: more info

        return (lock, noSubspeciesLock(from: lock))
    }

    @discardableResult
    private func readPods(from pods: [Any], with lock: inout PodfileLock) -> Bool {
        var predecessors = [String: [String]]()
        for content in pods {
            if let string = content as? String {
                lock.pods.append(Pod(podValue: string))
            } else if let map = content as? [String: [String]] {
                if let pod = Pod(map: map) {
                    lock.pods.append(pod)
                    pod.successors?.forEach { (name) in
                        var content = predecessors[name] ?? []
                        content.append(pod.name)
                        predecessors[name] = content
                    }
                }
            } else {
                assertionFailure("Get unknown data: \(content)")
            }
        }

        predecessors.forEach { arg in
            if let index = lock.pods.firstIndex(where: { $0.name == arg.key }) {
                lock.pods[index].predecessors = arg.value
            }
        }
        return true
    }

    private func noSubspeciesLock(from lock: PodfileLock) -> PodfileLock {
        func rootName(of name: String, splitIndex: String.Index? = nil) -> String {
            if let index = splitIndex ?? name.firstIndex(of: "/") {
                return String(name[..<index])
            }
            return name
        }

        let pods = lock.pods.map { $0.copy() }.reduce(into: [String: Pod]()) { partialResult, pod in
            if let index = pod.name.firstIndex(of: "/") {
                let name = rootName(of: pod.name, splitIndex: index)

                let mainPod = partialResult[name] ?? pod

                if !partialResult.keys.contains(name) {
                    pod.name = rootName(of: pod.name)
                    partialResult[name] = mainPod
                }

                var successors = mainPod.successors ?? []
                var predecessors = mainPod.predecessors ?? []

                if let subspeciesSuccessors = pod.successors {
                    successors.append(contentsOf: subspeciesSuccessors)
                }

                if let subspeciesPredecessors = pod.predecessors {
                    predecessors.append(contentsOf: subspeciesPredecessors)
                }

                mainPod.successors = successors
                mainPod.predecessors = predecessors

            } else {
                partialResult[pod.name] = pod
            }
        }
        .values
        .sorted(by: { $0.name < $1.name })

        func removeDuplicates(_ strings: [String], podName: String) -> [String]? {
            var names = Set(strings.map { rootName(of: $0) })
            names.remove(podName)
            return names.isEmpty ? nil : names.sorted()
        }

        for index in pods.indices {
            if let successors = pods[index].successors {
                pods[index].successors = removeDuplicates(successors, podName: pods[index].name)
            }
            if let predecessors = pods[index].predecessors {
                pods[index].predecessors = removeDuplicates(predecessors, podName: pods[index].name)
            }
        }

        var lock = lock
        lock.pods = pods
        return lock
    }
}
