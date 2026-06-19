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
        var parsedPods: [Pod] = []
        parsedPods.reserveCapacity(pods.count)

        for content in pods {
            if let string = content as? String {
                parsedPods.append(Pod(podValue: string))
            } else if let map = content as? [String: [String]] {
                if let pod = Pod(map: map) {
                    parsedPods.append(pod)
                    pod.successors.forEach { name in
                        var content = predecessors[name] ?? []
                        content.append(pod.name)
                        predecessors[name] = content
                    }
                }
            } else {
                assertionFailure("Get unknown data: \(content)")
            }
        }

        lock.pods = parsedPods.map { pod in
            if let predecessors = predecessors[pod.name] {
                Pod(name: pod.name, info: pod.info, successors: pod.successors, predecessors: predecessors)
            } else {
                pod
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

        struct PodAggregate {
            var info: Pod.Info?
            var hasRootInfo = false
            var successors: [String] = []
            var predecessors: [String] = []
        }

        let aggregates = lock.pods.reduce(into: [String: PodAggregate]()) { partialResult, pod in
            let name = rootName(of: pod.name)
            let isRootPod = name == pod.name
            var aggregate = partialResult[name] ?? PodAggregate(info: pod.info)

            if isRootPod || (!aggregate.hasRootInfo && aggregate.info == nil) {
                aggregate.info = pod.info
                aggregate.hasRootInfo = isRootPod
            }

            aggregate.successors.append(contentsOf: pod.successors)
            aggregate.predecessors.append(contentsOf: pod.predecessors)
            partialResult[name] = aggregate
        }

        func removeDuplicates(_ strings: [String], podName: String) -> [String] {
            var names = Set(strings.map { rootName(of: $0) })
            names.remove(podName)
            return names.sorted()
        }

        let pods = aggregates.map { name, aggregate in
            Pod(
                name: name,
                info: aggregate.info,
                successors: removeDuplicates(aggregate.successors, podName: name),
                predecessors: removeDuplicates(aggregate.predecessors, podName: name)
            )
        }
        .sorted(by: { $0.name < $1.name })

        var lock = lock
        lock.pods = pods
        return lock
    }
}
