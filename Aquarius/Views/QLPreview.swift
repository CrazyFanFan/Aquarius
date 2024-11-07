//
//  QLPreview.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/11/20.
//

import QuickLookUI
import SwiftUI

struct QLPreview: NSViewRepresentable {
    typealias NSViewType = QLPreviewView

    var url: URL

    func makeNSView(context: NSViewRepresentableContext<QLPreview>) -> QLPreviewView {
        let preview = QLPreviewView(frame: .zero, style: .compact)
        preview?.autostarts = true
        preview?.previewItem = url as QLPreviewItem
        return preview ?? QLPreviewView()
    }

    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<QLPreview>) {}
}
