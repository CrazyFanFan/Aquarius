//
//  PodsView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Grid
import SwiftUI

struct PodsView: View {
    @EnvironmentObject var data: UserData

    var body: some View {
        List(data.detail) { self.view(for: $0) }
    }

    func view(for detail: Detail) -> some View {
        switch detail.content {
        case .pod(let pod):
            return AnyView(HStack {
                Text(pod.name)
                Spacer()
                Text(pod.info?.name ?? "")
            }.font(.title)
            )
        case .dependencie(let name):
            return AnyView(Text(name)
                .onTapGesture {
                    guard let pod = self.data.lock.pods.first(where: { $0.name == name }) else { return }
                    self.data.onSelectd(pod: pod, with: detail.index + 1)
            })
        }
    }
}

struct PodsView_Previews: PreviewProvider {
    static var previews: some View {
        PodsView()
            .environmentObject(testData)
    }
}
