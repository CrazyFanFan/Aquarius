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

    var body: some View {
        HSplitView {
            List(data.showNames, id: \.group) { group in
                Section {
                    ForEach(group.1, id: \.pod) { node in
                        NodeViewInfoHelper.name(node)
                            .onTapGesture {
                                Task.detached {
                                    await data.select(group.0, node.0, pods: group.1.map(\.pod))
                                }
                            }
                    }
                } header: {
                    Text(LocalizedStringKey(group.0.rawValue))
                     + Text(": \(group.1.count)")
                }
            }
            .frame(minWidth: 150, idealWidth: 150, maxWidth: 250)
            .searchable(text: $data.searchKey, placement: .sidebar) {
                if !data.searchSuggestions.isEmpty {
                    ForEach(data.searchSuggestions, id: \.pod.name) { node in
                        NodeViewInfoHelper.name(node)
                            .searchCompletion(node.0.name)
                    }
                }
            }
            .listStyle(.sidebar)

            VStack {
                HStack {
                    Text("The connection between **\(pod.name)** and **\(data.selected?.name ?? "Unkonwn")** is as follows")
                        .lineLimit(nil)
                        .font(.system(size: 16))
                        .padding(.zero)

                    Spacer()
                }

                if !data.paths.isEmpty, !data.isReleationLoading {
                    HStack {
                        Text("Total: \(data.paths.count) path(s)")
                        Spacer()
                    }
                }

                if data.isReleationLoading {
                    Text("Loading")
                        .frame(maxHeight: .infinity)
                } else if data.paths.isEmpty {
                    Text("No connection")
                        .frame(maxHeight: .infinity)
                } else {
                    List(data.paths.indices, id: \.self) { index in
                        Section {
                            ForEach(data.paths[index], id: \.self) { name in
                                Text(name).selectionDisabled(false)
                                    .contextMenu {
                                        Button("Copy") {
                                            Pasteboard.write(name)
                                        }
                                    }
                            }
                        } header: {
                            HStack {
                                Text("Path: \(index + 1), Count: \(data.paths[index].count) (↓)")
                                Spacer()
                                Button("Copy") {
                                    Pasteboard.write(data.paths[index].joined(separator: "\n"))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .padding(.leading)
        }
        .onDisappear { data.cancel() }
        .toolbar {
            ToolbarItem {
                Toggle("Show Related Nodes Only", isOn: $data.associatedOnly)
            }

            ToolbarItemGroup {
                Button("Copy All") {
                    Pasteboard.write(data.paths.map { $0.joined(separator: "\n") }.joined(separator: "\n- - - - - -\n"))
                }

                Button("Copy (Prune)") {
                    Pasteboard.write(
                        data.paths
                            .reduce(into: Set<String>()) { $0.formUnion($1) }
                            .sorted()
                            .joined(separator: "\n")
                    )
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
        .frame(
            minWidth: 750,
            minHeight: 400,
            alignment: .center
        )
    }
}
