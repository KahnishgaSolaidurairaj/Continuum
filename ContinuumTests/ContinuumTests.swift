//
//  ContinuumTests.swift
//  ContinuumTests
//

import Foundation
import Testing
@testable import Continuum

struct ContinuumTests {

    @Test func wordRecognitionScorerAcceptsExactMatchWithConfidence() {
        let score = WordRecognitionScorer.score(
            WordRecognitionScorer.Input(
                targetWord: "Map",
                transcript: "map",
                confidence: 0.86
            )
        )

        #expect(score.correctness == 86)
        #expect(score.scoringMethod == .speechRecognition)
        #expect(score.messages.first?.severity == .good)
    }

    @Test func wordRecognitionScorerPenalizesWrongWord() {
        let score = WordRecognitionScorer.score(
            WordRecognitionScorer.Input(
                targetWord: "Map",
                transcript: "dog",
                confidence: 0.8
            )
        )

        #expect(score.correctness <= 15)
        #expect(score.messages.first?.text.contains("Map") == true)
    }

    @Test func wordRecognitionScorerAllowsCloseSingleTokenMatch() {
        #expect(WordRecognitionScorer.matchesTarget("map", heard: "nap"))
        #expect(!WordRecognitionScorer.matchesTarget("map", heard: "cat"))
    }

    @Test func manifestProvidesFifteenWordsPerLevel() throws {
        let jsonURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Continuum/Resources/PracticeSoundsManifest.json")

        let data = try Data(contentsOf: jsonURL)
        let manifest = try JSONDecoder().decode(PracticeSoundsManifest.self, from: data)

        #expect(manifest.version == 2)
        #expect(manifest.sounds.count == 44)
        for sound in manifest.sounds {
            #expect(sound.level2Words.count == 15)
            #expect(sound.level3Words.count == 15)
        }
    }

    @Test func flashWordBankTestWordsCombineLevelTwoAndThree() {
        guard let sound = PracticeSoundCatalog.allSounds.first else {
            Issue.record("Expected at least one practice sound")
            return
        }
        let target = PracticeTarget(id: sound.id, practiceSound: sound)
        let words = FlashWordBank.testWords(for: target)

        #expect(words.count == 30)
        #expect(words.prefix(15).allSatisfy { word in
            sound.level2Examples.contains { $0.word == word }
        })
    }

    @Test func activeSpeechRatioIsLowForNearSilentAudio() {
        let silentSamples = Array(repeating: Float(0.0001), count: 8_820)
        let chunk = AudioChunk(timestamp: 0, samples: silentSamples, sampleRate: 44_100)
        let ratio = FeatureExtractor.activeSpeechRatio(from: [chunk], threshold: 0.01)
        #expect(ratio < 0.12)
    }

    @Test func dashboardAnalyticsFiltersAccuracyBySoundGroup() {
        let today = Calendar.current.startOfDay(for: .now)
        let sessions = [
            makeSession(phoneme: "ae", soundID: "short_a", correctness: 70, on: today),
            makeSession(phoneme: "m", soundID: "m", correctness: 90, on: today)
        ]

        let vowelSeries = DashboardAnalytics.accuracySeries(
            on: today,
            from: sessions,
            group: .vowel,
            soundID: nil
        )
        let consonantSeries = DashboardAnalytics.accuracySeries(
            on: today,
            from: sessions,
            group: .consonant,
            soundID: nil
        )

        #expect(vowelSeries.count == 1)
        #expect(vowelSeries.first?.percent == 70)
        #expect(consonantSeries.count == 1)
        #expect(consonantSeries.first?.percent == 90)
    }

    @Test func topPracticedSoundsReturnsFiveMostVisitedSounds() {
        let today = Calendar.current.startOfDay(for: .now)
        let engagements = [
            makeEngagement(soundID: "m", on: today),
            makeEngagement(soundID: "m", on: today),
            makeEngagement(soundID: "short_a", on: today),
            makeEngagement(soundID: "f", on: today),
            makeEngagement(soundID: "f", on: today),
            makeEngagement(soundID: "f", on: today),
            makeEngagement(soundID: "s", on: today),
            makeEngagement(soundID: "b", on: today),
            makeEngagement(soundID: "t", on: today)
        ]

        let topSounds = DashboardAnalytics.topPracticedSounds(on: today, from: engagements, limit: 5)

        #expect(topSounds.count == 5)
        #expect(topSounds.first?.soundID == "f")
        #expect(topSounds.first?.visitCount == 3)
    }

    @Test func strengthsAndNeedsUseRollingAverageCorrectness() {
        let today = Calendar.current.startOfDay(for: .now)
        let sessions = [
            makeSession(phoneme: "m", soundID: "m", correctness: 90, on: today),
            makeSession(phoneme: "m", soundID: "m", correctness: 88, on: today),
            makeSession(phoneme: "s", soundID: "s", correctness: 40, on: today),
            makeSession(phoneme: "s", soundID: "s", correctness: 35, on: today)
        ]

        let result = DashboardAnalytics.strengthsAndNeeds(from: sessions, lastDays: 7, referenceDate: today)

        #expect(result.strengths.first?.phonemeLabel == "m")
        #expect(result.needs.first?.phonemeLabel == "s")
    }

    private func makeSession(
        phoneme: String,
        soundID: String,
        correctness: Int,
        on date: Date
    ) -> PracticeSessionRecord {
        PracticeSessionRecord(
            targetPhoneme: phoneme,
            targetSoundID: soundID,
            timestamp: date.addingTimeInterval(60),
            correctness: correctness,
            confidence: 0.8,
            coachingSummary: "Test",
            audioFeaturesJSON: Data(),
            ruleResultsJSON: Data()
        )
    }

    private func makeEngagement(soundID: String, on date: Date) -> ActivityEngagementRecord {
        ActivityEngagementRecord(
            activityRawValue: PracticeActivity.flash.rawValue,
            targetSoundID: soundID,
            startedAt: date,
            endedAt: date.addingTimeInterval(120),
            durationSeconds: 120
        )
    }
}
