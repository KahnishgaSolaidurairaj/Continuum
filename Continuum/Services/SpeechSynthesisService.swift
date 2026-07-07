import AVFoundation

/// Speaks a practice target aloud for Flash activity.
final class SpeechSynthesisService {
    private let synthesizer = AVSpeechSynthesizer()

    /// Speaks the example word for a practice target.
    /// - Parameter target: The selected letter or sound.
    func speak(_ target: PracticeTarget) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: target.exampleWord)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
}
