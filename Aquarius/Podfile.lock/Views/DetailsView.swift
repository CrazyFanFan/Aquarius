//
//  DetailsView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

struct DetailsView: View {
    @EnvironmentObject var data: DataAndSettings
    @State private var searchText: String = ""

    var body: some View {
        VStack{
            
            HStack {
                TextField("Type your search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("X") { self.searchText = "" }
            }

            List {
                ForEach(data.detail.reduce([Detail](), +)) { self.view(for: $0) }
            }

        }.frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
    }

    private func view(for detail: Detail) -> AnyView? {
        switch detail.content {
        case .pod(let pod):
            if searchText.isEmpty || pod.name.lowercased().contains(searchText.lowercased()) {
                return AnyView(HStack {
                    Text(pod.name)
                        .font(.headline)
                        .foregroundColor(.red)
                    Spacer()
                    Text(pod.info?.name ?? "")
                })
            }
        case .nextLevel(let name):
            if searchText.isEmpty || name.lowercased().contains(searchText.lowercased()) {

                return AnyView(HStack {
                    Text(name)
                        .onTapGesture {
                            guard let pod = self.data.lock.pods.first(where: { $0.name == name }) else { return }
                            self.data.onSelectd(pod: pod, with: detail.index + 1)
                    }
                    Spacer()
                    Text("▼")
                })
            }
        }
        return nil
    }
}

#if DEBUG
struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView()
            .environmentObject(testData)
    }
}
#endif
