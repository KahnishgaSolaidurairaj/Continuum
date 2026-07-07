import Foundation

/// Portrait-style demo thumbnails for the Try activity (person + example word).
enum PronunciationDemoPlaceholder {
    /// Stable portrait photo IDs from picsum — always people, never landscapes.
    private static let portraitIDs = [64, 65, 91, 101, 107, 177, 338, 433, 447, 473]

    /// Returns a portrait image URL for the given practice target.
    /// - Parameter target: The sound being demonstrated.
    /// - Returns: URL to a face-forward stock portrait.
    static func portraitURL(for target: PracticeTarget) -> URL {
        let index = abs(target.id.hashValue) % portraitIDs.count
        let photoID = portraitIDs[index]
        return URL(string: "https://picsum.photos/id/\(photoID)/600/400")!
    }
}
