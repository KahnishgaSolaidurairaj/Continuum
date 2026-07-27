import SwiftUI

/// A mood option with emoji icon for visual selection.
struct MoodChoice: Identifiable {
    let id: String
    let label: String
    let emoji: String

    static let all: [MoodChoice] = [
        MoodChoice(id: "Happy", label: "Happy", emoji: "😊"),
        MoodChoice(id: "Okay", label: "Okay", emoji: "🙂"),
        MoodChoice(id: "Frustrated", label: "Frustrated", emoji: "😤"),
        MoodChoice(id: "Tired", label: "Tired", emoji: "😴"),
        MoodChoice(id: "Excited", label: "Excited", emoji: "🤩")
    ]

    /// Returns the emoji for a stored mood label.
    /// - Parameter label: The saved mood label.
    /// - Returns: Matching emoji or a default smile.
    static func emoji(for label: String) -> String {
        all.first(where: { $0.label == label })?.emoji ?? "😊"
    }
}

/// Sheet shown when a child finishes a practice activity.
struct ActivityMoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.continuumDeviceLayout) private var layout

    let onComplete: (String?) -> Void

    var body: some View {
        ZStack {
            ContinuumTheme.homeLavender
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("How did you feel?")
                    .font(ContinuumTheme.kidSectionHeaderFont(for: layout))
                    .foregroundStyle(ContinuumTheme.tabPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                ForEach(MoodChoice.all) { mood in
                    Button {
                        onComplete(mood.label)
                        dismiss()
                    } label: {
                        moodRow(label: mood.label, emoji: mood.emoji, isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }

                Button {
                    onComplete(nil)
                    dismiss()
                } label: {
                    Text("Skip")
                        .font(ContinuumTheme.kidButtonFont(for: layout))
                        .foregroundStyle(ContinuumTheme.stormBlue)
                        .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight(for: layout))
                        .background(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(24)
            .continuumSheetInset()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func moodRow(label: String, emoji: String, isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: layout.scaled(40, phone: 32)))

            Text(label)
                .font(ContinuumTheme.kidBodyFont(for: layout).weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .kidChoiceButtonStyle(isSelected: isSelected)
    }
}
