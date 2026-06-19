//
//  TreeContent.Copy.swift
//  Aquarius
//
//  Created by Crazy凡 on 2025/3/26.
//

import SwiftUI

extension TreeContent {
    private static let tipsDismissDelay: UInt64 = 3_000_000_000

    private static func tipsBackgroundColor(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            Color(red: 0.46, green: 0.32, blue: 0.10).opacity(0.9)
        default:
            Color(red: 1.0, green: 0.86, blue: 0.28).opacity(0.42)
        }
    }

    @inline(__always) @ViewBuilder func bannerTip(
        _ title: String,
        _ message: String? = nil
    ) -> some View {
        if let message {
            bannerTip(title, Text(LocalizedStringKey(message))) {
                EmptyView()
            }
        } else {
            bannerTip(title) {
                EmptyView()
            }
        }
    }

    @ViewBuilder func bannerTip(
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
        .background(Self.tipsBackgroundColor(for: colorScheme))
    }

    @ViewBuilder func floatingTips() -> some View {
        switch treeData.copyResult {
        case .some(.string):
            floatingTip("Copy success! 🎉 ")
        case .some(.cancelled):
            floatingTip("Copy cancelled")
        default:
            EmptyView()
        }
    }

    @ViewBuilder func floatingTip(_ title: String) -> some View {
        Text(LocalizedStringKey(title))
            .font(.callout)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Self.tipsBackgroundColor(for: colorScheme), in: Capsule())
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 8, y: 3)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(1)
            .task(id: treeData.copyResult) {
                try? await Task.sleep(nanoseconds: Self.tipsDismissDelay)
                switch treeData.copyResult {
                case .some(.string), .some(.cancelled):
                    treeData.copyResult = nil
                default:
                    break
                }
            }
    }

    @MainActor @ViewBuilder func blockingTips() -> some View {
        if let result = treeData.copyResult {
            switch result {
            case let .file(url):
                let message = String(
                    format: String(localized: "Tree content is too large, written to cache file, path has been copied to clipboard.\nCache file path: %@"),
                    url.path
                )
                bannerTip(
                    "Saved to Cache File",
                    Text(LocalizedStringKey(message))
                ) {
                    Button("Open") {
                        NSWorkspace.shared.open(url)
                    }

                    Button("Show in finder") {
                        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                    }
                }
            case let .failure(string):
                bannerTip("Copy Failed", string)
            default:
                EmptyView()
            }
        }
    }
}
