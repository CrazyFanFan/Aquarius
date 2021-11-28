//
//  SearchBar.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/19.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI
import Combine

fileprivate extension Image {
    func icon() -> some View {
        self
            .resizable()
            .frame(width: 12, height: 12, alignment: .center)
            .foregroundColor(.secondary)
    }
}

struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack(alignment: .center) {
            Image("magnifyingglass").icon()

            ZStack(alignment: .trailing) {
                TextField(LocalizedStringKey("Search"), text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.trailing)

                if !searchText.isEmpty {
                    Button(action: {
                        self.searchText = ""
                    }) {
                        Image("xmark.circle.fill").icon()
                    }
                    .disabled(searchText == "")
                }
            }
            .frame(minWidth: 250)
        }
        .frame(minHeight: 28)
        .padding([.leading])
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(searchText: .constant(""))
    }
}
