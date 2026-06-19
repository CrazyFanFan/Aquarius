//
//  HighlightedTextView.swift
//  Aquarius
//
//  Created by Kkk on 2026/6/20.
//

import AppKit
import SwiftUI

struct HighlightedTextView: NSViewRepresentable {
    let attributedString: NSAttributedString
    let wrapsLines: Bool

    init(attributedString: NSAttributedString, wrapsLines: Bool = true) {
        self.attributedString = attributedString
        self.wrapsLines = wrapsLines
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context _: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.drawsBackground = false
        textView.allowsUndo = false
        textView.textContainerInset = .zero
        textView.minSize = .zero
        textView.isVerticallyResizable = true

        scrollView.documentView = textView
        configureWrapping(for: textView, in: scrollView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        configureWrapping(for: textView, in: scrollView)

        guard context.coordinator.renderedAttributedString?.isEqual(to: attributedString) != true else {
            return
        }

        let selectedRanges = textView.selectedRanges
        textView.textStorage?.setAttributedString(attributedString)
        textView.selectedRanges = selectedRanges.filter { range in
            let nsRange = range.rangeValue
            return nsRange.location != NSNotFound &&
                nsRange.location + nsRange.length <= attributedString.length
        }
        context.coordinator.renderedAttributedString = attributedString
    }

    private func configureWrapping(for textView: NSTextView, in scrollView: NSScrollView) {
        let wrappingWidth = max(scrollView.contentSize.width, 1)

        scrollView.hasHorizontalScroller = !wrapsLines
        textView.isHorizontallyResizable = !wrapsLines
        textView.autoresizingMask = wrapsLines ? [.width] : []
        textView.textContainer?.widthTracksTextView = wrapsLines

        textView.maxSize = NSSize(
            width: wrapsLines ? wrappingWidth : CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.containerSize = NSSize(
            width: wrapsLines ? wrappingWidth : CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
    }

    final class Coordinator {
        var renderedAttributedString: NSAttributedString?
    }
}

enum HighlightedTextStyle {
    static var font: NSFont {
        NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )
    }

    static var emphasizedFont: NSFont {
        NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .semibold
        )
    }

    static var baseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: font,
            .foregroundColor: NSColor.labelColor,
        ]
    }

    static func plain(_ contents: String) -> NSAttributedString {
        NSAttributedString(string: contents, attributes: baseAttributes)
    }
}
