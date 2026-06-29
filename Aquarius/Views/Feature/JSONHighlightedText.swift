//
//  JSONHighlightedText.swift
//  Aquarius
//
//  Created by Kkk on 2026/6/20.
//

import AppKit
import Foundation
import SwiftUI

struct JSONHighlightedText: View {
    let contents: String
    var searchText = ""
    var searchNavigationToken = 0
    var searchNavigationDirection = 1

    var body: some View {
        HighlightedTextView(
            attributedString: highlightedJSON ?? HighlightedTextStyle.plain(contents),
            searchText: searchText,
            searchNavigationToken: searchNavigationToken,
            searchNavigationDirection: searchNavigationDirection
        )
    }

    private var highlightedJSON: NSAttributedString? {
        guard let data = contents.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            return nil
        }

        let attributed = NSMutableAttributedString(
            string: contents,
            attributes: HighlightedTextStyle.baseAttributes
        )
        var tokenizer = JSONTokenizer(input: contents)

        while let token = tokenizer.nextToken() {
            applyJSONHighlight(token, to: attributed)
        }

        return attributed
    }

    private func applyJSONHighlight(_ token: JSONToken, to attributed: NSMutableAttributedString) {
        let range = NSRange(token.range, in: contents)
        attributed.addAttribute(.foregroundColor, value: token.type.color, range: range)
        if token.type.isKey {
            attributed.addAttribute(.font, value: HighlightedTextStyle.emphasizedFont, range: range)
        }
    }
}

private enum JSONTokenType {
    case bracket
    case separator
    case key
    case string
    case number
    case boolean
    case null
    case error

    var color: NSColor {
        switch self {
        case .bracket:
            .labelColor
        case .separator:
            .secondaryLabelColor
        case .key:
            NSColor.systemBlue.withAlphaComponent(0.86)
        case .string:
            NSColor.systemGreen.withAlphaComponent(0.86)
        case .number:
            NSColor.systemOrange.withAlphaComponent(0.86)
        case .boolean:
            NSColor.systemPurple.withAlphaComponent(0.86)
        case .null:
            NSColor.systemPink.withAlphaComponent(0.86)
        case .error:
            NSColor.systemRed.withAlphaComponent(0.86)
        }
    }

    var isKey: Bool {
        if case .key = self {
            true
        } else {
            false
        }
    }
}

private struct JSONToken {
    let type: JSONTokenType
    let range: Range<String.Index>
}

private struct JSONTokenizer {
    private let input: String
    private var currentIndex: String.Index

    init(input: String) {
        self.input = input
        currentIndex = input.startIndex
    }

    mutating func nextToken() -> JSONToken? {
        skipWhitespace()

        guard currentIndex < input.endIndex else {
            return nil
        }

        let startIndex = currentIndex
        let char = input[currentIndex]

        switch char {
        case "{", "}", "[", "]":
            currentIndex = input.index(after: currentIndex)
            return JSONToken(type: .bracket, range: startIndex ..< currentIndex)
        case ":", ",":
            currentIndex = input.index(after: currentIndex)
            return JSONToken(type: .separator, range: startIndex ..< currentIndex)
        case "\"":
            var token = parseString()
            if peekNextNonWhitespace() == ":" {
                token = JSONToken(type: .key, range: token.range)
            }
            return token
        case "n" where input[currentIndex...].hasPrefix("null"):
            currentIndex = input.index(currentIndex, offsetBy: 4)
            return JSONToken(type: .null, range: startIndex ..< currentIndex)
        case "t" where input[currentIndex...].hasPrefix("true"):
            currentIndex = input.index(currentIndex, offsetBy: 4)
            return JSONToken(type: .boolean, range: startIndex ..< currentIndex)
        case "f" where input[currentIndex...].hasPrefix("false"):
            currentIndex = input.index(currentIndex, offsetBy: 5)
            return JSONToken(type: .boolean, range: startIndex ..< currentIndex)
        case _ where char.isNumber || char == "-":
            return parseNumber()
        default:
            currentIndex = input.index(after: currentIndex)
            return JSONToken(type: .error, range: startIndex ..< currentIndex)
        }
    }

    private mutating func skipWhitespace() {
        while currentIndex < input.endIndex, input[currentIndex].isWhitespace {
            currentIndex = input.index(after: currentIndex)
        }
    }

    private func peekNextNonWhitespace() -> Character? {
        var index = currentIndex
        while index < input.endIndex {
            let char = input[index]
            if !char.isWhitespace {
                return char
            }
            index = input.index(after: index)
        }
        return nil
    }

    private mutating func parseString() -> JSONToken {
        let startIndex = currentIndex
        var isEscaped = false
        currentIndex = input.index(after: currentIndex)

        while currentIndex < input.endIndex {
            let char = input[currentIndex]

            if char == "\"", !isEscaped {
                currentIndex = input.index(after: currentIndex)
                return JSONToken(type: .string, range: startIndex ..< currentIndex)
            }

            isEscaped = char == "\\" && !isEscaped
            currentIndex = input.index(after: currentIndex)
        }

        return JSONToken(type: .error, range: startIndex ..< currentIndex)
    }

    private mutating func parseNumber() -> JSONToken {
        let startIndex = currentIndex
        let numberCharacters: Set<Character> = ["-", "+", "e", "E", "."]

        while currentIndex < input.endIndex {
            let char = input[currentIndex]
            guard char.isNumber || numberCharacters.contains(char) else {
                break
            }
            currentIndex = input.index(after: currentIndex)
        }

        let numberString = String(input[startIndex ..< currentIndex])
        guard Double(numberString) != nil else {
            return JSONToken(type: .error, range: startIndex ..< currentIndex)
        }

        return JSONToken(type: .number, range: startIndex ..< currentIndex)
    }
}

#Preview {
    JSONHighlightedText(contents: #"{"name":"Aquarius","enabled":true,"count":3,"items":[null]}"#)
}
