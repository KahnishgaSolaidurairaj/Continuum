import Foundation
import SwiftData

/// Recreates the on-disk SwiftData store when a schema upgrade cannot be opened.
enum SwiftDataStoreRecovery {
    /// Deletes the SQLite store files backing a model configuration.
    /// - Parameter configuration: The configuration whose store should be removed.
    static func deleteStore(matching configuration: ModelConfiguration) {
        let storeURL = configuration.url

        let fileManager = FileManager.default
        let relatedURLs = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}
