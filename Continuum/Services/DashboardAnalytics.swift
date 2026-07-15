import Foundation

/// Sound group filter for dashboard speech accuracy charts.
enum SoundGroupFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case vowel
    case consonant
    case vowelTeam

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .vowel: return "Vowel"
        case .consonant: return "Consonant"
        case .vowelTeam: return "Vowel Team"
        }
    }

    var category: PracticeSoundCategory? {
        switch self {
        case .all: return nil
        case .vowel: return .vowel
        case .consonant: return .consonant
        case .vowelTeam: return .vowelTeam
        }
    }
}

/// One plotted point on the speech accuracy line graph.
struct AccuracyPoint: Identifiable, Sendable {
    let attempt: Int
    let percent: Double

    var id: Int { attempt }
}

/// One ranked practiced sound for the dashboard bar chart.
struct PracticedSoundStat: Identifiable, Sendable {
    let soundID: String
    let displayName: String
    let visitCount: Int
    let totalDuration: TimeInterval

    var id: String { soundID }
}

/// Phoneme performance summary for strengths and needs badges.
struct PhonemePerformanceStat: Identifiable, Sendable {
    let phonemeLabel: String
    let averageCorrectness: Double
    let attemptCount: Int

    var id: String { phonemeLabel }
}

/// Weekly dashboard summary metrics.
struct WeeklyDashboardSummary: Sendable {
    let streakDays: Int
    let activitySummaryLine: String
    let moodTrendLine: String
    let todaysFocusLine: String
}

/// Aggregates practice records for dashboard charts and summaries.
enum DashboardAnalytics {
    private static let minimumAttemptsForFocus = 2
    private static let minimumAttemptsForStrengths = 2
    private static let maxAccuracyPoints = 10
    private static let maxStrengthCount = 3
    private static let maxNeedCount = 3

    /// Builds the weekly summary card content.
    /// - Parameters:
    ///   - engagements: Stored activity engagement records.
    ///   - sessions: Stored Test session records.
    ///   - streakDays: Current practice streak.
    ///   - referenceDate: Date used to determine the current calendar week.
    /// - Returns: Summary metrics for the This week card.
    static func weeklySummary(
        engagements: [ActivityEngagementRecord],
        sessions: [PracticeSessionRecord],
        streakDays: Int,
        referenceDate: Date = .now
    ) -> WeeklyDashboardSummary {
        let weekEngagements = engagementsInCurrentWeek(from: engagements, referenceDate: referenceDate)
        let weekSessions = sessionsInRollingDays(from: sessions, days: 7, endingOn: referenceDate)

        let sandboxVisits = visitCount(for: .sandbox, in: weekEngagements)
        let flashVisits = visitCount(for: .flash, in: weekEngagements)
        let testAttempts = weekSessions.count

        return WeeklyDashboardSummary(
            streakDays: streakDays,
            activitySummaryLine: "Sandbox: \(sandboxVisits) visits · Flash: \(flashVisits) visits · Test: \(testAttempts) attempts",
            moodTrendLine: moodTrendLine(from: weekEngagements),
            todaysFocusLine: todaysFocusLine(from: sessions, endingOn: referenceDate)
        )
    }

