import Foundation

/// Scores a spoken word attempt using speech-recognition transcript and confidence.
enum WordRecognitionScorer {
    /// Input values required to score one word attempt.
    struct Input: Sendable {
        let targetWord: String
        let transcript: String
        let confidence: Double
    }

    /// Scores whether the learner said the target word.
    /// - Parameter input: Target word, heard transcript, and average confidence.
    /// - Returns: Correctness percentage and coaching messages.
    static func score(_ input: Input) -> PronunciationScore {
        let normalizedTarget = normalize(input.targetWord)
        let heardToken = primaryToken(from: input.transcript)
        let normalizedHeard = normalize(heardToken)
        let boundedConfidence = min(1, max(0, input.confidence))

        if normalizedHeard.isEmpty {
            return PronunciationScore(
                correctness: 0,
                confidence: boundedConfidence,
                messages: [
                    CoachingMessage(
                        text: "No speech heard — try again and say **\(input.targetWord)** clearly.",
                        severity: .critical
                    )
                ],
                scoringMethod: .speechRecognition
            )
        }

        if matchesTarget(normalizedTarget, heard: normalizedHeard) {
            let correctness = Int((boundedConfidence * 100).rounded())
            return PronunciationScore(
                correctness: correctness,
                confidence: boundedConfidence,
                messages: [
                    CoachingMessage(
                        text: "Great — you said **\(input.targetWord)**.",
                        severity: .good
                    )
                ],
                scoringMethod: .speechRecognition
            )
        }

        let correctness = min(15, Int((boundedConfidence * 20).rounded()))
        return PronunciationScore(
            correctness: correctness,
            confidence: boundedConfidence,
            messages: [
                CoachingMessage(
                    text: "Try again — say **\(input.targetWord)**, not \"\(heardToken)\".",
                    severity: .warning
                )
            ],
            scoringMethod: .speechRecognition
        )
    }

    /// Normalizes a word for case-insensitive comparison.
    /// - Parameter text: Raw transcript or target text.
    /// - Returns: Lowercased text without punctuation or extra whitespace.
    static func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = trimmed.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(String.UnicodeScalarView(stripped)).lowercased()
    }

    /// Returns whether the heard word matches the target, allowing one edit for close misses.
    /// - Parameters:
    ///   - target: Normalized target word.
    ///   - heard: Normalized heard word.
    /// - Returns: Whether the attempt should count as correct.
    static func matchesTarget(_ target: String, heard: String) -> Bool {
        guard !target.isEmpty, !heard.isEmpty else { return false }
        if target == heard {
            return true
        }
        return editDistance(target, heard) <= 1
    }

    private static func primaryToken(from transcript: String) -> String {
        transcript
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .first ?? transcript
    }

    private static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        var distances = Array(repeating: Array(repeating: 0, count: right.count + 1), count: left.count + 1)

        for rowIndex in 0...left.count {
            distances[rowIndex][0] = rowIndex
        }
        for columnIndex in 0...right.count {
            distances[0][columnIndex] = columnIndex
        }

        for rowIndex in 1...left.count {
            for columnIndex in 1...right.count {
                let substitutionCost = left[rowIndex - 1] == right[columnIndex - 1] ? 0 : 1
                distances[rowIndex][columnIndex] = min(
                    distances[rowIndex - 1][columnIndex] + 1,
                    distances[rowIndex][columnIndex - 1] + 1,
                    distances[rowIndex - 1][columnIndex - 1] + substitutionCost
                )
            }
        }

        return distances[left.count][right.count]
    }
}
