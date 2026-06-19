//
//  RubyDSLHighlightedText.swift
//  Aquarius
//
//  Created by Kkk on 2026/6/20.
//

import AppKit
import SwiftUI

struct RubyDSLHighlightedText: View {
    let contents: String

    var body: some View {
        HighlightedTextView(attributedString: highlightedRubyDSL)
    }

    private var highlightedRubyDSL: NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: contents,
            attributes: HighlightedTextStyle.baseAttributes
        )
        var tokenizer = RubyDSLTokenizer(input: contents)

        while let token = tokenizer.nextToken() {
            applyRubyDSLHighlight(token, to: attributed)
        }

        return attributed
    }

    private func applyRubyDSLHighlight(_ token: RubyDSLToken, to attributed: NSMutableAttributedString) {
        let range = NSRange(token.range, in: contents)
        attributed.addAttribute(.foregroundColor, value: token.type.color, range: range)
        if token.type.isEmphasized {
            attributed.addAttribute(.font, value: HighlightedTextStyle.emphasizedFont, range: range)
        }
    }
}

private enum RubyDSLTokenType {
    case comment
    case string
    case symbol
    case keyword
    case literal
    case property
    case method
    case number
    case operatorToken
    case separator

    var color: NSColor {
        switch self {
        case .comment:
            .secondaryLabelColor
        case .string:
            NSColor.systemGreen.withAlphaComponent(0.86)
        case .symbol:
            NSColor.systemPink.withAlphaComponent(0.86)
        case .keyword:
            NSColor.systemPurple.withAlphaComponent(0.86)
        case .literal:
            NSColor.systemPurple.withAlphaComponent(0.86)
        case .property:
            NSColor.systemBlue.withAlphaComponent(0.86)
        case .method:
            NSColor.systemBlue.withAlphaComponent(0.86)
        case .number:
            NSColor.systemOrange.withAlphaComponent(0.86)
        case .operatorToken:
            .secondaryLabelColor
        case .separator:
            .labelColor
        }
    }

    var isEmphasized: Bool {
        switch self {
        case .property, .method:
            true
        default:
            false
        }
    }
}

private struct RubyDSLToken {
    let type: RubyDSLTokenType
    let range: Range<String.Index>
}

private struct RubyDSLTokenizer {
    private static let keywords: Set<String> = [
        "begin", "case", "class", "def", "do", "else", "elsif", "end",
        "ensure", "if", "module", "rescue", "return", "then", "unless",
        "until", "when", "while", "yield",
    ]

    private static let literals: Set<String> = [
        "false", "nil", "true",
    ]

    private static let commonMethods: Set<String> = [
        "author", "authors", "compiler_flags", "dependency", "description",
        "exclude_files", "framework", "frameworks", "homepage", "ios",
        "license", "name", "osx", "platform", "pod_target_xcconfig",
        "prefix_header_contents", "prepare_command", "preserve_paths",
        "requires_arc", "resource", "resources", "screenshots", "source",
        "source_files", "static_framework", "subspec", "summary", "swift_version",
        "test_spec", "tvos", "vendored_frameworks", "vendored_libraries",
        "version", "visionos", "watchos", "xcconfig",
    ]

    private let input: String
    private var currentIndex: String.Index

    init(input: String) {
        self.input = input
        currentIndex = input.startIndex
    }

    mutating func nextToken() -> RubyDSLToken? {
        skipWhitespace()

        guard currentIndex < input.endIndex else {
            return nil
        }

        let startIndex = currentIndex
        let char = input[currentIndex]

        switch char {
        case "#":
            return parseComment()
        case "\"", "'":
            return parseString(quote: char)
        case ":":
            return parseSymbol()
        case "0" ... "9":
            return parseNumber()
        case "(", ")", "[", "]", "{", "}", ",", ".":
            currentIndex = input.index(after: currentIndex)
            return RubyDSLToken(type: .separator, range: startIndex ..< currentIndex)
        case "=", ">", "<", "+", "-", "*", "/", "|", "&":
            return parseOperator()
        default:
            guard isIdentifierStart(char) else {
                currentIndex = input.index(after: currentIndex)
                return RubyDSLToken(type: .separator, range: startIndex ..< currentIndex)
            }
            return parseIdentifier()
        }
    }

