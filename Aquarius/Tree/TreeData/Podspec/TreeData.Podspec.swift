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

extension TreeData {
    @MainActor func showPodspec(of pod: Pod) {
        if isPodspecViewShow {
            isPodspecViewShow = false
        }

        if let cache = podspecCache[pod.name] {
            show(with: cache, and: nil)
        }

        asyncShowPodspecTask?.cancel()
        guard let lock else {
            assertionFailure("Should never here.")
            return
        }

        let lockFileURL = lockFile.url
        asyncShowPodspecTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let podspec = await Self.podspecInfo(for: pod, lock: lock, lockFileURL: lockFileURL),
                  !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard !Task.isCancelled else { return }
                self?.show(with: podspec, and: pod)
            }
        }
    }
}

// MARK: - show Podspec

private extension TreeData {
    nonisolated static func podspecInfo(for pod: Pod, lock: PodfileLock, lockFileURL: URL) async -> PodspecInfo? {
        let name = Self.normalized(name: pod.name)

        if let config = lock.externalSources[name] {
            if let path = config[":path"] {
                return Self.localPodspec(path, name: name, lockFileURL: lockFileURL)
            } else if config.keys.contains(":git") {
                return Self.gitPodspec(config, checkoutOption: lock.checkoutOptions[name])
            }
        } else if let repo = lock.specRepos.first(where: { repo in repo.pods.contains(name) }) {
            return await Self.repoPodspec(repo.repo, for: pod)
        } else {
            assertionFailure("Should never here.")
        }

        return nil
    }

    nonisolated static func normalized(name: String) -> String {
        if let index = name.firstIndex(of: "/") {
            return String(name[..<index])
        }
        return name
    }

