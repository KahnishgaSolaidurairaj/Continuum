import AVFoundation
import Foundation

/// Captures microphone audio with timestamps aligned to `CACurrentMediaTime()`.
final class AudioCaptureService {
    private let engine = AVAudioEngine()
    private var isRunning = false
    private(set) var sampleRate: Double = 44_100

    var onChunkCaptured: ((AudioChunk) -> Void)?

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
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        sampleRate = format.sampleRate

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let timestamp = CACurrentMediaTime()
            let samples = Self.extractSamples(from: buffer)
            let chunk = AudioChunk(timestamp: timestamp, samples: samples, sampleRate: format.sampleRate)
            self.onChunkCaptured?(chunk)
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    /// Stops microphone capture and tears down the audio tap.
    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
    }

    private static func extractSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
    }
}
