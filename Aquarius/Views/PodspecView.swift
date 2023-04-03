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

            case .local(let spec):
                localView(for: spec)

            case .repo(let spec):
                repoView(for: spec)

            case .git(let spec):
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
    @ViewBuilder func contentView(_ content: String?) -> some View {
        if let content = content {
            Text(content)
        } else {
            Text("Load podspec content failed.")
        }
    }

    func localView(for spec: TreeData.LocalSpec) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(spec.podspecFileURL.path)
            }

            Divider()

            switch spec.podspecContent {
            case .content(let contents):
                List(contents.indices, id: \.self) {
                    Text(contents[$0])
                }
            case .error(let error):
                Group {
                    Text(error).foregroundColor(.close)
                    MyPreview(url: spec.podspecFileURL)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Copy path") {
                    Pasteboard.write(spec.podspecFileURL.path)
                }

                if case let .content(contents) = spec.podspecContent {
                    Button("Copy content") {
                        Pasteboard.write(contents.joined(separator: "\n"))
                    }
                }

                Button("Show in finder") {
                    NSWorkspace.shared.selectFile(spec.podspecFileURL.path, inFileViewerRootedAtPath: "")
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
            case .commit(let commit):
                Text("Commit: \(commit)")
            case .branch(let branch, let commit):
                Text("Branch: \(branch), Commit: \(commit)")
            case .tag(let tag):
                Text("Tag: \(tag)")
            case .autoCommit(let commit):
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
                Text(spec.repoURLString)

                Spacer()

                Button("Copy repo URL") {
                    Pasteboard.write(spec.repoURLString)
                }
            }

            Divider()

            localView(for: spec.local)
        }
    }
}

struct PodspecView_Previews: PreviewProvider {
    static var previews: some View {
        PodspecView(
            podspec: .local(.init(podspecFileURL: URL(fileURLWithPath: "/tmp"), podspecContent: "Test content")))
    }
}
