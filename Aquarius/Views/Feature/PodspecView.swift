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
    @State private var podspecSearchText = ""
    @State private var podspecSearchNavigationToken = 0
    @State private var podspecSearchNavigationDirection = 1

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
                    .onChange(of: spec.url) { _, _ in
                        resetSearch()
                    }

            case let .repo(spec):
                repoView(for: spec)
                    .onChange(of: spec.podspecFile.url) { _, _ in
                        resetSearch()
                    }

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
        podspecDetailView(file: spec)
    }

    func gitView(for spec: TreeData.GitSpec) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            headerView(
                title: "Git Podspec",
                subtitle: spec.gitURLString,
                systemImage: "point.3.connected.trianglepath.dotted"
            )

            VStack(alignment: .leading, spacing: 8) {
                switch spec.revision {
                case let .commit(commit):
                    metadataRow("Commit", commit)
                case let .branch(branch, commit):
                    metadataRow("Branch", branch)
                    metadataRow("Commit", commit)
                case let .tag(tag):
                    metadataRow("Tag", tag)
                case let .autoCommit(commit):
                    metadataRow("Auto checkout commit", commit)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ContentUnavailableView(
                "Viewing PodSpecs in Git sources is not supported currently.",
                systemImage: "doc.text.magnifyingglass"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        podspecDetailView(
            file: spec.podspecFile,
            source: ("Repository", spec.repoGitString),
            copyRepoURLAction: {
                Pasteboard.write(spec.repoGitString)
            }
        )
    }

    func podspecDetailView(
        file spec: TreeData.PodspecFile,
        source: (title: String, value: String)? = nil,
        copyRepoURLAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView(
                title: spec.url.lastPathComponent.isEmpty ? "Podspec" : spec.url.lastPathComponent,
                subtitle: spec.url.deletingLastPathComponent().path,
                systemImage: "doc.text"
            )

            if let source {
                metadataRow(source.title, source.value)
                    .padding(.top, -2)
            }

            Divider()

            podspecContentView(for: spec)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Copy path") {
                    Pasteboard.write(spec.url.path)
                }

                if let copyRepoURLAction {
                    Button("Copy repo URL") {
                        copyRepoURLAction()
                    }
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

    @ViewBuilder
    func podspecContentView(for spec: TreeData.PodspecFile) -> some View {
        switch spec.content {
        case let .content(contents):
            VStack(spacing: 10) {
                previewToolbar
                previewContainer {
                    highlightedPodspecContents(contents)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        case let .error(error):
            VStack(alignment: .leading, spacing: 10) {
                statusMessage(error, systemImage: "exclamationmark.triangle")
                previewContainer {
                    QLPreview(url: spec.url)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        case let .permissionRequired(message):
            VStack(alignment: .leading, spacing: 12) {
                statusMessage(message, systemImage: "lock")

                Button("Grant Project Folder Access") {
                    grantAccess(for: spec)
                }

                previewContainer {
                    QLPreview(url: spec.url)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    func headerView(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
    }

    func metadataRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
    }

    func statusMessage(_ message: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.close)

            Text(message)
                .foregroundColor(.close)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func previewContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
            }
    }

    @ViewBuilder
    func highlightedPodspecContents(_ contents: String) -> some View {
        if contents.firstNonWhitespace == "{" || contents.firstNonWhitespace == "[" {
            JSONHighlightedText(
                contents: contents,
                searchText: podspecSearchText,
                searchNavigationToken: podspecSearchNavigationToken,
                searchNavigationDirection: podspecSearchNavigationDirection
            )
        } else {
            RubyDSLHighlightedText(
                contents: contents,
                searchText: podspecSearchText,
                searchNavigationToken: podspecSearchNavigationToken,
                searchNavigationDirection: podspecSearchNavigationDirection
            )
        }
    }

    var previewToolbar: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField(text: $podspecSearchText) {
                    Text(verbatim: "Search")
                }
                    .textFieldStyle(.plain)
                    .onSubmit {
                        guard !podspecSearchText.isEmpty else { return }
                        navigateSearch(direction: 1)
                    }

                if !podspecSearchText.isEmpty {
                    Button {
                        resetSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(Text(verbatim: "Clear search"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 30)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            Button {
                navigateSearch(direction: -1)
            } label: {
                Image(systemName: "chevron.up")
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .disabled(podspecSearchText.isEmpty)
            .help(Text(verbatim: "Previous match"))

            Button {
                navigateSearch(direction: 1)
            } label: {
                Image(systemName: "chevron.down")
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .disabled(podspecSearchText.isEmpty)
            .help(Text(verbatim: "Next match"))

        }
        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
    }

    func navigateSearch(direction: Int) {
        podspecSearchNavigationDirection = direction
        podspecSearchNavigationToken += 1
    }

    func resetSearch() {
        podspecSearchText = ""
        podspecSearchNavigationToken = 0
        podspecSearchNavigationDirection = 1
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
