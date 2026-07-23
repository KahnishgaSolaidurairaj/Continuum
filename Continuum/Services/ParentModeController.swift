import SwiftUI

/// Shared parent/child mode state for the tab shell and home screens.
@Observable
@MainActor
final class ParentModeController {
    var isChildMode: Bool {
        didSet { ParentModeStore.isChildModeActive = isChildMode }
    }

    init() {
        isChildMode = ParentModeStore.isChildModeActive
    }

    /// Switches into the simplified child home and practice experience.
    func switchToChildMode() {
        isChildMode = true
    }

    /// Switches back to the parent experience when no PIN is configured.
    func switchToParentModeWithoutPIN() {
        isChildMode = false
    }

    /// Attempts to unlock parent mode using the saved four-digit PIN.
    /// - Parameter pin: PIN entered by the parent.
    /// - Returns: Whether the PIN was accepted.
    func unlockParentMode(with pin: String) -> Bool {
        guard ParentModeStore.verifyPIN(pin) else { return false }
        isChildMode = false
        return true
    }

    /// Whether child-to-parent switching requires PIN entry.
    var requiresPINToUnlockParentMode: Bool {
        ParentModeStore.hasPINConfigured
    }
}
