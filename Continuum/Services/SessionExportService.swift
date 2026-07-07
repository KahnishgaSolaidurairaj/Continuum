import Foundation
import SwiftData

/// Exports stored practice sessions for offline ML training pipelines.
enum SessionExportService {
    struct ExportPayload: Codable {
        let sessions: [ExportSession]
    }

    struct ExportSession: Codable {
        let id: UUID
        let targetPhoneme: String
        let timestamp: Date
        let correctness: Int
        let confidence: Double
        let visualFeatures: VisualFeatures
        let audioFeatures: AudioFeatures
        let coachingMessages: [CoachingMessage]
    }

    /// Exports all practice sessions to a JSON file in Documents.
    /// - Parameter modelContext: SwiftData context containing session records.
    /// - Returns: URL of the exported JSON file.
    static func exportAll(modelContext: ModelContext) throws -> URL {
        let descriptor = FetchDescriptor<PracticeSessionRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let records = try modelContext.fetch(descriptor)
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let sessions: [ExportSession] = try records.map { record in
            guard
                let visual = try? decoder.decode(VisualFeatures.self, from: record.visualFeaturesJSON),
                let audio = try? decoder.decode(AudioFeatures.self, from: record.audioFeaturesJSON),
                let messages = try? decoder.decode([CoachingMessage].self, from: record.ruleResultsJSON)
            else {
                throw ExportError.invalidStoredSession(record.id)
            }

            return ExportSession(
                id: record.id,
                targetPhoneme: record.targetPhoneme,
                timestamp: record.timestamp,
                correctness: record.correctness,
                confidence: record.confidence,
                visualFeatures: visual,
                audioFeatures: audio,
                coachingMessages: messages
            )
        }

        let payload = ExportPayload(sessions: sessions)
        let data = try encoder.encode(payload)
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pronunciation_sessions_export.json")
        try data.write(to: url, options: .atomic)
        return url
    }

    enum ExportError: LocalizedError {
        case invalidStoredSession(UUID)

        var errorDescription: String? {
            switch self {
            case .invalidStoredSession(let id):
                return "Could not decode stored session \(id.uuidString)."
            }
        }
    }
}
