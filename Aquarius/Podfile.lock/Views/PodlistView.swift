//
//  PodlistView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/5.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

struct PodlistView: View {
    @EnvironmentObject var data: DataAndSettings
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Type your search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("X") { self.searchText = "" }
            }.padding(5)

            HStack {
                Text(data.lock.pods.isEmpty ? "Nothing" : "Total: \(data.lock.pods.count)")
                    .font(.title)

                Spacer()
            
                Button("Copy all") {
                    let content = self.data.lock.pods
                        .map { $0.name }
                        .joined(separator: "\n")
                    Pasteboard.write(content)
                }.font(.system(size: 10))
                    .disabled(data.lock.pods.isEmpty)
            }.padding(5)

            List {
                ForEach(data.lock.pods) { pod in
                    if self.searchText.isEmpty || pod.name.lowercased().contains(self.searchText.lowercased()) {
                        PodView(pod: pod)
                            .modifier(PodModifier(isSeleced: self.data.seletedPods.first == pod))
                            .onTapGesture {
                                self.data.onSelectd(pod: pod, with: 0)
                            }
                    }
                }
            }

        }.frame(minWidth: 400, maxWidth: 400, maxHeight: .infinity)
            .listStyle(PlainListStyle())
    }
}

struct PodlistView_Previews: PreviewProvider {
    static var previews: some View {
        PodlistView()
    }
}
