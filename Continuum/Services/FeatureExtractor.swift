import Foundation

/// Converts raw face and audio samples into attempt-level features.
enum FeatureExtractor {
    /// Aggregates visual measurements from tracked face frames.
    /// - Parameter frames: Timestamped ARKit frames for one attempt.
    /// - Returns: Visual feature summary.
    static func extractVisual(from frames: [FaceFrame]) -> VisualFeatures {
        guard !frames.isEmpty else {
            return VisualFeatures(
                maximumJawOpen: 0,
                averageJawOpen: 0,
                maximumMouthClose: 0,
                averageMouthClose: 0,
                lipRounding: 0,
                lipSpread: 0,
                mouthSymmetry: 0,
                headMovement: 0,
                tongueVisibility: 0,
                motionSpeed: 0,
                frameCount: 0
            )
        }

        let jawValues = frames.map(\.jawOpen)
        let closeValues = frames.map(\.mouthClose)
        let roundingValues = frames.map { ($0.mouthFunnel + $0.mouthPucker) / 2 }
        let spreadValues = frames.map { ($0.mouthSmileLeft + $0.mouthSmileRight) / 2 }
        let symmetryValues = frames.map { abs($0.mouthSmileLeft - $0.mouthSmileRight) }
        let tongueValues = frames.map(\.tongueOut)

        let headYaw = frames.map(\.headYaw)
        let headPitch = frames.map(\.headPitch)
        let headRoll = frames.map(\.headRoll)
        let headMovement = combinedRange(headYaw) + combinedRange(headPitch) + combinedRange(headRoll)

        let motionSpeed = averageFrameDelta(for: frames)

        return VisualFeatures(
            maximumJawOpen: jawValues.max() ?? 0,
            averageJawOpen: average(jawValues),
            maximumMouthClose: closeValues.max() ?? 0,
            averageMouthClose: average(closeValues),
            lipRounding: average(roundingValues),
            lipSpread: average(spreadValues),
            mouthSymmetry: average(symmetryValues),
            headMovement: headMovement,
            tongueVisibility: tongueValues.max() ?? 0,
            motionSpeed: motionSpeed,
            frameCount: frames.count
        )
    }

    /// Aggregates audio measurements from captured microphone chunks.
    /// - Parameter chunks: Timestamped audio chunks for one attempt.
    /// - Returns: Audio feature summary.
    static func extractAudio(from chunks: [AudioChunk]) -> AudioFeatures {
        guard let firstChunk = chunks.first, !chunks.isEmpty else {
            return AudioFeatures(
                duration: 0,
                rmsEnergy: 0,
                peakEnergy: 0,
                zeroCrossingRate: 0,
                voicedEnergyRatio: 0,
                burstPeak: 0,
                sampleRate: 44_100
            )
        }

        let allSamples = chunks.flatMap(\.samples)
        guard !allSamples.isEmpty else {
            return AudioFeatures(
                duration: 0,
                rmsEnergy: 0,
                peakEnergy: 0,
                zeroCrossingRate: 0,
                voicedEnergyRatio: 0,
                burstPeak: 0,
                sampleRate: firstChunk.sampleRate
            )
        }

        let duration = Double(allSamples.count) / firstChunk.sampleRate
        let rms = rootMeanSquare(allSamples)
        let peak = allSamples.map(abs).max() ?? 0
        let zcr = zeroCrossingRate(allSamples)
        let voicedRatio = voicedEnergyRatio(allSamples, sampleRate: firstChunk.sampleRate)
        let burstPeak = burstPeakEnergy(chunks: chunks)

        return AudioFeatures(
            duration: duration,
            rmsEnergy: rms,
            peakEnergy: peak,
            zeroCrossingRate: zcr,
            voicedEnergyRatio: voicedRatio,
            burstPeak: burstPeak,
            sampleRate: firstChunk.sampleRate
        )
    }

    private static func average(_ values: [Float]) -> Float {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Float(values.count)
    }

    private static func combinedRange(_ values: [Float]) -> Float {
        guard let minValue = values.min(), let maxValue = values.max() else { return 0 }
        return maxValue - minValue
    }

