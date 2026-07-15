import Foundation
import SwiftData

/// Persisted record of one pronunciation practice attempt.
@Model
final class PracticeSessionRecord {
    var id: UUID
    var targetPhoneme: String
    var targetSoundID: String?
    var timestamp: Date
    var correctness: Int
    var confidence: Double
    var coachingSummary: String
    var audioFeaturesJSON: Data
    var ruleResultsJSON: Data

    init(
        id: UUID = UUID(),
        targetPhoneme: String,
        targetSoundID: String? = nil,
        timestamp: Date = .now,
        correctness: Int,
        confidence: Double,
        coachingSummary: String,
        audioFeaturesJSON: Data,
        ruleResultsJSON: Data
    ) {
        self.id = id
        self.targetPhoneme = targetPhoneme
        self.targetSoundID = targetSoundID
        self.timestamp = timestamp
        self.correctness = correctness
        self.confidence = confidence
        self.coachingSummary = coachingSummary
        self.audioFeaturesJSON = audioFeaturesJSON
        self.ruleResultsJSON = ruleResultsJSON
    }
}

/// Lightweight profile summarizing recurring pronunciation issues.
struct UserPronunciationProfile: Codable, Sendable {
    var weakAirflowCount: Int = 0
    var weakVoicingCount: Int = 0
    var shortDurationCount: Int = 0

    /// Returns personalized practice tips based on recurring issues.
    /// - Returns: Coaching messages tailored to observed patterns.
    func personalizedTips() -> [CoachingMessage] {
        var tips: [CoachingMessage] = []

        if weakAirflowCount >= 3 {
            tips.append(CoachingMessage(
                text: "Try stronger, steady airflow for fricatives like /f/ and /v/.",
                severity: .warning
            ))
        }
        if weakVoicingCount >= 3 {
            tips.append(CoachingMessage(
                text: "Place a hand on your throat and feel vibration for voiced sounds.",
                severity: .warning
            ))
        }
        if shortDurationCount >= 3 {
            tips.append(CoachingMessage(
                text: "Hold each sound slightly longer before stopping.",
                severity: .warning
            ))
        }

        return tips
    }
}

/// Reads and writes the local user pronunciation profile.
enum UserProfileStore {
    private static let fileName = "user_pronunciation_profile.json"

    /// Loads the saved profile or returns a fresh default.
    /// - Returns: The stored pronunciation profile.
    static func load() -> UserPronunciationProfile {
        let url = profileURL()
        guard
            let data = try? Data(contentsOf: url),
            let profile = try? JSONDecoder().decode(UserPronunciationProfile.self, from: data)
        else {
            return UserPronunciationProfile()
        }
        return profile
    }

    /// Persists the pronunciation profile to disk.
    /// - Parameter profile: The profile to save.
    static func save(_ profile: UserPronunciationProfile) {
        let url = profileURL()
        guard let data = try? JSONEncoder().encode(profile) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func profileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }
}
