import Foundation

/// Persists whether the learner has seen the first-launch app preview tour.
enum AppTourStore {
    private static let hasCompletedKey = "hasCompletedAppTour"

    /// Whether the user has finished or skipped the app preview tour.
    static var hasCompletedAppTour: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedKey) }
    }

    /// Marks the app preview tour as complete so it is not shown again on launch.
    static func markCompleted() {
        hasCompletedAppTour = true
    }

#if DEBUG
    /// Clears tour completion so developers can preview the tour again.
    static func resetForPreview() {
        hasCompletedAppTour = false
    }
#endif
}
