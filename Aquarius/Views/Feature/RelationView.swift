//
//  RelationView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2024/10/23.
//

import SwiftUI

struct RelationView: View {
    @Environment(\.presentationMode) var presentationMode

    var pod: Pod

    @State var data: RelationTreeData
    @State private var pathSearchKey = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidebar
                Divider()
                detail
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)

            Divider()

            bottomBar
                .layoutPriority(1)
        }
        .onDisappear { data.cancel() }
        .frame(
            minWidth: 900,
            minHeight: 560,
            alignment: .center
        )
    }
}

private extension RelationView {
    var sidebar: some View {
        VStack(spacing: 0) {
            searchField("Search Modules", text: $data.searchKey)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            sidebarContent
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    var sidebarContent: some View {
        if !data.searchKey.isEmpty, data.showNames.allSatisfy(\.1.isEmpty) {
            ContentUnavailableView("No Modules", systemImage: "magnifyingglass")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(data.showNames, id: \.group) { group in
                        if !group.1.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                (Text(LocalizedStringKey(group.0.rawValue)) + Text(": \(group.1.count)"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)

                                ForEach(group.1, id: \.pod) { node in
                                    Button {
                                        data.select(group.0, node.0)
                                    } label: {
                                        sidebarRow(node)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }

    func sidebarRow(_ node: (pod: Pod, indices: Set<String.Index>?)) -> some View {
        let isSelected = data.selected == node.pod

        return NodeViewInfoHelper.name(node)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .primary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(
                isSelected ? Color.accentColor.opacity(0.14) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
    }

    var detail: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                detailTitle

                if data.selected != nil {
                    if let summary = data.summary {
                        summaryView(summary)
                    }

                    searchField("Search Paths", text: $pathSearchKey)
                        .frame(maxWidth: .infinity)

                    if data.isPathSearchLimited || data.loadsAllPaths {
                        Toggle(
                            "Load All Paths",
                            isOn: Binding(
                                get: { data.loadsAllPaths },
                                set: { data.setLoadsAllPaths($0) }
                            )
                        )
                        .toggleStyle(.switch)
                    }

                    if !data.paths.isEmpty {
                        Text(pathSearchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                             ? "Total: \(data.paths.count) path(s)"
                             : "Total: \(filteredPaths.count) / \(data.paths.count) path(s)")
                            .foregroundColor(.secondary)

                        if data.isPathSearchLimited {
                            Text("Showing the first \(RelationTreeData.maxPathCount) shortest paths. Use search to narrow the result.")
                                .foregroundColor(.secondary)
                        }
                    }

                    if data.isReleationLoading, !data.paths.isEmpty {
                        ProgressView("Loading")
                            .controlSize(.small)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            detailContent
                .layoutPriority(0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    var detailTitle: some View {
        if let selected = data.selected {
            Text("The connection between **\(pod.name)** and **\(selected.name)** is as follows")
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("Select a module on the left to inspect its connection with \(pod.name).")
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    func summaryView(_ summary: RelationSummary) -> some View {
        HStack(spacing: 12) {
            summaryItem("Subgraph Nodes", value: summary.nodeCount)
            summaryItem("Subgraph Edges", value: summary.edgeCount)
            summaryItem("Shortest Depth", value: summary.shortestDepth)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    func summaryItem(_ title: LocalizedStringKey, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(minWidth: 110, alignment: .leading)
    }

    var bottomBar: some View {
        HStack {
            Toggle("Show Related Nodes Only", isOn: $data.associatedOnly)

            Button("Copy All") {
                Pasteboard.write(data.paths.map { $0.joined(separator: "\n") }.joined(separator: "\n- - - - - -\n"))
            }

            Button("Copy Deduplicated") {
                Pasteboard.write(
                    data.paths
                        .reduce(into: Set<String>()) { $0.formUnion($1) }
                        .sorted()
                        .joined(separator: "\n")
                )
            }

            Spacer()

            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(minHeight: 52)
    }

    func searchField(_ title: LocalizedStringKey, text: Binding<String>) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(title, text: text)
                .textFieldStyle(.plain)

            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minHeight: 30)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    var filteredPaths: [(offset: Int, path: [String])] {
        let key = pathSearchKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let paths = data.paths.enumerated().map { (offset: $0.offset, path: $0.element) }
        guard !key.isEmpty else { return paths }

        return paths.filter { item in
            item.path.contains { name in
                name.lowercased().contains(key)
            }
        }
    }

    @ViewBuilder
    var detailContent: some View {
        if data.selected == nil {
            ContentUnavailableView("Select a Module", systemImage: "point.3.connected.trianglepath.dotted")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if data.isReleationLoading, data.paths.isEmpty {
            ProgressView("Loading")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if data.paths.isEmpty {
            ContentUnavailableView("No dependency path found", systemImage: "point.3.connected.trianglepath.dotted")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredPaths.isEmpty {
            ContentUnavailableView("No matching paths", systemImage: "magnifyingglass")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(filteredPaths, id: \.offset) { item in
                        pathSection(index: item.offset, path: item.path)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func pathSection(index: Int, path: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Path: \(index + 1), Count: \(path.count) (↓)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Copy") {
                    Pasteboard.write(path.joined(separator: "\n"))
                }
                .buttonStyle(.borderless)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(path, id: \.self) { name in
                    Text(name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .selectionDisabled(false)
                        .contextMenu {
                            Button("Copy") {
                                Pasteboard.write(name)
                            }
                        }

                    Divider()
                }
            }
        }
        .padding(.top, 8)
    }
}
