//
//  PodlistView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/12/5.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

struct PodlistView: View {
    @EnvironmentObject var data: UserData

    var body: some View {
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

                    Toggle(isOn: self.$data.isRecursive) { Text("Recursive") }
                        .font(.system(size: 10))
                }
            }

            ForEach(data.lock.pods) { pod in
                PodInfo(pod: pod)
                    .onTapGesture {
                        self.data.onSelectd(pod: pod, with: 0)
                }
            }
        }.frame(minWidth: 400, maxWidth: 400, maxHeight: .infinity)
    }
}

struct PodlistView_Previews: PreviewProvider {
    static var previews: some View {
        PodlistView()
    }
}
