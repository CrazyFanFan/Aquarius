//
//  MyPreview.swift
//  Aquarius
//
//  Created by Crazy凡 on 2022/11/20.
//

import SwiftUI
import QuickLookUI

struct MyPreview: NSViewRepresentable {
    typealias NSViewType = QLPreviewView

    var url: URL

    func makeNSView(context: NSViewRepresentableContext<MyPreview>) -> QLPreviewView {
        let preview = QLPreviewView(frame: .zero, style: .compact)
        preview?.autostarts = true
        preview?.previewItem = url as QLPreviewItem
        return preview ?? QLPreviewView()
    }

    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<MyPreview>) {
    }
}
