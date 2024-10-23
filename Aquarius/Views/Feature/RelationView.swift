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
        HStack {
            VStack {
                HStack {
                    Text("The connection between **\(pod.name)** and **\(data.selected?.name ?? "Unkonwn")** is as follows")
                        .font(.system(size: 16))
                        .padding(.zero)
                    Spacer()
                }

                if data.isReleationLoading {
                    Text("Loading")
                        .frame(maxHeight: .infinity)
                } else if data.path.isEmpty {
                    Text("No connection")
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(data.path, id: \.self) { pod in
                            HStack {
                                Text(pod.name)
                                Spacer()
                                if pod.name != data.path.last?.name {
                                    Text("↓")
                                }
                            }
                        }
                    }
                }
            }

            List(data.showNames, id: \.pod.name) { node in
                NodeViewInfoHelper.name(node)
                    .onTapGesture {
                        data.select(node.pod)
                    }
            }
            .searchable(text: $data.searchKey) {
                if !data.searchSuggestions.isEmpty {
                    ForEach(data.searchSuggestions, id: \.pod.name) { node in
                        NodeViewInfoHelper.name(node)
                            .searchCompletion(node.0.name)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Copy") {
                    Pasteboard.write(data.path.map(\.name).joined(separator: "\n"))
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
