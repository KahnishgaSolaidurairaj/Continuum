import AVFoundation
import Foundation
import Speech

/// Recognizes one spoken word attempt using on-device SpeechAnalyzer.
@MainActor
final class WordSpeechRecognitionService {
    enum ReadinessState: Equatable {
        case idle
        case preparing
        case ready
        case unavailable(String)
    }

    private(set) var readinessState: ReadinessState = .idle

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var finalTranscript = AttributedString()
    private var confidenceValues: [Double] = []
    private var analyzerFormat: AVAudioFormat?
    private let locale: Locale

    init(locale: Locale = Locale(identifier: "en_US")) {
        self.locale = locale
    }

    /// Prepares on-device speech models for the configured locale.
    func prepare() async {
        readinessState = .preparing

        guard SpeechTranscriber.isAvailable else {
            readinessState = .unavailable("Speech recognition is not available on this device.")
            return
        }

        let supportedLocales = await SpeechTranscriber.supportedLocales
        guard let resolvedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
            readinessState = .unavailable("English speech recognition is not supported on this device.")
            return
        }

        guard supportedLocales.contains(where: {
            $0.identifier(.bcp47) == resolvedLocale.identifier(.bcp47)
        }) else {
            readinessState = .unavailable("English speech recognition is not supported on this device.")
            return
        }

        do {
            let installer = SpeechTranscriber(
                locale: resolvedLocale,
                transcriptionOptions: [],
                reportingOptions: [],
                attributeOptions: [.transcriptionConfidence]
            )
            if !(await isLocaleInstalled(resolvedLocale)) {
                try await downloadAssets(for: installer)
            }
            readinessState = .ready
        } catch {
            readinessState = .unavailable(
                "Could not prepare speech recognition: \(error.localizedDescription)"
            )
        }
    }

    /// Starts a fresh recognition session for one recording.
    /// - Parameter sampleRate: Sample rate of captured microphone chunks.
    func beginSession(sampleRate: Double) async throws {
        guard case .ready = readinessState else {
            throw WordSpeechRecognitionError.notReady
        }

        finalTranscript = AttributedString()
        confidenceValues = []

        let resolvedLocale = await SpeechTranscriber.supportedLocale(equivalentTo: locale) ?? locale
        let transcriber = SpeechTranscriber(
            locale: resolvedLocale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: [.transcriptionConfidence]
        )
        self.transcriber = transcriber
        analyzer = SpeechAnalyzer(modules: [transcriber])
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

        let (inputSequence, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation

        resultsTask = Task {
            do {
                for try await result in transcriber.results where result.isFinal {
                    finalTranscript += result.text
                    confidenceValues.append(contentsOf: Self.confidenceValues(from: result.text))
                }
            } catch {
                // The session ends when recording stops or is cancelled.
            }
        }

        try await analyzer?.start(inputSequence: inputSequence)
    }

    /// Streams one captured microphone chunk into the analyzer.
    /// - Parameter chunk: Timestamped microphone samples from `AudioCaptureService`.
    func append(chunk: AudioChunk) {
        guard
            let inputContinuation,
            let analyzerFormat,
            let captureBuffer = AudioPCMBufferFactory.makeBuffer(from: chunk)
        else {
            return
        }

        do {
            let converted = try AudioPCMBufferConverter.convert(
                captureBuffer,
                to: analyzerFormat
            )
            inputContinuation.yield(AnalyzerInput(buffer: converted))
        } catch {
            return
        }
    }

    /// Finalizes recognition and returns the transcript with average confidence.
    /// - Returns: Final transcript text and confidence between 0 and 1.
    func finish() async throws -> (transcript: String, confidence: Double) {
        inputContinuation?.finish()
        inputContinuation = nil
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        resultsTask?.cancel()
        resultsTask = nil
        analyzer = nil
        transcriber = nil

        let transcript = String(finalTranscript.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        let averageConfidence: Double
        if confidenceValues.isEmpty {
            averageConfidence = transcript.isEmpty ? 0 : 0.5
        } else {
            averageConfidence = confidenceValues.reduce(0, +) / Double(confidenceValues.count)
        }
        return (transcript, averageConfidence)
    }

    /// Cancels the current session without producing a final transcript.
    func cancel() {
        inputContinuation?.finish()
        inputContinuation = nil
        resultsTask?.cancel()
        resultsTask = nil
        let activeAnalyzer = analyzer
        analyzer = nil
        transcriber = nil
        finalTranscript = AttributedString()
        confidenceValues = []
        Task {
            try? await activeAnalyzer?.cancelAndFinishNow()
        }
    }

    private func isLocaleInstalled(_ locale: Locale) async -> Bool {
        let installed = Set(await SpeechTranscriber.installedLocales)
        return installed.contains { $0.identifier(.bcp47) == locale.identifier(.bcp47) }
    }

    private func downloadAssets(for transcriber: SpeechTranscriber) async throws {
        guard let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) else {
            return
        }
        try await request.downloadAndInstall()
    }

    private static func confidenceValues(from attributedText: AttributedString) -> [Double] {
        attributedText.runs.compactMap(\.transcriptionConfidence)
    }
}

enum WordSpeechRecognitionError: LocalizedError {
    case notReady

    var errorDescription: String? {
        switch self {
        case .notReady:
            return "Speech recognition is not ready yet."
        }
    }
}

/// Builds PCM buffers from captured microphone chunks.
enum AudioPCMBufferFactory {
    /// Creates a mono float PCM buffer from one captured chunk.
    /// - Parameter chunk: Timestamped microphone samples.
    /// - Returns: A PCM buffer matching the chunk sample rate.
    static func makeBuffer(from chunk: AudioChunk) -> AVAudioPCMBuffer? {
        guard
            let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: chunk.sampleRate,
                channels: 1,
                interleaved: false
            ),
            let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(chunk.samples.count)
            ),
            let channelData = buffer.floatChannelData?[0]
        else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(chunk.samples.count)
        for index in chunk.samples.indices {
            channelData[index] = chunk.samples[index]
        }
        return buffer
    }
}

/// Converts PCM buffers into the format required by SpeechAnalyzer.
enum AudioPCMBufferConverter {
    /// Converts one PCM buffer into the analyzer's preferred format.
    /// - Parameters:
    ///   - input: Captured microphone buffer.
    ///   - outputFormat: Format returned by `SpeechAnalyzer.bestAvailableAudioFormat`.
    /// - Returns: Converted PCM buffer ready for analysis.
    static func convert(_ input: AVAudioPCMBuffer, to outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        if input.format == outputFormat {
            return input
        }

        guard let converter = AVAudioConverter(from: input.format, to: outputFormat) else {
            throw WordSpeechRecognitionError.notReady
        }

        let ratio = outputFormat.sampleRate / input.format.sampleRate
        let capacity = AVAudioFrameCount((Double(input.frameLength) * ratio).rounded(.up))
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: max(capacity, 1)) else {
            throw WordSpeechRecognitionError.notReady
        }

        var consumedInput = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if consumedInput {
                status.pointee = .noDataNow
                return nil
            }
            consumedInput = true
            status.pointee = .haveData
            return input
        }

        if let error {
            throw error
        }
        return output
    }
}
