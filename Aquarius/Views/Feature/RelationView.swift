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
            List(data.showNames, id: \.pod.name) { node in
                NodeViewInfoHelper.name(node)
                    .onTapGesture {
                        data.select(node.pod)
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
                                Text("Path \(index + 1): (↓)")
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
        .toolbar {
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
            minWidth: 700,
            maxWidth: 700,
            minHeight: 350,
            maxHeight: 700,
            alignment: .center
        )
    }
}
