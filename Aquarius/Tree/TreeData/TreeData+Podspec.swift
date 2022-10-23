//
//  TreeData+Podspec.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/12/4.
//

import Foundation

/* Podfile.lock Git info data structure

 - commit
 EXTERNAL SOURCES:
   Alamofire:
     :commit: 0f506b1c45
     :git: https://github.com/Alamofire/Alamofire.git

 CHECKOUT OPTIONS:
   Alamofire:
     :commit: 0f506b1c45
     :git: https://github.com/Alamofire/Alamofire.git

 - Branch
 EXTERNAL SOURCES:
   Alamofire:
     :branch: master
     :git: https://github.com/Alamofire/Alamofire.git

 CHECKOUT OPTIONS:
   Alamofire:
     :commit: 65b77694905b0dea7e419b2f74b1e5dc037094b5
     :git: https://github.com/Alamofire/Alamofire.git

 - Tag
 EXTERNAL SOURCES:
   Alamofire:
     :git: https://github.com/Alamofire/Alamofire.git
     :tag: 5.4.4

 CHECKOUT OPTIONS:
   Alamofire:
     :git: https://github.com/Alamofire/Alamofire.git
     :tag: 5.4.4
 */

extension String {
    func prettied() -> String {
        if let stringData = data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: stringData, options: []),
        let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let newString = String(data: data, encoding: .utf8) {
            return newString
        }

        return self
    }
}

extension TreeData {
    struct RepoSpec {
        var repoURLString: String
        var local: LocalSpec
    }

    struct LocalSpec {
        var podspecFileURL: URL
        var podspecContent: [String]

        init(podspecFileURL: URL, podspecContent: String? = nil) {
            let string = podspecContent ??
            (try? String(contentsOfFile: podspecFileURL.path))?.prettied() ??
            "Load podspec content failed."

            self.podspecFileURL = podspecFileURL
            self.podspecContent = string.components(separatedBy: "\n")
        }
    }

    enum GitRevision: Hashable {
        /// branch and commit
        case branch(String, String)
        case tag(String)
        case commit(String)
        case autoCommit(String)
    }

    struct GitSpec {
        var gitURLString: String
        var revision: GitRevision
    }

    enum PodspecInfo {
        case repo(RepoSpec)
        case local(LocalSpec)
        case git(GitSpec)
    }
}

extension TreeData {
    func showPodspec(of pod: Pod) {
        GlobalState.shared.isLoading = true

        if let cache = podspecCache[pod] {
            show(with: cache, and: nil)
        }

        DispatchQueue.global().async { [weak self] in
            self?.asyncShowPodspec(of: pod)
        }
    }

    func asyncShowPodspec(of pod: Pod) {
        guard let lock = lock else {
            assert(false, "Should never here.")
            return
        }

        let name = normalized(name: pod.name)

        if let config = lock.externalSources[name] {
            if let path = config[":path"] {
                loadLocalPodspec(path, name: name, pod: pod)
            } else if config.keys.contains(":git") {
                loadGitPodspec(config, checkoutOption: lock.checkoutOptions[name], pod: pod)
            }
        } else if let repo = lock.specRepos.first(where: { repo in repo.pods.contains(name) }) {
            loadRepoPodspec(repo.repo, for: pod)
        } else {
            assert(false, "Should never here.")
        }
    }
}

// MARK: - show Podspec
private extension TreeData {
    func normalized(name: String) -> String {
        name.components(separatedBy: "/").first ?? name
    }

    func normalized(version: String?) -> String? {
        guard var version = version?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }

        if version.hasPrefix("(") {
            version.removeFirst()
        }

        if version.hasSuffix(")") {
            version.removeLast()
        }

