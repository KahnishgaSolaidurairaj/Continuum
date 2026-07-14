import Foundation
import SwiftData

/// Persisted record of one practice activity visit with time spent and optional mood.
@Model
final class ActivityEngagementRecord {
    var id: UUID
    var activityRawValue: String
    var targetSoundID: String
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: Double
    var mood: String?

    init(
        id: UUID = UUID(),
        activityRawValue: String,
        targetSoundID: String,
        startedAt: Date,
        endedAt: Date,
        durationSeconds: Double,
        mood: String? = nil
    ) {
        self.id = id
        self.activityRawValue = activityRawValue
        self.targetSoundID = targetSoundID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.mood = mood
    }

    /// The practice activity associated with this visit.
    var activity: PracticeActivity? {
        PracticeActivity(rawValue: activityRawValue)
    }
}
