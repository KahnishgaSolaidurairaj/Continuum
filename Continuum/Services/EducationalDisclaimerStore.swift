import Foundation

/// Persists whether the user has acknowledged the educational-use disclaimer.
enum EducationalDisclaimerStore {
    private static let hasAcknowledgedKey = "hasAcknowledgedEducationalDisclaimer"

    /// Whether the user has accepted the in-app educational disclaimer.
    static var hasAcknowledgedDisclaimer: Bool {
        get { UserDefaults.standard.bool(forKey: hasAcknowledgedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasAcknowledgedKey) }
    }

    /// Records that the user accepted the disclaimer so it is not shown again.
    static func markAcknowledged() {
        hasAcknowledgedDisclaimer = true
    }

#if DEBUG
    /// Clears disclaimer acceptance so developers can preview it again.
    static func resetForPreview() {
        hasAcknowledgedDisclaimer = false
    }
#endif
}
