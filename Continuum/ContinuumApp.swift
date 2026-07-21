import SwiftUI
import SwiftData

@main
struct ContinuumApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PracticeSessionRecord.self, ActivityEngagementRecord.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Older installs may have an incompatible store after schema changes.
            SwiftDataStoreRecovery.deleteStore(matching: modelConfiguration)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