    nonisolated static func normalized(version: String?) -> String? {
        version?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "()")))
    }

    /// UI show podspec
    /// - Parameters:
    ///   - podspec: podspec
    ///   - pod: pod use as cache key, pass nil to skip update cache.
    @MainActor
    func show(with podspec: PodspecInfo, and pod: Pod?) {
        if let pod {
            podspecCache[pod.name] = podspec
        }
        self.podspec = podspec
        isPodspecViewShow = true
    }

    nonisolated static func localPodspec(_ path: String, name: String, lockFileURL: URL) -> PodspecInfo {
        let projectURL = lockFileURL
            .deletingLastPathComponent()
            .resolvingSymlinksInPath()
        let newURL = lockFileURL
            .deletingLastPathComponent()
            .appendingPathComponent(path)
            .appendingPathComponent("\(name).podspec")
            .resolvingSymlinksInPath()

        func resolvedBookmark(containing url: URL) -> URL? {
            let bookmarks = AppSettings.shared.podspecAccessBookmarks
            for (bookmarkURL, bookmark) in bookmarks {
                guard url.isDescendant(of: bookmarkURL),
                      let resolved = BookmarkTool.resolve(bookmark) else {
                    continue
                }

                if let refreshedBookmark = resolved.refreshedBookmark {
                    AppSettings.shared.podspecAccessBookmarks[bookmarkURL] = refreshedBookmark
                }

                return resolved.url
            }

            return nil
        }

        return .local(.init(
            url: newURL,
            accessURL: resolvedBookmark(containing: newURL) ?? projectURL,
            requireAccessing: true
        ))
    }

    nonisolated static func gitPodspec(_ config: [String: String], checkoutOption: [String: String]?) -> PodspecInfo? {
        guard let gitURLString = config[":git"] else {
            // todo error
            assertionFailure("Should never here.")
            return nil
        }

        let revision: GitRevision

        if let commit = config[":commit"] {
            revision = .commit(commit)
        } else if let tag = config[":tag"] {
            revision = .tag(tag)
        } else if let branch = config[":branch"], let commit = checkoutOption?[":commit"] {
            revision = .branch(branch: branch, commit: commit)
        } else if let commit = checkoutOption?[":commit"] {
            revision = .autoCommit(commit)
        } else {
            assertionFailure("Should never here.")
            return nil
        }

        return .git(.init(gitURLString: gitURLString, revision: revision))
    }

    /// run shell
    @discardableResult
    nonisolated static func shell(_ command: String, environment: [String: String]? = nil) -> (String, Int32) {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe

        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        if let environment {
            task.environment = environment
        }
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return (output, task.terminationStatus)
    }

    /// check if repo match git url
    nonisolated static func check(repo: URL, matchGitURL url: String) -> Bool {
        var isDirectory: ObjCBool = .init(false)

        guard FileManager.default.fileExists(atPath: repo.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              FileManager.default.fileExists(atPath: repo.appendingPathComponent(".git").path) else {
            return false
        }

        let result = Self.shell("git -C \(repo.path) remote -v")

        guard result.1 == 0 else {
            return false
        }

        return result.0.lowercased().contains(url)
    }

    /// check if repo match git repo name
    nonisolated static func check(repo: URL, matchGitRepoName name: String) -> Bool {
        repo.lastPathComponent.lowercased().hasSuffix(name)
    }

    /// Find podspec in repo
    nonisolated static func findPod(_ pod: Pod, in repoURL: URL) -> URL? {
        guard let version = normalized(version: pod.info?.version) else {
            return nil
        }

        let name = Self.normalized(name: pod.name)

        // try simple repo first
        let tmpPath = repoURL.appendingPathComponent("\(name)/\(version)/\(name).podspec.json")
        if FileManager.default.fileExists(atPath: tmpPath.path) {
            return tmpPath
        }

        let result = Self.shell("find \(repoURL.path) -type d -name \(name)")

        guard result.1 == 0 else { return nil }

        let podspecURL = URL(fileURLWithPath: result.0.trimmingCharacters(in: .whitespacesAndNewlines))
            .appendingPathComponent("\(version)/\(name).podspec.json")

        if FileManager.default.fileExists(atPath: podspecURL.path) {
            return podspecURL
        }

        return nil
    }

    /// Find repo in repos root dir
    nonisolated static func findRepoURL(at repoRootURL: URL, with repoGitURLString: String) -> URL? {
        guard let tmpSubDirectories = subDirectories(of: repoRootURL), !tmpSubDirectories.isEmpty else { return nil }

        let url = repoGitURLString.lowercased()
        if let repo = tmpSubDirectories.first(where: { Self.check(repo: $0, matchGitURL: url) }) { return repo }

        var repoName = repoGitURLString.lowercased()
        if repoName.hasSuffix(".git") {
            repoName.removeLast(4)
        }
        repoName = repoName.components(separatedBy: "/").last ?? repoName

        return tmpSubDirectories.first(where: { Self.check(repo: $0, matchGitRepoName: repoName) })
    }

    nonisolated static func subDirectories(of url: URL) -> [URL]? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
            return contents.compactMap { element in
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

    nonisolated static func repoPodspec(_ repoGitURLString: String, for pod: Pod) async -> PodspecInfo? {
        func requireCocoapodsRepoReadPermission() async -> URL? {
            let cocoapodsRepoRoot = Utils.userHome.appendingPathComponent(".cocoapods")
            let bookmark = await MainActor.run {
                AppSettings.shared.repoBookMark[cocoapodsRepoRoot]
            }
            if let data = bookmark, let resolved = BookmarkTool.resolve(data) {
                if let refreshedBookmark = resolved.refreshedBookmark {
                    await MainActor.run {
                        AppSettings.shared.repoBookMark[cocoapodsRepoRoot] = refreshedBookmark
                    }
                }
                return resolved.url
            }

            if let url = await DiskAccessHelper.requireReadAccess(of: cocoapodsRepoRoot) {
                let bookmark = BookmarkTool.bookmark(for: url)
                await MainActor.run {
                    AppSettings.shared.repoBookMark[cocoapodsRepoRoot] = bookmark
                }
                return url
            }

            return nil
        }

        guard let url = await requireCocoapodsRepoReadPermission() else {
            return nil
        }

        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let repoRoots = Self.subDirectories(of: url), !repoRoots.isEmpty else {
            // TODO: tips
            return nil
        }

        for url in repoRoots {
            let podspecFileURL: URL? = if repoGitURLString == "trunk" { // trunk is key for cdn
                Self.findPod(pod, in: url.appendingPathComponent("trunk"))
            } else if let repoFileURL = Self.findRepoURL(at: url, with: repoGitURLString) {
                Self.findPod(pod, in: repoFileURL)
            } else {
                // TODO: Add custom repo path support.
                // assert(false, "Should never here.")
                nil
            }

            guard let podspecFileURL else {
                continue
            }

            return .repo(
                RepoSpec(
                    repoGitString: repoGitURLString,
                    podspecFile: PodspecFile(url: podspecFileURL)
                )
            )
        }

        return nil
    }
}

private extension URL {
    func isDescendant(of directoryURL: URL) -> Bool {
        let pathComponents = standardizedFileURL.pathComponents
        let directoryPathComponents = directoryURL.standardizedFileURL.pathComponents

        guard pathComponents.count >= directoryPathComponents.count else {
            return false
        }

        return zip(pathComponents, directoryPathComponents).allSatisfy(==)
    }
}
