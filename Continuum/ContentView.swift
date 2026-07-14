import SwiftUI
import SwiftData

/// App entry point showing the Continuum tab shell.
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PracticeSessionRecord.self, ActivityEngagementRecord.self], inMemory: true)
}
