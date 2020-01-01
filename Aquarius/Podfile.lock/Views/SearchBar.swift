//
//  SearchBar.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/19.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI
import Combine

struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            Text("🔍")
                .foregroundColor(.secondary)

            TextField("Type your search", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                self.searchText = ""
            }) {
                Text("×")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .frame(width: 20, height: 20, alignment: .center)
            .cornerRadius(10)
            .disabled(searchText == "")
        }
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(searchText: .constant(""))
    }
}