    private mutating func skipWhitespace() {
        while currentIndex < input.endIndex, input[currentIndex].isWhitespace {
            currentIndex = input.index(after: currentIndex)
        }
    }

    private mutating func parseComment() -> RubyDSLToken {
        let startIndex = currentIndex

        while currentIndex < input.endIndex, input[currentIndex].isNewline == false {
            currentIndex = input.index(after: currentIndex)
        }

        return RubyDSLToken(type: .comment, range: startIndex ..< currentIndex)
    }

    private mutating func parseString(quote: Character) -> RubyDSLToken {
        let startIndex = currentIndex
        var isEscaped = false
        currentIndex = input.index(after: currentIndex)

        while currentIndex < input.endIndex {
            let char = input[currentIndex]

            if char == quote, !isEscaped {
                currentIndex = input.index(after: currentIndex)
                return RubyDSLToken(type: .string, range: startIndex ..< currentIndex)
            }

            isEscaped = char == "\\" && !isEscaped
            currentIndex = input.index(after: currentIndex)
        }

        return RubyDSLToken(type: .string, range: startIndex ..< currentIndex)
    }

    private mutating func parseSymbol() -> RubyDSLToken {
        let startIndex = currentIndex
        currentIndex = input.index(after: currentIndex)

        if currentIndex < input.endIndex, input[currentIndex] == ":" {
            currentIndex = input.index(after: currentIndex)
            return RubyDSLToken(type: .operatorToken, range: startIndex ..< currentIndex)
        }

        guard currentIndex < input.endIndex, isIdentifierStart(input[currentIndex]) else {
            return RubyDSLToken(type: .operatorToken, range: startIndex ..< currentIndex)
        }

        consumeIdentifierBody()
        return RubyDSLToken(type: .symbol, range: startIndex ..< currentIndex)
    }

    private mutating func parseNumber() -> RubyDSLToken {
        let startIndex = currentIndex

        while currentIndex < input.endIndex {
            let char = input[currentIndex]
            guard char.isNumber || char == "." || char == "_" else {
                break
            }
            currentIndex = input.index(after: currentIndex)
        }

        return RubyDSLToken(type: .number, range: startIndex ..< currentIndex)
    }

    private mutating func parseOperator() -> RubyDSLToken {
        let startIndex = currentIndex

        while currentIndex < input.endIndex {
            let char = input[currentIndex]
            guard "=><+-*/|&".contains(char) else {
                break
            }
            currentIndex = input.index(after: currentIndex)
        }

        return RubyDSLToken(type: .operatorToken, range: startIndex ..< currentIndex)
    }

    private mutating func parseIdentifier() -> RubyDSLToken {
        let startIndex = currentIndex
        consumeIdentifierBody()

        var containsDot = false
        while currentIndex < input.endIndex, input[currentIndex] == "." {
            let dotIndex = currentIndex
            let nextIndex = input.index(after: currentIndex)
            guard nextIndex < input.endIndex, isIdentifierStart(input[nextIndex]) else {
                currentIndex = dotIndex
                break
            }

            containsDot = true
            currentIndex = nextIndex
            consumeIdentifierBody()
        }

        let identifier = String(input[startIndex ..< currentIndex])
        let type: RubyDSLTokenType = if containsDot {
            .property
        } else if Self.keywords.contains(identifier) {
            .keyword
        } else if Self.literals.contains(identifier) {
            .literal
        } else if Self.commonMethods.contains(identifier) {
            .method
        } else {
            .separator
        }

        return RubyDSLToken(type: type, range: startIndex ..< currentIndex)
    }

    private mutating func consumeIdentifierBody() {
        while currentIndex < input.endIndex, isIdentifierBody(input[currentIndex]) {
            currentIndex = input.index(after: currentIndex)
        }
    }

    private func isIdentifierStart(_ char: Character) -> Bool {
        char.isLetter || char == "_"
    }

    private func isIdentifierBody(_ char: Character) -> Bool {
        char.isLetter || char.isNumber || char == "_" || char == "?" || char == "!"
    }
}

#Preview {
    RubyDSLHighlightedText(contents: """
    Pod::Spec.new do |s|
      s.name = "Aquarius"
      s.version = "1.0.0"
      s.platform = :ios, "13.0"
      s.source_files = "Sources/**/*.{swift,h,m}"
      s.dependency "Alamofire"
      s.requires_arc = true
      # This is a podspec comment.
    end
    """)
}
