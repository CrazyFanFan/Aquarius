//
//  PageCommonSettings.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/10/23.
//

import SwiftUI

struct PageCommonSettings: View {
    @Binding var orderRule: OrderBy
    @Binding var detailMode: DetailMode
    @Binding var isSubspeciesShow: Bool

    var body: some View {
        Group {
            Picker("Sort by:", selection: $orderRule) {
                ForEach(OrderBy.allCases, id: \.self) { rule in
                    Text("\(Image(systemName: "arrow.down")) \(rule.rawValue)").tag(rule)
                }
            }

            Picker("Model:", selection: $detailMode) {
                ForEach(DetailMode.allCases) { mode in
                    (
                        Text("\(image(of: mode)) ") +
                        Text(LocalizedStringKey(mode.rawValue.capitalized))
                    ).tag(mode)
                }
            }

            Picker("Subspecies:", selection: $isSubspeciesShow) {
                ForEach([true, false], id: \.self) {
                    (
                        Text("\(Image(systemName: $0 ? "eye" : "eye.slash")) ") +
                        Text(LocalizedStringKey($0 ? "Show" : "Hidden"))
                    ).tag($0)
                }
            }
        }
    }

    @inline(__always) private func image(of mode: DetailMode) -> Image {
        Image(systemName: mode == .successors ? "arrow.triangle.merge" : "arrow.triangle.branch")
    }
}

#Preview {
    PageCommonSettings(
        orderRule: .constant(.alphabeticalAscending),
        detailMode: .constant(.predecessors),
        isSubspeciesShow: .constant(false))
}
