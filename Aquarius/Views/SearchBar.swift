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
    @Binding var text: String

    var body: some View {
        HStack(alignment: .center) {
            Image("magnifyingglass").icon()

            ZStack(alignment: .trailing) {
                TextField(LocalizedStringKey("Search"), text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.trailing)

                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image("xmark.circle.fill").icon()
                    }
                    .disabled(text == "")
                }
            }
            .frame(minWidth: 250)
        }
        .frame(minHeight: 28)
        .padding([.leading])
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(text: .constant(""))
    }
}
