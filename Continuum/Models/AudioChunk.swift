import Foundation

/// A short slice of microphone audio aligned to the shared media clock.
struct AudioChunk: Codable, Sendable {
    let timestamp: TimeInterval
    let samples: [Float]
    let sampleRate: Double
}
