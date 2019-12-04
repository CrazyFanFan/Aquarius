//
//  PodsView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

struct PodsView: View {
    @EnvironmentObject var data: UserData

    var body: some View {
        return List(data.detail) {
            self.view(for: $0)
        }
    }

    private func view(for detail: Detail) -> some View {
        switch detail.content {
        case .pod(let pod):
            return AnyView(HStack {
                Text(pod.name)
                    .font(.headline)
                    .foregroundColor(.red)
                Spacer()
                Text(pod.info?.name ?? "")
            })
        case .dependencie(let name):
            if self.data.isRecursive {
                 return AnyView(Text(name))
            } else {
                return AnyView(Text(name)
                    .onTapGesture {
                        guard let pod = self.data.lock.pods.first(where: { $0.name == name }) else { return }
                        self.data.onSelectd(pod: pod, with: detail.index + 1)
                })
            }
        }
    }
}

struct PodsView_Previews: PreviewProvider {
    static var previews: some View {
        PodsView()
            .environmentObject(testData)
    }
}
