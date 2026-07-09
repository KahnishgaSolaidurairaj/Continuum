import AVFoundation

/// Speaks a practice target aloud for Flash activity.
final class SpeechSynthesisService {
    private let synthesizer = AVSpeechSynthesizer()

    /// Speaks the example word for a practice target.
    /// - Parameter target: The selected letter or sound.
    func speak(_ target: PracticeTarget) {
        speakWord(target.exampleWord)
    }

    /// Speaks an arbitrary word aloud for Flash levels 2 and 3.
    /// - Parameter word: The word to pronounce.
    func speakWord(_ word: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
}
