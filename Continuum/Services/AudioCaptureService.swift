import AVFoundation
import Foundation
import os

/// Captures microphone audio with timestamps aligned to `CACurrentMediaTime()`.
///
/// Audio-session handoff: Flash reference playback uses `.playback` in
/// `ReferenceAudioPlaybackService`. Test recording reconfigures the shared session
/// here to `.playAndRecord` + `.spokenAudio` with Apple voice processing enabled.
final class AudioCaptureService {
    private let engine = AVAudioEngine()
    private let logger = Logger(subsystem: "com.continuum", category: "AudioCapture")
    private var isRunning = false
    private(set) var sampleRate: Double = 44_100

    /// Whether Apple's voice processing pipeline is active for the current capture session.
    private(set) var isVoiceProcessingActive = false

    var onChunkCaptured: ((AudioChunk) -> Void)?
    var onBufferCaptured: ((AVAudioPCMBuffer) -> Void)?

    /// Called when capture starts without voice processing after a configuration failure.
    var onVoiceProcessingUnavailable: (() -> Void)?

    /// Active microphone format after `start()` has been called.
    var inputFormat: AVAudioFormat? {
        guard isRunning else { return nil }
        return engine.inputNode.outputFormat(forBus: 0)
    }

    /// Requests microphone permission from the user.
    /// - Returns: Whether recording is allowed.
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Starts microphone capture and forwards timestamped chunks.
    /// - Throws: Audio engine startup errors.
    func start() throws {
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try session.setActive(true)
        try preferBuiltInMicrophone(session: session)
        try reduceInputGainWhenVoiceProcessing(session: session)

        let inputNode = engine.inputNode
        isVoiceProcessingActive = enableVoiceProcessing(on: inputNode)

        let format = inputNode.outputFormat(forBus: 0)
        sampleRate = format.sampleRate

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let timestamp = CACurrentMediaTime()
            let samples = Self.extractSamples(from: buffer)
            let chunk = AudioChunk(timestamp: timestamp, samples: samples, sampleRate: format.sampleRate)
            self.onChunkCaptured?(chunk)
            self.onBufferCaptured?(buffer)
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    /// Stops microphone capture and tears down the audio tap.
    func stop() {
        guard isRunning else { return }
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)
        if isVoiceProcessingActive {
            try? inputNode.setVoiceProcessingEnabled(false)
            isVoiceProcessingActive = false
        }
        engine.stop()
        isRunning = false
    }

    /// Routes capture through the built-in mic when available for better noise handling.
    private func preferBuiltInMicrophone(session: AVAudioSession) throws {
        guard
            let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic })
        else {
            return
        }
        try session.setPreferredInput(builtInMic)
    }

    /// Lowers hardware input gain when supported so voice-processing AGC does not peg the waveform.
    private func reduceInputGainWhenVoiceProcessing(session: AVAudioSession) throws {
        guard session.isInputGainSettable else { return }
        try session.setInputGain(0.65)
    }

    /// Enables Apple echo cancellation and noise suppression when supported.
    /// - Parameter inputNode: The engine input node to configure.
    /// - Returns: Whether voice processing is active.
    private func enableVoiceProcessing(on inputNode: AVAudioInputNode) -> Bool {
        do {
            try inputNode.setVoiceProcessingEnabled(true)
            return true
        } catch {
            logger.warning("Voice processing unavailable, using unprocessed capture: \(error.localizedDescription)")
            onVoiceProcessingUnavailable?()
            return false
        }
    }

    private static func extractSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
    }
}
