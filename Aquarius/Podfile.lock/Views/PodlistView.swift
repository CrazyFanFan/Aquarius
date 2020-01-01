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
            SearchBar(searchText: $searchText)

            HStack {
                Text(data.lock.pods.isEmpty ? "Nothing" : "Total: \(data.lock.pods.count)")
                    .foregroundColor(.primary)
                    .font(.headline)

                Spacer()

                Button("Copy all") {
                    let content = self.data.lock.pods
                        .map { $0.name }
                        .joined(separator: "\n")
                    Pasteboard.write(content)
                }.disabled(data.lock.pods.isEmpty)
            }

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
            
        }.padding([.top, .trailing], 8)
            .frame(minWidth: 400, maxWidth: 400, maxHeight: .infinity)
    }
}

struct PodlistView_Previews: PreviewProvider {
    static var previews: some View {
        PodlistView()
    }
}
