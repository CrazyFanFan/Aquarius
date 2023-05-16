//
//  TreeData.Podspec.swift
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

private var asyncShowPodspecTask: Task<Void, Never>?

extension TreeData {
    @MainActor func showPodspec(of pod: Pod) {
        GlobalState.shared.isLoading = true

        if let cache = podspecCache[pod] {
            show(with: cache, and: nil)
        }

        asyncShowPodspecTask = Task.detached(priority: .userInitiated) {
            await self.asyncShowPodspec(of: pod)

            DispatchQueue.main.async {
                GlobalState.shared.isLoading = false
            }
        }
    }
}

// MARK: - show Podspec
private extension TreeData {
    func asyncShowPodspec(of pod: Pod) async {
        guard let lock = lock else {
            assert(false, "Should never here.")
            return
        }

        let name = normalized(name: pod.name)

        if let config = lock.externalSources[name] {
            if let path = config[":path"] {
                await loadLocalPodspec(path, name: name, pod: pod)
            } else if config.keys.contains(":git") {
                loadGitPodspec(config, checkoutOption: lock.checkoutOptions[name], pod: pod)
            }
        } else if let repo = lock.specRepos.first(where: { repo in repo.pods.contains(name) }) {
            await loadRepoPodspec(repo.repo, for: pod)
        } else {
            assert(false, "Should never here.")
        }
    }

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

    func loadLocalPodspec(_ path: String, name: String, pod: Pod) async {
        let newURL = lockFile.url
            .deletingLastPathComponent()
            .appendingPathComponent(path)
            .appendingPathComponent("\(name).podspec")
            .resolvingSymlinksInPath()

        // TODO requireAccessing 
        show(with: .local(.init(url: newURL, requireAccessing: true)), and: pod)
    }

    func loadGitPodspec(_ config: [String: String], checkoutOption: [String: String]?, pod: Pod) {
        guard let gitURLString = config[":git"] else {
            // todo error
            assert(false, "Should never here.")
            return
        }

        let revision: GitSpec.GitRevision

        if let commit = config[":commit"] {
            revision = .commit(commit)
        } else if let tag = config[":tag"] {
            revision = .tag(tag)
        } else if let branch = config[":branch"], let commit = checkoutOption?[":commit"] {
            revision = .branch(branch: branch, commit: commit)
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

    /// check if repo match git url
    func check(repo: URL, matchGitURL url: String) -> Bool {
        var isDirectory: ObjCBool = .init(false)

        guard FileManager.default.fileExists(atPath: repo.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              FileManager.default.fileExists(atPath: repo.appendingPathComponent(".git").path) else {
            return false
        }

        let result = shell("git -C \(repo.path) remote -v")

        guard result.1 == 0 else {
            return false
        }

        return result.0.lowercased().contains(url)
    }

    /// check if repo match git repo name
    func check(repo: URL, matchGitRepoName name: String) -> Bool {
        repo.lastPathComponent.lowercased().hasSuffix(name)
    }

    /// Find podspec in repo
    func findPod(_ pod: Pod, in repoURL: URL) -> URL? {
        guard let version = normalized(version: pod.info?.version) else {
            return nil
        }

        let name = normalized(name: pod.name)

        // try simple repo first
        let tmpPath = repoURL.appendingPathComponent("\(name)/\(version)/\(name).podspec.json")
        if FileManager.default.fileExists(atPath: tmpPath.path) {
            return tmpPath
        }

        let result = shell("find \(repoURL.path) -type d -name \(name)")

        guard result.1 == 0 else { return nil }

        let podspecURL = URL(fileURLWithPath: result.0.trimmingCharacters(in: .whitespacesAndNewlines))
            .appendingPathComponent("\(version)/\(name).podspec.json")

        if FileManager.default.fileExists(atPath: podspecURL.path) {
            return podspecURL
        }

        return nil
    }

    /// Find repo in repos root dir
    func findRepoURL(at repoRootURL: URL, with repoGitURLString: String) -> URL? {
        guard let tmpSubDirectories = subDirectories(of: repoRootURL), !tmpSubDirectories.isEmpty else { return nil }

        let url = repoGitURLString.lowercased()
        if let repo = tmpSubDirectories.first(where: { check(repo: $0, matchGitURL: url) }) { return repo }

        var repoName = repoGitURLString.lowercased()
        if repoName.hasSuffix(".git") {
            repoName.removeLast(4)
        }
        repoName = repoName.components(separatedBy: "/").last ?? repoName

        return tmpSubDirectories.first(where: { check(repo: $0, matchGitRepoName: repoName) })
    }

    func subDirectories(of url: URL) -> [URL]? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
            return contents.compactMap { (element) in
                var isDirectory: ObjCBool = false
                let fullPath = url.appendingPathComponent(element)
                FileManager.default.fileExists(atPath: fullPath.path, isDirectory: &isDirectory)
                return isDirectory.boolValue ? fullPath : nil
            }
        } catch {
            print("Error while enumerating files \(url.path): \(error.localizedDescription)")
        }

        return nil
    }

    func loadRepoPodspec(_ repoGitURLString: String, for pod: Pod) async {
        func requireCocoapodsRepoReadPermission() async -> URL? {
            let cocoapodsRepoRoot = Utils.userHome.appendingPathComponent(".cocoapods")
            if let data = GlobalState.shared.repoBookMark[cocoapodsRepoRoot], let url = BookmarkTool.url(for: data) {
                return url.0
            }

            if let url = await DiskAccessHelper.requireReadAccess(of: cocoapodsRepoRoot) {
                GlobalState.shared.repoBookMark[cocoapodsRepoRoot] = BookmarkTool.bookmark(for: url)
                return url
            }

            return nil
        }

        guard let url = await requireCocoapodsRepoReadPermission() else {
            return
        }

        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let repoRoots = subDirectories(of: url), !repoRoots.isEmpty else {
            // TODO: tips
            return
        }

        for url in repoRoots {
            let podspecFileURL: URL?
            // trunk is key for cdn
            if repoGitURLString == "trunk" {
                podspecFileURL = findPod(pod, in: url.appendingPathComponent("trunk"))
            } else if let repoFileURL = findRepoURL(at: url, with: repoGitURLString) {
                podspecFileURL = findPod(pod, in: repoFileURL)
            } else {
                // TODO: Add custom repo path support.
                // assert(false, "Should never here.")
                podspecFileURL = nil
            }

            guard let podspecFileURL = podspecFileURL else {
                continue
            }

            show(
                with: PodspecInfo.repo(
                    RepoSpec(
                        repoGitString: repoGitURLString,
                        podspecFile: PodspecFile(url: podspecFileURL)
                    )
                ),
                and: pod)
        }
    }
}
