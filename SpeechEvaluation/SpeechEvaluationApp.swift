//
//  SpeechEvaluationApp.swift
//  SpeechEvaluation
//
//  Created by 59 BGCC Loan Library on 6/30/26.
//

import SwiftUI
import SwiftData

@main
struct SpeechEvaluationApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
