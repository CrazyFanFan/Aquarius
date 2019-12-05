//
//  DropView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/29.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import Combine
import SwiftUI

private let supportType: String = kUTTypeFileURL as String

struct DropView: View {
    @EnvironmentObject var data: UserData
    @State private var isTargeted: Bool = false

    var body: some View {
        Text("Drag the Podfile.lock here!")
            .frame(minWidth: 250, maxWidth: 250, maxHeight: .infinity)
            .onDrop(of: [supportType], isTargeted: $isTargeted) { self.loadData(from: $0) }
    }

    private func loadData(from items: [NSItemProvider]) -> Bool {
        guard let item = items.first(where: { $0.canLoadObject(ofClass: URL.self) }) else { return false }
        DispatchQueue.global().async {
            item.loadItem(forTypeIdentifier: supportType, options: nil) { (data, error) in
                if let _ = error {
                    // TODO error
                    return
                }

                guard let urlData = data as? Data,
                    let urlString = String(data: urlData, encoding: .utf8),
                    let url = URL(string: urlString) else {
                        // TODO error
                        return
                }

                guard url.lastPathComponent == "Podfile.lock" else {
                    // TODO error
                    return
                }

                let path = url.path

                if let lock = DataReader(path: path).readData() {
                    DispatchQueue.main.async {
                        self.data.lock = lock
                    }
                }
            }
        }
        return true
    }
}

struct DropView_Previews: PreviewProvider {
    static var previews: some View {
        DropView()
    }
}
