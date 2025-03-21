//
//  TreeContent.Copy.swift
//  Aquarius
//
//  Created by Crazy凡 on 2025/3/26.
//

import SwiftUI

extension TreeContent {
    @inline(__always) @ViewBuilder func _tips(
        _ title: String,
        _ message: String? = nil
    ) -> some View {
        if let message {
            _tips(title, Text(LocalizedStringKey(message))) {
                EmptyView()
            }
        } else {
            _tips(title) {
                EmptyView()
            }
        }
    }

    @ViewBuilder func _tips(
        _ title: String,
        _ message: Text? = nil,
        @ViewBuilder actions: () -> some View
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(title)).font(.title3)
                if let message {
                    message
                }

                HStack {
                    Spacer()
                    actions()
                }
            }

            Button {
                treeData.copyResult = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
        }
        .padding(5)
        .background(Color.yellow.opacity(0.75))
    }

    @MainActor @ViewBuilder func tips() -> some View {
        if let result = treeData.copyResult {
            switch result {
            case let .file(url):
                _tips(
                    "Copy success! 🎉 ",
                    Text("""
                    Tree content is too large, written to cache file, path has been copied to clipboard.
                    Cache file path: \(url.path)
                    """)
                ) {
                    Button("Open") {
                        NSWorkspace.shared.open(url)
                    }

                    Button("Show in finder") {
                        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                    }
                }
            case .string:
                _tips("Copy success! 🎉 ", "Result has been copied to clipboard.")
            case let .failure(string):
                _tips("Copy failed! 😢 ", string)
            case .cancelled:
                _tips("User cancel copy!")
            }
        }
    }
}
