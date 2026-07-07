import Foundation

/// Local progress, streak, and mood data for the home and dashboard screens.
enum PracticeProgressStore {
    private static let lastTargetKey = "lastPracticeTargetID"
    private static let moodKey = "todayMood"
    private static let practiceDatesKey = "practiceDates"
    private static let dailyGoalKey = "dailyGoalMinutes"

    /// The most recently practiced letter or sound ID.
    static var lastPracticeTargetID: String? {
        get { UserDefaults.standard.string(forKey: lastTargetKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastTargetKey) }
    }

    /// Optional mood logged from the home screen.
    static var todayMood: String? {
        get { UserDefaults.standard.string(forKey: moodKey) }
        set { UserDefaults.standard.set(newValue, forKey: moodKey) }
    }

    /// Daily practice goal in minutes for display on home.
    static var dailyGoalMinutes: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: dailyGoalKey)
            return value == 0 ? 10 : value
        }
        set { UserDefaults.standard.set(newValue, forKey: dailyGoalKey) }
    }

    /// Records that the user practiced today and updates streak metadata.
    static func recordPractice(on date: Date = .now) {
        var dates = practiceDates()
        let day = Calendar.current.startOfDay(for: date)
        if !dates.contains(day) {
            dates.append(day)
            savePracticeDates(dates)
        }
    }

    /// Returns unique practice days sorted newest first.
    static func practiceDates() -> [Date] {
        guard let rawValues = UserDefaults.standard.array(forKey: practiceDatesKey) as? [Double] else {
            return []
        }
        return rawValues.map { Date(timeIntervalSince1970: $0) }.sorted(by: >)
    }

    /// Count of consecutive days with at least one practice session ending today.
    static var currentStreak: Int {
        let calendar = Calendar.current
        let practicedDays = Set(practiceDates().map { calendar.startOfDay(for: $0) })
        guard !practicedDays.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        while practicedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// Number of sessions on a given day.
    static func sessionCount(on date: Date, totalSessions: Int, sessionDates: [Date]) -> Int {
        let day = Calendar.current.startOfDay(for: date)
        return sessionDates.filter { Calendar.current.isDate($0, inSameDayAs: day) }.count
    }

    private static func savePracticeDates(_ dates: [Date]) {
        let rawValues = dates.map(\.timeIntervalSince1970)
        UserDefaults.standard.set(rawValues, forKey: practiceDatesKey)
    }
}
