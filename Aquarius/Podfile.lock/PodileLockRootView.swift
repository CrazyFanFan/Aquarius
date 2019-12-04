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
    @State private var isRecursive: Bool = false

    var body: some View {
        HStack {
            DropView().environmentObject(data)

            List {
                if data.lock.pods.isEmpty {
                    Text("Nothing")
                } else {
                    HStack {
                        Text("Total: \(data.lock.pods.count)")
                            .font(.title)

                        Button("Copy all") {
                            let content = self.data.lock.pods
                                .map { $0.name }
                                .joined(separator: "\n")
                            Pasteboard.write(content)
                        }.font(.system(size: 10))

                        Toggle(isOn: self.$isRecursive) { Text("Recursive") }
                            .font(.system(size: 10))
                    }
                }

                ForEach(data.lock.pods) { pod in
                    PodInfo(pod: pod)
                        .onTapGesture {
                            self.data.isRecursive = self.isRecursive
                            self.data.onSelectd(pod: pod, with: 0)
                        }
                }
            }.frame(minWidth: 400, maxWidth: 400, maxHeight: .infinity)

            if !data.detail.isEmpty {
                PodsView().environmentObject(data)
                    .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            }
        }.frame(minHeight: 300, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PodileLockRootView()
    }
}