    private static func averageFrameDelta(for frames: [FaceFrame]) -> Float {
        guard frames.count > 1 else { return 0 }

        var totalDelta: Float = 0
        for index in 1..<frames.count {
            let previous = frames[index - 1]
            let current = frames[index]
            totalDelta += abs(current.jawOpen - previous.jawOpen)
            totalDelta += abs(current.mouthClose - previous.mouthClose)
        }

        return totalDelta / Float(frames.count - 1)
    }

    private static func rootMeanSquare(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let sumSquares = samples.reduce(0) { $0 + ($1 * $1) }
        return sqrt(sumSquares / Float(samples.count))
    }

    private static func zeroCrossingRate(_ samples: [Float]) -> Float {
        guard samples.count > 1 else { return 0 }
        var crossings = 0
        for index in 1..<samples.count {
            let previous = samples[index - 1]
            let current = samples[index]
            if (previous >= 0 && current < 0) || (previous < 0 && current >= 0) {
                crossings += 1
            }
        }
        return Float(crossings) / Float(samples.count - 1)
    }

    private static func voicedEnergyRatio(_ samples: [Float], sampleRate: Double) -> Float {
        let windowSize = max(256, Int(sampleRate * 0.02))
        guard samples.count >= windowSize else { return 0 }

        var voicedWindows = 0
        var totalWindows = 0

        var start = 0
        while start + windowSize <= samples.count {
            let window = Array(samples[start..<(start + windowSize)])
            let zcr = zeroCrossingRate(window)
            if zcr < 0.12 && rootMeanSquare(window) > 0.01 {
                voicedWindows += 1
            }
            totalWindows += 1
            start += windowSize
        }

        guard totalWindows > 0 else { return 0 }
        return Float(voicedWindows) / Float(totalWindows)
    }

    private static func burstPeakEnergy(chunks: [AudioChunk]) -> Float {
        guard !chunks.isEmpty else { return 0 }

        let windowSize = 256
        var peak: Float = 0

        for chunk in chunks {
            let samples = chunk.samples
            guard samples.count >= windowSize else { continue }

            var start = 0
            while start + windowSize <= samples.count {
                let window = Array(samples[start..<(start + windowSize)])
                peak = max(peak, rootMeanSquare(window))
                start += windowSize / 2
            }
        }

        return peak
    }

    /// Returns the fraction of sample windows above an RMS threshold.
    /// - Parameters:
    ///   - chunks: Captured microphone chunks for one attempt.
    ///   - threshold: RMS threshold used to detect active audio.
    /// - Returns: Ratio of active windows in `0...1`.
    static func activeSpeechRatio(
        from chunks: [AudioChunk],
        threshold: Float = 0.01
    ) -> Float {
        guard let firstChunk = chunks.first else { return 0 }

        let samples = chunks.flatMap(\.samples)
        let sampleRate = firstChunk.sampleRate
        let window = max(256, Int(sampleRate * 0.01))
        guard samples.count >= window else { return 0 }

        let step = max(1, window / 2)
        var activeWindows = 0
        var totalWindows = 0

        var start = 0
        while start + window <= samples.count {
            let windowSamples = samples[start..<(start + window)]
            let sumSquares = windowSamples.reduce(Float.zero) { partial, sample in
                partial + sample * sample
            }
            let windowRMS = sqrt(sumSquares / Float(windowSamples.count))
            if windowRMS >= threshold {
                activeWindows += 1
            }
            totalWindows += 1
            start += step
        }

        guard totalWindows > 0 else { return 0 }
        return Float(activeWindows) / Float(totalWindows)
    }

    /// Returns the fraction of samples at or above a saturation ceiling.
    /// - Parameters:
    ///   - chunks: Captured microphone chunks for one attempt.
    ///   - ceiling: Absolute sample level treated as hard saturation.
    /// - Returns: Ratio of saturated samples in `0...1`.
    static func saturationRatio(from chunks: [AudioChunk], ceiling: Float = 0.999) -> Float {
        let samples = chunks.flatMap(\.samples)
        guard !samples.isEmpty else { return 0 }

        let saturatedCount = samples.reduce(into: 0) { count, sample in
            if abs(sample) >= ceiling {
                count += 1
            }
        }
        return Float(saturatedCount) / Float(samples.count)
    }
}