    /// Returns Test sessions on a day that match the selected group and sound filters.
    /// - Parameters:
    ///   - date: Selected calendar day.
    ///   - sessions: Stored Test session records.
    ///   - group: Sound group filter.
    ///   - soundID: Specific sound ID, or `nil` for all sounds in the group.
    /// - Returns: Matching sessions sorted oldest to newest.
    static func sessions(
        on date: Date,
        from sessions: [PracticeSessionRecord],
        group: SoundGroupFilter,
        soundID: String?
    ) -> [PracticeSessionRecord] {
        let calendar = Calendar.current
        return sessions
            .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            .filter { matchesFilters(session: $0, group: group, soundID: soundID) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    /// Builds up to ten accuracy points for the selected day and filters.
    /// - Parameters:
    ///   - date: Selected calendar day.
    ///   - sessions: Stored Test session records.
    ///   - group: Sound group filter.
    ///   - soundID: Specific sound ID, or `nil` for all sounds in the group.
    /// - Returns: Attempt-indexed accuracy percentages.
    static func accuracySeries(
        on date: Date,
        from sessions: [PracticeSessionRecord],
        group: SoundGroupFilter,
        soundID: String?
    ) -> [AccuracyPoint] {
        let filtered = Self.sessions(on: date, from: sessions, group: group, soundID: soundID)
        return filtered
            .prefix(maxAccuracyPoints)
            .enumerated()
            .map { index, session in
                AccuracyPoint(attempt: index + 1, percent: Double(session.correctness))
            }
    }

    /// Returns sounds practiced most often on the selected day.
    /// - Parameters:
    ///   - date: Selected calendar day.
    ///   - engagements: Stored activity engagement records.
    ///   - limit: Maximum number of sounds to return.
    /// - Returns: Ranked practiced sounds.
    static func topPracticedSounds(
        on date: Date,
        from engagements: [ActivityEngagementRecord],
        limit: Int = 5
    ) -> [PracticedSoundStat] {
        let dayEngagements = ActivityEngagementAnalytics.engagements(on: date, records: engagements)
        var counts: [String: Int] = [:]
        var durations: [String: TimeInterval] = [:]

        for engagement in dayEngagements {
            counts[engagement.targetSoundID, default: 0] += 1
            durations[engagement.targetSoundID, default: 0] += engagement.durationSeconds
        }

        return counts
            .map { soundID, count in
                PracticedSoundStat(
                    soundID: soundID,
                    displayName: displayName(forSoundID: soundID),
                    visitCount: count,
                    totalDuration: durations[soundID] ?? 0
                )
            }
            .sorted {
                if $0.visitCount == $1.visitCount {
                    return $0.totalDuration > $1.totalDuration
                }
                return $0.visitCount > $1.visitCount
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Returns strengths and needs phonemes from rolling Test session averages.
    /// - Parameters:
    ///   - sessions: Stored Test session records.
    ///   - lastDays: Number of days to include.
    ///   - referenceDate: End date for the rolling window.
    /// - Returns: Top and bottom phoneme stats.
    static func strengthsAndNeeds(
        from sessions: [PracticeSessionRecord],
        lastDays: Int = 7,
        referenceDate: Date = .now
    ) -> (strengths: [PhonemePerformanceStat], needs: [PhonemePerformanceStat]) {
        let recentSessions = sessionsInRollingDays(from: sessions, days: lastDays, endingOn: referenceDate)
        let grouped = Dictionary(grouping: recentSessions, by: \.targetPhoneme)

        let stats = grouped.compactMap { phoneme, attempts -> PhonemePerformanceStat? in
            guard attempts.count >= minimumAttemptsForStrengths else { return nil }
            let average = Double(attempts.reduce(0) { $0 + $1.correctness }) / Double(attempts.count)
            return PhonemePerformanceStat(
                phonemeLabel: phoneme,
                averageCorrectness: average,
                attemptCount: attempts.count
            )
        }
        .sorted { $0.averageCorrectness > $1.averageCorrectness }

        let strengths = Array(stats.prefix(maxStrengthCount))
        let needs = Array(stats.suffix(maxNeedCount).reversed())
        return (strengths, needs)
    }

    /// Sounds available for the sound picker in the selected group.
    /// - Parameter group: Selected sound group filter.
    /// - Returns: Practice sounds in that group.
    static func sounds(for group: SoundGroupFilter) -> [PracticeSound] {
        switch group {
        case .all:
            return []
        case .vowel:
            return PracticeSoundCatalog.vowels
        case .consonant:
            return PracticeSoundCatalog.consonants
        case .vowelTeam:
            return PracticeSoundCatalog.vowelTeams
        }
    }

    /// Resolves the sound ID stored on a session, with a phoneme fallback.
    /// - Parameter session: One Test session record.
    /// - Returns: Canonical practice sound ID.
    static func resolvedSoundID(for session: PracticeSessionRecord) -> String {
        if let soundID = session.targetSoundID, !soundID.isEmpty {
            return PracticeSoundAssetBridge.canonicalSoundID(soundID)
        }
        return fallbackSoundID(forPhoneme: session.targetPhoneme)
    }

    private static func matchesFilters(
        session: PracticeSessionRecord,
        group: SoundGroupFilter,
        soundID: String?
    ) -> Bool {
        let resolvedSoundID = resolvedSoundID(for: session)
        guard let sound = PracticeSoundCatalog.sound(withID: resolvedSoundID) else {
            return false
        }

        if let soundID {
            return resolvedSoundID == PracticeSoundAssetBridge.canonicalSoundID(soundID)
        }

        guard let category = group.category else {
            return true
        }

        return sound.category == category
    }

    private static func fallbackSoundID(forPhoneme phonemeRawValue: String) -> String {
        PracticeSoundCatalog.allSounds
            .first(where: { $0.linkedPhoneme.rawValue == phonemeRawValue })?
            .id ?? phonemeRawValue
    }

    private static func displayName(forSoundID soundID: String) -> String {
        PracticeSoundCatalog.sound(withID: soundID)?.displayName ?? soundID
    }

    private static func visitCount(
        for activity: PracticeActivity,
        in engagements: [ActivityEngagementRecord]
    ) -> Int {
        engagements.filter { $0.activityRawValue == activity.rawValue }.count
    }

    private static func engagementsInCurrentWeek(
        from engagements: [ActivityEngagementRecord],
        referenceDate: Date
    ) -> [ActivityEngagementRecord] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
            return []
        }
        return engagements.filter { engagement in
            weekInterval.contains(engagement.endedAt)
        }
    }

    private static func sessionsInRollingDays(
        from sessions: [PracticeSessionRecord],
        days: Int,
        endingOn referenceDate: Date
    ) -> [PracticeSessionRecord] {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: referenceDate)
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: endOfDay) else {
            return []
        }
        return sessions.filter { $0.timestamp >= startDate }
    }

