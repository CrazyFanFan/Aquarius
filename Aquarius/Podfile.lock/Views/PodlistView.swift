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
                Text("Total: \(data.lock.pods.count)")
                    .font(.title)
            }

            ForEach(data.lock.pods) { pod in
                PodView(pod: pod)
                    .onTapGesture {
                        self.data.onSelectd(pod: pod, with: 0)
                }
            }
        }.frame(minWidth: 400, maxWidth: 400, maxHeight: .infinity)
            .listStyle(PlainListStyle())
    }
}

struct PodlistView_Previews: PreviewProvider {
    static var previews: some View {
        PodlistView()
    }
}
