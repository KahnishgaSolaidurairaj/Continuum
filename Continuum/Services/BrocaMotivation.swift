import Foundation

/// Encouraging messages from Broca the Bear for the home screen motivation button.
enum BrocaMotivation {
    static let messages: [String] = [
        "You're doing great — one sound at a time!",
        "Broca believes in you. Let's practice together!",
        "Every try makes your voice stronger. Keep going!",
        "Mistakes are how we learn. Try again — you've got this!",
        "I heard you working hard last time. Proud of you!",
        "Small steps today, big confidence tomorrow!",
        "Your mouth is learning a superpower. Cool, right?",
        "Take a breath, smile, and say it one more time!",
        "Practice heroes show up every day — like you!",
        "That sound is getting closer. I can tell!"
    ]

    /// Returns a random motivational line from Broca.
    static func randomMessage(excluding current: String? = nil) -> String {
        let options = messages.filter { $0 != current }
        return options.randomElement() ?? messages[0]
    }
}
