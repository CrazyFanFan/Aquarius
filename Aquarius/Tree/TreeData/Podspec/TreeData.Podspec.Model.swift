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
           let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let newString = String(data: data, encoding: .utf8) {
            return newString
        }

        return self
    }
}

extension TreeData {
    struct LocalSpec {
        enum PodspecContent {
            case content([String])
            case error(String)
        }

        var url: URL
        var content: PodspecContent

        init(url: URL, content: String? = nil) {
            func urlContent(of url: URL) -> PodspecContent {
                do {
                    let url = URL(fileURLWithPath: url.path)
                    let isAcccessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if isAcccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    guard isAcccessing else {
                        return .error(NSLocalizedString("""
                        Load podspec content failed.
                        Sorry, you do not have permission to access the podspec file. Please use the 'Show in Finder' to view the file yourself.
                        """, comment: ""))
                    }

                    let prettiedContent = try String(contentsOf: url)
                        .prettied()
                        .components(separatedBy: "\n")

                    return .content(prettiedContent)
                } catch {
                    print(error)
                    return .error(NSLocalizedString("Load podspec content failed.", comment: ""))
                }
            }

            self.url = url

            if let string = content {
                self.content = .content(string.components(separatedBy: "\n"))
            } else {
                self.content = urlContent(of: url)
            }
        }
    }

    struct RepoSpec {
        var repoURLString: String
        var local: LocalSpec
    }

    struct GitSpec {
        enum GitRevision: Hashable {
            /// branch and commit
            case branch(branch: String, commit: String)
            case tag(String)
            case commit(String)
            case autoCommit(String)
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
