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
    let searchText: String
    let searchNavigationToken: Int
    let searchNavigationDirection: Int

    init(
        attributedString: NSAttributedString,
        wrapsLines: Bool = true,
        searchText: String = "",
        searchNavigationToken: Int = 0,
        searchNavigationDirection: Int = 1
    ) {
        self.attributedString = attributedString
        self.wrapsLines = wrapsLines
        self.searchText = searchText
        self.searchNavigationToken = searchNavigationToken
        self.searchNavigationDirection = searchNavigationDirection
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

        let didUpdateContent = context.coordinator.renderedAttributedString?.isEqual(to: attributedString) != true
        if didUpdateContent {
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.setAttributedString(attributedString)
            textView.selectedRanges = selectedRanges.filter { range in
                let nsRange = range.rangeValue
                return nsRange.location != NSNotFound &&
                    nsRange.location + nsRange.length <= attributedString.length
            }
            context.coordinator.renderedAttributedString = attributedString
        }

        let didUpdateSearch = context.coordinator.searchText != searchText
        let didNavigate = context.coordinator.searchNavigationToken != searchNavigationToken
        if didUpdateContent || didUpdateSearch || didNavigate {
            applySearch(
                in: textView,
                coordinator: context.coordinator,
                navigates: didNavigate && !didUpdateSearch,
                direction: searchNavigationDirection
            )
        }
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
        var searchText = ""
        var searchNavigationToken = 0
        var selectedMatchIndex = 0
        var matchRanges: [NSRange] = []
    }
}

private extension HighlightedTextView {
    static var searchHighlightColor: NSColor {
        NSColor.systemYellow.withAlphaComponent(0.35)
    }

    static var selectedSearchHighlightColor: NSColor {
        NSColor.systemOrange.withAlphaComponent(0.45)
    }

    func applySearch(in textView: NSTextView, coordinator: Coordinator, navigates: Bool, direction: Int) {
        let fullRange = NSRange(location: 0, length: attributedString.length)
        textView.textStorage?.removeAttribute(.backgroundColor, range: fullRange)

        let didClearSearch = !coordinator.searchText.isEmpty && searchText.isEmpty
        coordinator.searchText = searchText
        coordinator.searchNavigationToken = searchNavigationToken
        coordinator.matchRanges = searchRanges(in: textView.string, searchText: searchText)

        guard !coordinator.matchRanges.isEmpty else {
            coordinator.selectedMatchIndex = 0
            if didClearSearch {
                textView.setSelectedRange(NSRange(location: 0, length: 0))
            }
            return
        }

        if navigates {
            let offset = direction >= 0 ? 1 : -1
            coordinator.selectedMatchIndex = (
                coordinator.selectedMatchIndex + offset + coordinator.matchRanges.count
            ) % coordinator.matchRanges.count
        } else {
            coordinator.selectedMatchIndex = 0
        }

        for range in coordinator.matchRanges {
            textView.textStorage?.addAttribute(
                .backgroundColor,
                value: Self.searchHighlightColor,
                range: range
            )
        }

        let selectedRange = coordinator.matchRanges[coordinator.selectedMatchIndex]
        textView.textStorage?.addAttribute(
            .backgroundColor,
            value: Self.selectedSearchHighlightColor,
            range: selectedRange
        )
        textView.setSelectedRange(selectedRange)
        textView.scrollRangeToVisible(selectedRange)
    }

    func searchRanges(in string: String, searchText: String) -> [NSRange] {
        guard !searchText.isEmpty else {
            return []
        }

        var ranges: [NSRange] = []
        var start = string.startIndex
        while start < string.endIndex,
              let range = string[start...].range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) {
            ranges.append(NSRange(range, in: string))
            start = range.upperBound < string.endIndex ? range.upperBound : string.endIndex
        }
        return ranges
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
