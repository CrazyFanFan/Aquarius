//
//  PodInfo.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

struct PodView: View {
    var pod: Pod
    var body: some View {
        HStack {
            Text(pod.name)
            Spacer()
            Text(pod.info?.name ?? "") + Text("▶")
        }
        .padding(2)
    }
}

struct PodInfo_Previews: PreviewProvider {
    static var previews: some View {
        PodView(pod: Pod(podValue: "Test (1.2.3)"))
    }
}
