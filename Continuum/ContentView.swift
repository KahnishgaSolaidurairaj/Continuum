import SwiftUI
import SwiftData

/// App entry point showing the Continuum tab shell.
struct ContentView: View {
    private var deviceLayout: ContinuumDeviceLayout {
        UIDevice.current.userInterfaceIdiom == .phone ? .phone : .pad
    }

    var body: some View {
        MainTabView()
            .environment(\.continuumDeviceLayout, deviceLayout)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PracticeSessionRecord.self, ActivityEngagementRecord.self], inMemory: true)
}
