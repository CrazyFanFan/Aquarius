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
    @Binding var isSubspecShow: Bool

    var body: some View {
        Group {
            Picker("Sort by:", selection: $orderRule) {
                ForEach(OrderBy.allCases, id: \.self) { rule in
                    Text("\(Image("arrow.down")) \(rule.rawValue)").tag(rule)
                }
            }

            Picker("Model:", selection: $detailMode) {
                ForEach(DetailMode.allCases) { mode in
                    (
                        Text("\(Image(mode == .successors ? "arrow.triangle.branch.180" : "arrow.triangle.branch")) ") +
                        Text(LocalizedStringKey(mode.rawValue.capitalized))
                    ).tag(mode)
                }
            }

            Picker("Subspecs:", selection: $isSubspecShow) {
                ForEach([true, false], id: \.self) {
                    (
                        Text("\(Image($0 ? "eye" : "eye.slash")) ") +
                        Text(LocalizedStringKey($0 ? "Show" : "Hidden"))
                    ).tag($0)
                }
            }
        }
    }
}

struct PageSettings_Previews: PreviewProvider {
    static var previews: some View {
        PageCommonSettings(orderRule: .constant(.alphabeticalAscending), detailMode: .constant(.predecessors), isSubspecShow: .constant(false))
    }
}
