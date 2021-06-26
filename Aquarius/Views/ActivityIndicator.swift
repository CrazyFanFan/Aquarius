//
//  ActivityIndicator.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Foundation
import SwiftUI

struct ActivityIndicator: View {
    @State private var isAnimating: Bool = false

    var body: some View {
        GeometryReader(content: { geometry in
            ForEach(0..<5) { index in
                Group {
                    Circle()
                        .frame(width: geometry.size.width / 5, height: geometry.size.height / 5)
                        .scaleEffect(self.scaleEffect(index), anchor: .center)
                        .offset(y: geometry.size.width / 10 - geometry.size.height / 2)
                }.frame(width: geometry.size.width, height: geometry.size.height)
                .rotationEffect(!self.isAnimating ? .degrees(0) : .degrees(360))
                .animation(Animation
                            .timingCurve(0.5, 0.15 + Double(index) / 5, 0.25, 1, duration: 1.5)
                            .repeatForever(autoreverses: false)
                )
            }
        })
        .aspectRatio(1, contentMode: .fit)
        .onAppear { () -> Void in
            self.isAnimating = true
        }
    }

    private func scaleEffect(_ index: Int) -> CGFloat {
        let index = CGFloat(index)
        return self.isAnimating ? 0.2 + index / 5 : 1 - index / 5
    }
}
