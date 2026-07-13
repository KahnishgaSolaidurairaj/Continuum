import SwiftUI

/// Renders a word with selected letters emphasized in a different color.
struct HighlightedWordText: View {
    let word: String
    let highlights: [SoundHighlight]
    let font: Font
    let baseColor: Color
    let highlightColor: Color

    var body: some View {
        highlightedText
            .font(font)
            .multilineTextAlignment(.center)
    }

    private var highlightedText: Text {
        guard !highlights.isEmpty else {
            return Text(word).foregroundStyle(baseColor)
        }

        let segments = Self.segments(for: word, highlights: highlights)
        return segments.reduce(Text("")) { partial, segment in
            partial + Text(segment.text).foregroundStyle(segment.isHighlighted ? highlightColor : baseColor)
        }
    }

    /// Splits a word into highlighted and non-highlighted segments.
    private static func segments(for word: String, highlights: [SoundHighlight]) -> [(text: String, isHighlighted: Bool)] {
        var occupied = Array(repeating: false, count: word.count)
        for highlight in highlights {
            guard highlight.start >= 0, highlight.start + highlight.length <= word.count else { continue }
            for index in highlight.start..<(highlight.start + highlight.length) {
                occupied[index] = true
            }
        }

        var segments: [(text: String, isHighlighted: Bool)] = []
        var currentText = ""
        var currentHighlighted = occupied.first ?? false

        for (index, character) in word.enumerated() {
            let isHighlighted = occupied[index]
            if isHighlighted != currentHighlighted, !currentText.isEmpty {
                segments.append((currentText, currentHighlighted))
                currentText = ""
                currentHighlighted = isHighlighted
            }
            currentText.append(character)
            currentHighlighted = isHighlighted
        }

        if !currentText.isEmpty {
            segments.append((currentText, currentHighlighted))
        }

        return segments
    }
}
