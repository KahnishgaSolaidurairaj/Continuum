import Foundation

/// Asset names for Broca the Bear mascot poses used across the app.
enum BrocaBearCatalog {
    static let poseImageNames: [String] = [
        "BrocaBearWaving",
        "BrocaBearPointing",
        "BrocaBearCheering",
        "BrocaBearThinking",
        "BrocaBearPresenting"
    ]

    static let defaultPose = "BrocaBearWaving"

    /// Returns a random pose image name, optionally avoiding the current pose.
    /// - Parameter current: The pose currently on screen.
    /// - Returns: An asset name for a Broca pose.
    static func randomPose(excluding current: String? = nil) -> String {
        let options = poseImageNames.filter { $0 != current }
        return options.randomElement() ?? poseImageNames[0]
    }
}
