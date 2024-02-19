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

    var body: some View {
        Group {
            switch podspec {
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
        .background(Color(NSColor.windowBackgroundColor))
        .contentShape(RoundedRectangle(cornerRadius: 5))
        .frame(
            minWidth: 700,
            maxWidth: 700,
            minHeight: 350,
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
            }

            Divider()

            switch spec.content {
            case let .content(contents):
                ScrollView {
                    Text(contents)
                        .textSelection(.enabled)
                }
            case let .error(error):
                Group {
                    Text(error).foregroundColor(.close)
                    MyPreview(url: spec.url)
                }
            }
        }
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
}

#Preview {
    PodspecView(podspec: .local(.init(url: URL(fileURLWithPath: "/tmp"), content: "Test content")))
}
