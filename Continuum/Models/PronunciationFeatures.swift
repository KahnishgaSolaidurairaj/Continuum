import Foundation

/// Aggregated visual measurements from a pronunciation attempt.
struct VisualFeatures: Codable, Sendable {
    let maximumJawOpen: Float
    let averageJawOpen: Float
    let maximumMouthClose: Float
    let averageMouthClose: Float
    let lipRounding: Float
    let lipSpread: Float
    let mouthSymmetry: Float
    let headMovement: Float
    let tongueVisibility: Float
    let motionSpeed: Float
    let frameCount: Int
}

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

/// Final scoring output for one attempt.
struct PronunciationScore: Codable, Sendable {
    let correctness: Int
    let confidence: Double
    let messages: [CoachingMessage]
}
