import CryptoKit
import Foundation
import Security

/// Persists parent PIN, backup phone, temporary unlock codes, and child mode state.
enum ParentModeStore {
    private static let childModeKey = "isChildModeActive"
    private static let pinHashKey = "parentPINHash"
    private static let backupPhoneKey = "parentBackupPhoneNumber"
    private static let tempPINHashKey = "parentTemporaryPINHash"
    private static let tempPINExpiryKey = "parentTemporaryPINExpiry"
    private static let needsParentPINUpdateKey = "needsParentPINUpdate"
    private static let pinKeychainAccount = "parentDisplayPIN"

    private static let temporaryPINLifetime: TimeInterval = 15 * 60

    /// Whether the simplified child experience is active.
    static var isChildModeActive: Bool {
        get { UserDefaults.standard.bool(forKey: childModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: childModeKey) }
    }

    /// Whether a parent should create a new PIN after unlocking with a temporary code.
    static var needsParentPINUpdate: Bool {
        get { UserDefaults.standard.bool(forKey: needsParentPINUpdateKey) }
        set { UserDefaults.standard.set(newValue, forKey: needsParentPINUpdateKey) }
    }

    /// Whether a four-digit parent PIN has been configured.
    static var hasPINConfigured: Bool {
        guard let hash = UserDefaults.standard.string(forKey: pinHashKey) else { return false }
        return !hash.isEmpty
    }

    /// Optional backup phone number used to reset a forgotten PIN.
    static var backupPhoneNumber: String? {
        get {
            let value = UserDefaults.standard.string(forKey: backupPhoneKey)
            return value?.isEmpty == true ? nil : value
        }
        set {
            if let newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: backupPhoneKey)
            } else {
                UserDefaults.standard.removeObject(forKey: backupPhoneKey)
            }
        }
    }

    /// Saves a new four-digit parent PIN.
    /// - Parameter pin: Exactly four numeric digits.
    static func setPIN(_ pin: String) {
        UserDefaults.standard.set(hashPIN(pin), forKey: pinHashKey)
        saveDisplayPIN(pin)
        needsParentPINUpdate = false
    }

    /// Returns the saved parent PIN for display to the parent on this device.
    static func storedPIN() -> String? {
        readDisplayPIN()
    }

    /// Returns whether the entered PIN matches the saved parent PIN.
    /// - Parameter pin: Exactly four numeric digits.
    static func verifyPIN(_ pin: String) -> Bool {
        guard hasPINConfigured,
              let savedHash = UserDefaults.standard.string(forKey: pinHashKey) else {
            return false
        }
        return hashPIN(pin) == savedHash
    }

    /// Creates a temporary six-digit unlock code and stores it until it expires.
    /// - Returns: The plain temporary PIN to include in the recovery text message.
    static func issueTemporaryPIN() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999_999))
        UserDefaults.standard.set(hashPIN(code), forKey: tempPINHashKey)
        UserDefaults.standard.set(Date().addingTimeInterval(temporaryPINLifetime).timeIntervalSince1970, forKey: tempPINExpiryKey)
        return code
    }

    /// Returns whether a temporary PIN is still valid and matches the entered code.
    /// - Parameter pin: Six-digit temporary PIN from the recovery text message.
    static func verifyTemporaryPIN(_ pin: String) -> Bool {
        guard let savedHash = UserDefaults.standard.string(forKey: tempPINHashKey),
              let expiryTimestamp = UserDefaults.standard.object(forKey: tempPINExpiryKey) as? Double else {
            return false
        }

        guard Date().timeIntervalSince1970 <= expiryTimestamp else {
            clearTemporaryPIN()
            return false
        }

        return hashPIN(pin) == savedHash
    }

    /// Clears any active temporary PIN recovery code.
    static func clearTemporaryPIN() {
        UserDefaults.standard.removeObject(forKey: tempPINHashKey)
        UserDefaults.standard.removeObject(forKey: tempPINExpiryKey)
    }

    /// Marks that the parent reached parent mode through a temporary PIN unlock.
    static func markTemporaryPINUnlockComplete() {
        clearTemporaryPIN()
        needsParentPINUpdate = true
    }

    /// Resets the parent PIN when the backup phone number matches.
    /// - Parameters:
    ///   - phoneNumber: Phone number entered by the parent.
    ///   - newPIN: Replacement four-digit PIN.
    /// - Returns: Whether the phone matched and the PIN was updated.
    @discardableResult
    static func resetPIN(phoneNumber: String, newPIN: String) -> Bool {
        guard normalizedPhone(phoneNumber) == normalizedPhone(backupPhoneNumber ?? "") else {
            return false
        }
        setPIN(newPIN)
        return true
    }

    /// Clears the saved parent PIN.
    static func clearPIN() {
        UserDefaults.standard.removeObject(forKey: pinHashKey)
        deleteDisplayPIN()
        clearTemporaryPIN()
        needsParentPINUpdate = false
    }

    /// Returns a display-friendly masked version of the backup phone number.
    static func maskedBackupPhoneNumber() -> String? {
        guard let digits = backupPhoneNumber?.filter(\.isNumber), digits.count >= 4 else { return nil }
        let lastFour = digits.suffix(4)
        return "(***) ***-\(lastFour)"
    }

#if DEBUG
    /// Clears parent-mode settings for developer previews.
    static func resetForPreview() {
        isChildModeActive = false
        clearPIN()
        backupPhoneNumber = nil
    }
#endif

    private static func hashPIN(_ pin: String) -> String {
        let digest = SHA256.hash(data: Data(pin.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func normalizedPhone(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    private static func saveDisplayPIN(_ pin: String) {
        let data = Data(pin.utf8)
        deleteDisplayPIN()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func readDisplayPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let pin = String(data: data, encoding: .utf8) else {
            return nil
        }
        return pin
    }

    private static func deleteDisplayPIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKeychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
