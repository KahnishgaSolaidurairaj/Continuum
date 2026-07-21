import Foundation

/// Aggregated audio measurements from a pronunciation attempt.
struct AudioFeatures: Codable, Sendable {
    let duration: TimeInterval
    let rmsEnergy: Float
    let peakEnergy: Float
    let zeroCrossingRate: Float
    let voicedEnergyRatio: Float
    let burstPeak: Float
    let sampleRate: Double
}

/// Severity level for a coaching hint.
enum CoachingSeverity: String, Codable, Sendable {
    case good
    case warning
    case critical
}

/// A single piece of live or post-attempt feedback.
struct CoachingMessage: Codable, Sendable, Identifiable {
    let id: UUID
    let text: String
    let severity: CoachingSeverity

    init(id: UUID = UUID(), text: String, severity: CoachingSeverity) {
        self.id = id
        self.text = text
        self.severity = severity
    }
}

/// How an attempt was scored.
enum ScoringMethod: String, Codable, Sendable {
    case rules
    case hybridFallback
    case speechRecognition
}

/// Final scoring output for one attempt.
struct PronunciationScore: Codable, Sendable {
    let correctness: Int
    let confidence: Double
    let messages: [CoachingMessage]
    var scoringMethod: ScoringMethod = .rules

    /// Short label shown under the score card.
    var scoringMethodLabel: String {
        switch scoringMethod {
        case .rules:
            return "Scored with rules"
        case .hybridFallback:
            return "Rejected before scoring"
        case .speechRecognition:
            return "Recognized your spoken word"
        }
    }
}
