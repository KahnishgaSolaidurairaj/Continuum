import AVFoundation

/// Speaks a practice target aloud for Flash activity.
final class SpeechSynthesisService {
    private let synthesizer = AVSpeechSynthesizer()

    /// Speaks the isolated target sound for Flash level 1.
    /// - Parameter target: The selected letter or sound.
    func speakSound(_ target: PracticeTarget) {
        if let spokenSound = isolatedSound(from: target.displayLabel) {
            speakWord(spokenSound)
        } else {
            speakWord(target.traceCharacter)
        }
    }

    /// Extracts the slash-delimited sound cue from labels like "/b/" or "Short /a/".
    private func isolatedSound(from displayLabel: String) -> String? {
        guard let start = displayLabel.firstIndex(of: "/"),
              let end = displayLabel[displayLabel.index(after: start)...].firstIndex(of: "/") else {
            return nil
        }
        let sound = displayLabel[displayLabel.index(after: start)..<end]
        return sound.isEmpty ? nil : String(sound)
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
