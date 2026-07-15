import SwiftUI

/// One warm-up breathing exercise shown in the Home warm-up sheet.
struct WarmUpExercise: Identifiable, Sendable {
    let id: String
    let title: String
    let instructions: String
    let tip: String
    let iconSystemName: String
    let iconAccentColor: Color

    /// Ordered warm-up slides shown before practice.
    static let slides: [WarmUpExercise] = [
        WarmUpExercise(
            id: "blow_lightly",
            title: "Blow lightly",
            instructions: "Soft breeze through your lips for 4 seconds like cooling soup. Repeat 3 times.",
            tip: "You should barely feel the air on your hand.",
            iconSystemName: "leaf.fill",
            iconAccentColor: Color(red: 0.36, green: 0.68, blue: 0.42)
        ),
        WarmUpExercise(
            id: "pop_bubbles",
            title: "Pop bubbles",
            instructions: "Make a tiny bubble with your lips, then pop it with a soft puh sound. Do 5 pops.",
            tip: "If bubbles are hard, practice puh-puh-puh with lips closed then open.",
            iconSystemName: "bubbles.and.sparkles.fill",
            iconAccentColor: ContinuumTheme.stormBlue
        )
    ]
}