        return version
    }

    /// UI show podspec
    /// - Parameters:
    ///   - podspec: podspec
    ///   - pod: pod use as cache key, pass nil to skip update cache.
    func show(with podspec: PodspecInfo, and pod: Pod?) {
        if let pod = pod {
            podspecCache[pod] = podspec
        }
        self.podspec = podspec
        DispatchQueue.main.async {
            self.isPodspecShow = true
            GlobalState.shared.isLoading = false
        }
    }

    func loadLocalPodspec(_ path: String, name: String, pod: Pod) {
        guard let url = lockFile?.url else {
            assert(false, "Should never here.")
            return
        }

        var newURL = url
            .deletingLastPathComponent()

        var path = path
        if path.hasPrefix("./") {
            path.removeFirst(2)
        }

        while path.hasPrefix("../") {
            newURL.deleteLastPathComponent()
            path.removeFirst(3)
        }

        newURL.appendPathComponent(path)
        newURL.appendPathComponent("\(name).podspec")

        show(with: .local(.init(podspecFileURL: newURL)), and: pod)
    }

    func loadGitPodspec(_ config: [String: String], checkoutOption: [String: String]?, pod: Pod) {
        guard let gitURLString = config[":git"] else {
            // todo error
            assert(false, "Should never here.")
            return
        }

        let revision: GitRevision

        if let commit = config[":commit"] {
            revision = .commit(commit)
        } else if let tag = config[":tag"] {
            revision = .tag(tag)
        } else if let branch = config[":branch"], let commit = checkoutOption?[":commit"] {
            revision = .branch(branch, commit)
        } else if let commit = checkoutOption?[":commit"] {
            revision = .autoCommit(commit)
        } else {
            assert(false, "Should never here.")
            return
        }

        show(with: .git(.init(gitURLString: gitURLString, revision: revision)), and: pod)
    }

    /// run shell
    @discardableResult
    func shell(_ command: String, environment: [String: String]? = nil) -> (String, Int32) {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe

        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        if let environment = environment {
            task.environment = environment
        }
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return (output, task.terminationStatus)
    }

    func checkFileURL(_ url: URL, with gitURLString: String) -> Bool {
        var isDirectory: ObjCBool = .init(false)

        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
           isDirectory.boolValue,
           FileManager.default.fileExists(atPath: url.appendingPathComponent(".git").path) else {
               return false
           }

        let result = shell("git -C \(url.path) remote -v")

        guard result.1 == 0 else {
            return false
        }

        return result.0.lowercased().contains(gitURLString)
    }

    /// Find podspec in repo
    func findPod(_ pod: Pod, in filePathURL: URL) -> URL? {
        guard let version = normalized(version: pod.info?.version) else {
            return nil
        }

        let name = normalized(name: pod.name)

        // try simple repo first
        let tmpPath = filePathURL.appendingPathComponent("\(name)/\(version)/\(name).podspec.json")
        if FileManager.default.fileExists(atPath: tmpPath.path) {
            return tmpPath
        }

        let result = shell("find \(filePathURL.path) -type d -name \(name)")

        guard result.1 == 0 else { return nil }

        let podspecURL = URL(fileURLWithPath: result.0.trimmingCharacters(in: .whitespacesAndNewlines))
            .appendingPathComponent("\(version)/\(name).podspec.json")

        if FileManager.default.fileExists(atPath: podspecURL.path) {
            return podspecURL
        }

        return nil
    }

    func findRepoFileURL(at repoRootURL: URL, with repoGitURLString: String) -> URL? {
        let repoGitURLString = repoGitURLString.lowercased()

        let result = shell("ls \(repoRootURL.path)")

        guard result.1 == 0 else {
            return nil
        }

        let names = result.0.replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }

        for name in names where name != "trunk" {
            let tmpRepoURL = repoRootURL.appendingPathComponent(name)
            if checkFileURL(tmpRepoURL, with: repoGitURLString) {
                return tmpRepoURL
            }
        }

        return nil
    }

    func loadRepoPodspec(_ repoGitURLString: String, for pod: Pod) {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cocoapods/repos/")

        let podspecFileURL: URL?
        // trunk is key for cdn
        if repoGitURLString == "trunk" {
            podspecFileURL = findPod(pod, in: url.appendingPathComponent("trunk"))
        } else if let repoFileURL = findRepoFileURL(at: url, with: repoGitURLString) {
            podspecFileURL = findPod(pod, in: repoFileURL)
        } else {
            assert(false, "Should never here.")
            podspecFileURL = nil
        }

        guard let podspecFileURL = podspecFileURL else {
            return
        }

        show(
            with: .repo(.init(repoURLString: repoGitURLString, local: .init(podspecFileURL: podspecFileURL))),
            and: pod)
    }
}
