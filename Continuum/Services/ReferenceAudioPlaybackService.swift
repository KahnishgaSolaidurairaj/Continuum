import AVFoundation
import Foundation

/// Plays bundled PhonemeAudio reference clips from the app resources.
///
/// Audio-session handoff: this service uses `.playback` for Flash reference clips.
/// Test recording reconfigures the shared session in `AudioCaptureService` to
/// `.playAndRecord` + `.spokenAudio` with voice processing when capture starts.
final class ReferenceAudioPlaybackService {
    private var player: AVAudioPlayer?

    /// Plays the primary reference clip for a practice sound.
    /// - Parameter soundID: Practice sound identifier.
    /// - Returns: Whether playback started successfully.
    @discardableResult
    func playReference(for soundID: String) -> Bool {
        guard let sound = PracticeSoundCatalog.sound(withID: soundID) else { return false }
        let fileName = sound.playbackFile as NSString
        let baseName = fileName.deletingPathExtension
        let fileExtension = fileName.pathExtension.isEmpty ? "wav" : fileName.pathExtension

        guard let url = Bundle.main.url(
            forResource: baseName,
            withExtension: fileExtension
        ) ?? Bundle.main.url(
            forResource: baseName,
            withExtension: fileExtension,
            subdirectory: "ReferenceAudio"
        ) else {
            return false
        }

        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            return player?.play() ?? false
        } catch {
            return false
        }
    }

    /// Stops any active reference playback.
    func stop() {
        player?.stop()
        player = nil
    }
}
