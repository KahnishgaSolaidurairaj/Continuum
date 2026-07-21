import Foundation

/// Persists parent-selected priority sounds shown first on the Practice tab.
enum PracticePriorityStore {
    private static let prioritySoundIDsKey = "prioritySoundIDs"

    /// Ordered sound IDs the child should focus on first.
    static var prioritySoundIDs: [String] {
        get { UserDefaults.standard.stringArray(forKey: prioritySoundIDsKey) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: prioritySoundIDsKey) }
    }

    /// Returns the saved priority sounds in display order.
    static func prioritySounds() -> [PracticeSound] {
        prioritySoundIDs.compactMap { PracticeSoundCatalog.sound(withID: $0) }
    }

    /// Adds a sound to the priority list if it is not already included.
    /// - Parameter soundID: The curriculum sound identifier to prioritize.
    static func add(soundID: String) {
        let canonicalID = PracticeSoundAssetBridge.canonicalSoundID(soundID)
        guard !prioritySoundIDs.contains(canonicalID) else { return }
        prioritySoundIDs = prioritySoundIDs + [canonicalID]
    }

    /// Removes a sound from the priority list.
    /// - Parameter soundID: The curriculum sound identifier to deprioritize.
    static func remove(soundID: String) {
        let canonicalID = PracticeSoundAssetBridge.canonicalSoundID(soundID)
        prioritySoundIDs = prioritySoundIDs.filter { $0 != canonicalID }
    }

    /// Returns whether a sound is already marked as priority.
    /// - Parameter soundID: The curriculum sound identifier to check.
    static func contains(soundID: String) -> Bool {
        prioritySoundIDs.contains(PracticeSoundAssetBridge.canonicalSoundID(soundID))
    }
}
