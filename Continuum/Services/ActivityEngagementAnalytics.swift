import Foundation

/// Aggregates stored activity engagement records for dashboard and home summaries.
enum ActivityEngagementAnalytics {
    /// Returns all engagement visits on the given calendar day.
    /// - Parameters:
    ///   - date: The day to filter by.
    ///   - records: Stored engagement records.
    /// - Returns: Visits that ended on the given day.
    static func engagements(on date: Date, records: [ActivityEngagementRecord]) -> [ActivityEngagementRecord] {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.endedAt, inSameDayAs: date) }
    }

    /// Sums foreground seconds for one activity on a given day.
    /// - Parameters:
    ///   - date: The day to filter by.
    ///   - activity: The practice game to total.
    ///   - records: Stored engagement records.
    /// - Returns: Total seconds spent in that activity.
    static func totalDuration(
        on date: Date,
        activity: PracticeActivity,
        records: [ActivityEngagementRecord]
    ) -> TimeInterval {
        engagements(on: date, records: records)
            .filter { $0.activityRawValue == activity.rawValue }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    /// Returns total seconds per practice game for a given day.
    /// - Parameters:
    ///   - date: The day to filter by.
    ///   - records: Stored engagement records.
    /// - Returns: Durations keyed by practice activity.
    static func durationsByActivity(
        on date: Date,
        records: [ActivityEngagementRecord]
    ) -> [PracticeActivity: TimeInterval] {
        Dictionary(
            uniqueKeysWithValues: PracticeActivity.allCases.map { activity in
                (activity, totalDuration(on: date, activity: activity, records: records))
            }
        )
    }

    /// Returns the most recent mood logged today from a completed activity.
    /// - Parameter records: Stored engagement records.
    /// - Returns: The latest non-nil mood label for today, if any.
    static func latestMoodToday(records: [ActivityEngagementRecord]) -> String? {
        engagements(on: .now, records: records)
            .sorted { $0.endedAt > $1.endedAt }
            .compactMap(\.mood)
            .first
    }

    /// Formats a duration in seconds as a kid-friendly minutes label.
    /// - Parameter seconds: Duration in seconds.
    /// - Returns: A short minutes string such as "3 min".
    static func formattedMinutes(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int((seconds / 60.0).rounded()))
        return seconds < 30 ? "< 1 min" : "\(minutes) min"
    }
}
