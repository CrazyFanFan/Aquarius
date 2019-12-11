//
//  PodModifier.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/11.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation
import SwiftUI

struct PodModifier: ViewModifier {
    var isSeleced: Bool

    func body(content: Self.Content) -> some View {
        if isSeleced {
            return AnyView(
                content
                    .foregroundColor(.red)
                    .font(.subheadline)
            )
        }
        return AnyView(content)
    }
}
