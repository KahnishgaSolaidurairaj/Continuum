import Foundation
import SwiftData

/// Tracks foreground time in a practice activity and persists engagement on exit.
@Observable
final class ActivitySessionTracker {
    private var startedAt: Date?
    private var activity: PracticeActivity?
    private var targetSoundID: String?
    private var accumulatedSeconds: TimeInterval = 0
    private var lastResumeAt: Date?
    private var isPaused = false
    private var isActive = false
    private var ended = false

    /// Whether a visit is in progress and has not been saved yet.
    var hasActiveSession: Bool {
        isActive && !ended
    }

    /// Begins timing a new activity visit.
    /// - Parameters:
    ///   - activity: The selected practice game.
    ///   - target: The sound being practiced.
    func start(activity: PracticeActivity, target: PracticeTarget) {
        guard !isActive else { return }

        startedAt = .now
        lastResumeAt = .now
        self.activity = activity
        targetSoundID = target.id
        accumulatedSeconds = 0
        isPaused = false
        isActive = true
        ended = false
    }

    /// Pauses the timer when the app moves to the background.
    func pause() {
        guard isActive, !isPaused, let lastResumeAt else { return }
        accumulatedSeconds += Date.now.timeIntervalSince(lastResumeAt)
        isPaused = true
        self.lastResumeAt = nil
    }

    /// Resumes the timer when the app returns to the foreground.
    func resume() {
        guard isActive, isPaused else { return }
        lastResumeAt = .now
        isPaused = false
    }

    /// Ends the visit, saves engagement data, and clears active state.
    /// - Parameters:
    ///   - mood: Optional mood selected at activity end.
    ///   - modelContext: SwiftData context for persistence.
    func end(mood: String?, modelContext: ModelContext) {
        guard isActive, !ended else { return }
        ended = true
        persist(mood: mood, modelContext: modelContext)
        reset()
    }

    /// Saves the visit without mood when the child leaves without tapping Done.
    /// - Parameter modelContext: SwiftData context for persistence.
    func abandon(modelContext: ModelContext) {
        end(mood: nil, modelContext: modelContext)
    }

    private func currentDuration() -> TimeInterval {
        var total = accumulatedSeconds
        if let lastResumeAt, !isPaused {
            total += Date.now.timeIntervalSince(lastResumeAt)
        }
        return max(total, 0)
    }

    private func persist(mood: String?, modelContext: ModelContext) {
        guard let activity, let targetSoundID, let startedAt else { return }

        let endedAt = Date.now
        let record = ActivityEngagementRecord(
            activityRawValue: activity.rawValue,
            targetSoundID: targetSoundID,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: currentDuration(),
            mood: mood
        )
        modelContext.insert(record)

        do {
            try modelContext.save()
            PracticeProgressStore.recordPractice(on: startedAt)
        } catch {
            print("Failed to save activity engagement: \(error.localizedDescription)")
        }
    }

    private func reset() {
        isActive = false
        startedAt = nil
        activity = nil
        targetSoundID = nil
        accumulatedSeconds = 0
        lastResumeAt = nil
        isPaused = false
    }
}
