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
    let searchText: String
    let searchNavigationToken: Int
    let searchNavigationDirection: Int

    init(
        attributedString: NSAttributedString,
        searchText: String = "",
        searchNavigationToken: Int = 0,
        searchNavigationDirection: Int = 1
    ) {
        self.attributedString = attributedString
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
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.wantsLayer = true
        scrollView.layer?.masksToBounds = true
        scrollView.contentView.wantsLayer = true
        scrollView.contentView.layer?.masksToBounds = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.drawsBackground = false
        textView.allowsUndo = false
        textView.textContainerInset = .zero
        textView.minSize = .zero
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        let lineNumberRuler = LineNumberRulerView(textView: textView)
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.verticalRulerView = lineNumberRuler
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

        (scrollView.verticalRulerView as? LineNumberRulerView)?.refresh()
    }

    private func configureWrapping(for textView: NSTextView, in scrollView: NSScrollView) {
        let wrappingWidth = max(scrollView.contentSize.width, 1)

        textView.maxSize = NSSize(width: wrappingWidth, height: CGFloat.greatestFiniteMagnitude)
        textView.frame.size.width = wrappingWidth
        textView.textContainer?.containerSize = NSSize(
            width: wrappingWidth,
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

private final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    private var textAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
    }

    private var backgroundColor: NSColor {
        NSColor.secondaryLabelColor.withAlphaComponent(0.07)
    }

    init(textView: NSTextView) {
        self.textView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        updateRuleThickness()
        observeScrollBounds()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func refresh() {
        updateRuleThickness()
        needsDisplay = true
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        backgroundColor.setFill()
        bounds.fill()

        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return
        }

        let text = textView.string as NSString
        guard text.length > 0 else {
            drawLineNumber(1, lineRect: textView.visibleRect, in: textView)
            return
        }

        layoutManager.ensureLayout(for: textContainer)

        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textContainer)
        guard visibleGlyphRange.location != NSNotFound else {
            return
        }

        let visibleCharacterRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)
        let visibleLineRange = text.lineRange(for: visibleCharacterRange)
        var lineStart = visibleLineRange.location
        var lineNumber = text.lineNumber(at: lineStart)

        while lineStart < NSMaxRange(visibleLineRange), lineStart < text.length {
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: lineStart)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            drawLineNumber(lineNumber, lineRect: lineRect, in: textView)

            var nextLineStart = 0
            text.getLineStart(nil, end: &nextLineStart, contentsEnd: nil, for: NSRange(location: lineStart, length: 0))
            guard nextLineStart > lineStart else {
                break
            }

            lineStart = nextLineStart
            lineNumber += 1
        }
    }

    private func drawLineNumber(_ lineNumber: Int, lineRect: NSRect, in textView: NSTextView) {
        let label = "\(lineNumber)" as NSString
        let labelSize = label.size(withAttributes: textAttributes)
        let textContainerOrigin = textView.textContainerOrigin
        let lineOriginInTextView = NSPoint(
            x: textContainerOrigin.x + lineRect.minX,
            y: textContainerOrigin.y + lineRect.minY
        )
        let lineOrigin = convert(lineOriginInTextView, from: textView)
        let labelX = max(2, ruleThickness - labelSize.width - 7)
        let labelY = lineOrigin.y + max(0, (lineRect.height - labelSize.height) / 2)

        label.draw(
            at: NSPoint(x: labelX, y: labelY),
            withAttributes: textAttributes
        )
    }

    private func updateRuleThickness() {
        let lineCount = max(1, textView?.string.lineCount ?? 1)
        let digits = max(2, String(lineCount).count)
        let sampleLabel = String(repeating: "8", count: digits) as NSString
        let desiredThickness = ceil(sampleLabel.size(withAttributes: textAttributes).width + 14)

        if abs(ruleThickness - desiredThickness) > 0.5 {
            ruleThickness = desiredThickness
        }
    }

    private func observeScrollBounds() {
        guard let contentView = scrollView?.contentView else {
            return
        }

        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollBoundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: contentView
        )
    }

    @objc private func scrollBoundsDidChange(_: Notification) {
        needsDisplay = true
    }
}

private extension NSString {
    func lineNumber(at location: Int) -> Int {
        guard location > 0 else {
            return 1
        }

        var lineNumber = 1
        let prefixRange = NSRange(location: 0, length: min(location, length))
        enumerateSubstrings(in: prefixRange, options: [.byLines, .substringNotRequired]) { _, _, enclosingRange, _ in
            if NSMaxRange(enclosingRange) <= location {
                lineNumber += 1
            }
        }
        return lineNumber
    }
}

private extension String {
    var lineCount: Int {
        reduce(1) { count, character in
            character == "\n" ? count + 1 : count
        }
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
