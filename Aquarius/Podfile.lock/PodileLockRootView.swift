//
//  ContentView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
import SwiftUI

private let supportType: String = kUTTypeFileURL as String

struct PodileLockRootView: View {
    @EnvironmentObject var data: UserData
    @State private var isPodViewShow: Bool = false

    var body: some View {
        HStack {
            DropView().environmentObject(data)
            PodlistView().environmentObject(data)
            if !data.detail.isEmpty {
                DetailsView().environmentObject(data)
            }
        }.frame(minHeight: 350, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PodileLockRootView()
    }
}
