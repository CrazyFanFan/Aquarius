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

extension TreeData {
    struct RepoSpec {
        var repoURLString: String
        var local: LocalSpec
    }

    struct LocalSpec {
        var podspecFileURL: URL
        var podspecContent: String
    }

    struct GitSpec {
        enum GitRevision: Hashable {
            case brance(String)
            case tag(String)
            case commit(String)
        }

        var gitURLString: String
        var revision: GitRevision
    }

    enum PodspecInfo {
        case repo(RepoSpec)
        case local(LocalSpec)
        case git(GitSpec)
    }
}

// MARK: - show podspec
extension TreeData {
    private func normalized(name: String) -> String {
        name.components(separatedBy: "/").first ?? name
    }

    private func loadLoacalPodspec(_ path: String, name: String) {
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

        let string = (try? String(contentsOfFile: newURL.path)) ?? "Load podspec content faile."

        podspec = .local(.init(podspecFileURL: newURL, podspecContent: string))
        DispatchQueue.main.async {
            self.isPodspecShow = true
        }
    }

    private func loadGitPodspec(_ config: [String: String]) {

    }

    private func loadRepoPodspec(_ repoGitURLString: String) {

    }

    func showPodspec(of pod: Pod) {
        guard let lock = podfileLock else {
            assert(false, "Should never here.")
            return
        }

        let name = normalized(name: pod.name)

        if let config = lock.externalSources[name] {
            print(config)
            if let path = config[":path"] {
                loadLoacalPodspec(path, name: name)
            } else if config.keys.contains(":git") {
                loadGitPodspec(config)
            }
        } else if let repo = lock.specRepos.first(where: { repo in repo.pods.contains(name) }) {
            loadRepoPodspec(repo.repo)
        } else {
            assert(false, "Should never here.")
        }
    }
}
