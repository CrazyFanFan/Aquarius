//
//  PodspecView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2021/12/4.
//

import SwiftUI

struct PodspecView: View {
    @Environment(\.presentationMode) var presentationMode

    var podspec: TreeData.PodspecInfo?

    var body: some View {
        Group {
            switch podspec {
            case .none:
                Text("Todo")

            case .local(let spec):
                localView(for: spec)

            case .repo:
                Text("Todo")

            case .git:
                Text("Todo")
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .contentShape(RoundedRectangle(cornerRadius: 5))
        .frame(
            minWidth: 700,
            maxWidth: 700,
            minHeight: 350,
            maxHeight: 700,
            alignment: .center
        )
    }

    private func contentView(_ content: String?) -> some View {
        if let content = content {
            return Text(content)
        } else {
            return Text("Load podspec content faile.")
        }
    }

    private func localView(for spec: TreeData.LocalSpec) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(spec.podspecFileURL.path)
            }

            Divider()

            ScrollView {
                HStack {
                    Text(spec.podspecContent)
                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Copy path") {
                    Pasteboard.write(spec.podspecFileURL.path)
                }
                Button("Copy content") {
                    Pasteboard.write(spec.podspecFileURL.path)
                }
                Button("Show in finder") {
                    NSWorkspace.shared.selectFile(spec.podspecFileURL.path, inFileViewerRootedAtPath: "")
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct PodspecView_Previews: PreviewProvider {
    static var previews: some View {
        PodspecView(
            podspec: .local(.init(podspecFileURL: URL(fileURLWithPath: "/tmp"), podspecContent: "Test content")))
    }
}