    private static func moodTrendLine(from engagements: [ActivityEngagementRecord]) -> String {
        let moods = engagements.compactMap(\.mood)
        guard moods.count >= 2 else {
            return "Log moods after activities to see weekly trends."
        }

        let scores = moods.map(moodScore)
        let midpoint = moods.count / 2
        let earlyAverage = average(of: Array(scores.prefix(midpoint)))
        let lateAverage = average(of: Array(scores.suffix(moods.count - midpoint)))

        if lateAverage >= earlyAverage + 0.4 {
            return "Usually finishes happier after practice."
        }
        if lateAverage <= earlyAverage - 0.4 {
            return "Moods were tougher later in the week — try shorter practice bursts."
        }
        return "Mood stayed steady across this week's practice."
    }

    private static func todaysFocusLine(
        from sessions: [PracticeSessionRecord],
        endingOn referenceDate: Date
    ) -> String {
        let recentSessions = sessionsInRollingDays(from: sessions, days: 7, endingOn: referenceDate)
        let grouped = Dictionary(grouping: recentSessions) { resolvedSoundID(for: $0) }

        let weakest = grouped.compactMap { soundID, attempts -> (String, Double)? in
            guard attempts.count >= minimumAttemptsForFocus else { return nil }
            let average = Double(attempts.reduce(0) { $0 + $1.correctness }) / Double(attempts.count)
            return (soundID, average)
        }
        .min(by: { $0.1 < $1.1 })

        if let weakest,
           let sound = PracticeSoundCatalog.sound(withID: weakest.0) {
            return "Try \(sound.displayName) in Speech Accuracy — keep practicing."
        }

        if let lastID = PracticeProgressStore.lastPracticeTargetID,
           let sound = PracticeSoundCatalog.sound(withID: lastID) {
            return "Continue with \(sound.displayName) in Speech Accuracy."
        }

        return "Complete a Test activity to get a focus sound."
    }

    private static func moodScore(_ mood: String) -> Double {
        switch mood {
        case "Excited": return 5
        case "Happy": return 4
        case "Okay": return 3
        case "Tired": return 2
        case "Frustrated": return 1
        default: return 3
        }
    }

    private static func average(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
