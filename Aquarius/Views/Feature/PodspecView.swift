//
//  PodspecView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/12/4.
//

import SwiftUI

struct PodspecView: View {
    @Environment(\.presentationMode) var presentationMode

    var podspec: TreeData.PodspecInfo?
    @State private var reloadedPodspec: TreeData.PodspecInfo?

    private var currentPodspec: TreeData.PodspecInfo? {
        reloadedPodspec ?? podspec
    }

    var body: some View {
        Group {
            switch currentPodspec {
            case .none:
                Text("Empty")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }

            case let .local(spec):
                localView(for: spec)

            case let .repo(spec):
                repoView(for: spec)

            case let .git(spec):
                gitView(for: spec)
            }
        }
        .padding()
        .frame(
            minWidth: 700,
            maxWidth: 700,
            minHeight: 500,
            maxHeight: 700,
            alignment: .center
        )
    }
}

private extension PodspecView {
    func localView(for spec: TreeData.PodspecFile) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(spec.url.path)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            switch spec.content {
            case let .content(contents):
                highlightedPodspecContents(contents)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case let .error(error):
                Group {
                    Text(error)
                        .foregroundColor(.close)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    QLPreview(url: spec.url)
                }
            case let .permissionRequired(message):
                VStack(alignment: .leading, spacing: 12) {
                    Text(message)
                        .foregroundColor(.close)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Grant Project Folder Access") {
                        grantAccess(for: spec)
                    }

                    QLPreview(url: spec.url)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Copy path") {
                    Pasteboard.write(spec.url.path)
                }

                if case let .content(contents) = spec.content {
                    Button("Copy content") {
                        Pasteboard.write(contents)
                    }
                }

                Button("Show in finder") {
                    NSWorkspace.shared.selectFile(spec.url.path, inFileViewerRootedAtPath: "")
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    func gitView(for spec: TreeData.GitSpec) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Git: \(spec.gitURLString)")
                Spacer()
            }

            switch spec.revision {
            case let .commit(commit):
                Text("Commit: \(commit)")
            case let .branch(branch, commit):
                Text("Branch: \(branch), Commit: \(commit)")
            case let .tag(tag):
                Text("Tag: \(tag)")
            case let .autoCommit(commit):
                Text("No branch tag or commit specified, automatic checkout commit: \(commit)")
            }

            Spacer()

            Text("Viewing PodSpecs in Git sources is not supported currently.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Copy path") {
                    Pasteboard.write(spec.gitURLString)
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    func repoView(for spec: TreeData.RepoSpec) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(spec.repoGitString)

                Spacer()

                Button("Copy repo URL") {
                    Pasteboard.write(spec.repoGitString)
                }
            }

            Divider()

            localView(for: spec.podspecFile)
        }
    }

    @ViewBuilder
    func highlightedPodspecContents(_ contents: String) -> some View {
        if contents.firstNonWhitespace == "{" || contents.firstNonWhitespace == "[" {
            JSONHighlightedText(contents: contents)
        } else {
            RubyDSLHighlightedText(contents: contents)
        }
    }

    func grantAccess(for spec: TreeData.PodspecFile) {
        let podspecDirectoryURL = spec.url.deletingLastPathComponent()
        guard let selectedURL = DiskAccessHelper.requireReadAccess(
            of: podspecDirectoryURL,
            directoryURL: spec.accessURL ?? podspecDirectoryURL,
            title: NSLocalizedString("Grant Podspec Access", comment: ""),
            prompt: NSLocalizedString("Grant Access", comment: ""),
            allowsEnclosingDirectory: true
        ) else {
            return
        }

        guard let bookmark = BookmarkTool.bookmark(for: selectedURL) else {
            return
        }

        AppSettings.shared.podspecAccessBookmarks[selectedURL] = bookmark
        let reloadedSpec = spec.reloaded(with: selectedURL)

        switch currentPodspec {
        case let .repo(repoSpec):
            reloadedPodspec = .repo(.init(
                repoGitString: repoSpec.repoGitString,
                podspecFile: reloadedSpec
            ))
        default:
            reloadedPodspec = .local(reloadedSpec)
        }
    }
}

private extension String {
    var firstNonWhitespace: Character? {
        first { !$0.isWhitespace }
    }
}

#Preview {
    PodspecView(podspec: .local(.init(url: URL(fileURLWithPath: "/tmp"), content: "Test content")))
}
