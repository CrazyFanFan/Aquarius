//
//  LockRootView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
import SwiftUI

private let supportType: String = kUTTypeFileURL as String

struct LockRootView: View {
    @EnvironmentObject var data: TreeData

    var body: some View {
        ZStack {
            HStack {
                DropView()

                if data.lockFile != nil {
                    TreeContent()
                }
            }

            if data.isLoading {
                ActivityIndicator()
                    .frame(width: 50, height: 50, alignment: .center)
                    .animation(.easeInOut)
            }
        }
        .frame(minHeight: 350, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LockRootView()
    }
}
