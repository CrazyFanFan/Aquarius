//
//  TreeData.Podspec.Model.swift
//  Aquarius
//
//  Created by Crazy凡 on 2023/5/7.
//

import Foundation

extension String {
    func prettied() -> String {
        if let stringData = data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: stringData, options: []),
           let data = try? JSONSerialization.data(
               withJSONObject: json,
               options: [.prettyPrinted, .withoutEscapingSlashes]
           ),
           let newString = String(data: data, encoding: .utf8) {
            return newString
        }

        return self
    }
}

extension TreeData {
    enum PodspecContent {
        case content(String)
        case error(String)
        case permissionRequired(String)
    }

    struct PodspecFile {
        var url: URL
        var content: PodspecContent
        var accessURL: URL?

        init(url: URL, content: String? = nil, accessURL: URL? = nil, requireAccessing: Bool = false) {
            func urlContent(of url: URL, accessURL: URL?) -> PodspecContent {
                do {
                    let scopedURL = accessURL ?? url
                    let isAcccessing = requireAccessing && scopedURL.startAccessingSecurityScopedResource()
                    defer {
                        if isAcccessing {
                            scopedURL.stopAccessingSecurityScopedResource()
                        }
                    }

                    guard !requireAccessing || isAcccessing else {
                        return .permissionRequired(NSLocalizedString("""
                        Failed to load podspec contents.
                        Aquarius does not have permission to read this podspec file. \
                        Grant access to the project folder to preview it.
                        """, comment: ""))
                    }

                    return try .content(String(contentsOf: url).prettied())
                } catch {
                    print(error)
                    return .error(NSLocalizedString("Failed to load podspec contents.", comment: ""))
                }
            }

            self.url = url
            self.accessURL = accessURL

            if let string = content {
                self.content = .content(string)
            } else {
                self.content = urlContent(of: url, accessURL: accessURL)
            }
        }

        func reloaded(with accessURL: URL? = nil) -> PodspecFile {
            PodspecFile(url: url, accessURL: accessURL ?? self.accessURL, requireAccessing: true)
        }
    }

    struct RepoSpec {
        var repoGitString: String
        var podspecFile: PodspecFile
    }

    enum GitRevision: Hashable {
        /// branch and commit
        case branch(branch: String, commit: String)
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
        case local(PodspecFile)
        case git(GitSpec)
    }
}

extension TreeData.PodspecContent: Sendable {}
extension TreeData.PodspecFile: Sendable {}
extension TreeData.RepoSpec: Sendable {}
extension TreeData.GitRevision: Sendable {}
extension TreeData.GitSpec: Sendable {}
extension TreeData.PodspecInfo: Sendable {}
