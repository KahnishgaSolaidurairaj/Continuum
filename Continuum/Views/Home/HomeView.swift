import SwiftUI

/// Home screen with mascot, practice prompt, streak, and mood logging.
struct HomeView: View {
    let onStartPractice: (PracticeTarget) -> Void
    let onOpenPracticeTab: () -> Void

    @State private var showMoodSheet = false
    @State private var showMotivationSheet = false
    @State private var motivationMessage = BrocaMotivation.randomMessage()
    @State private var selectedMood = PracticeProgressStore.todayMood

    private var suggestedTarget: PracticeTarget {
        if let lastID = PracticeProgressStore.lastPracticeTargetID,
           let match = PracticeTarget.sounds.first(where: { $0.id == lastID }) {
            return match
        }
        return PracticeTarget.sounds[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            topSection
            middleSection
            Spacer(minLength: 0)
        }
        .background(ContinuumTheme.homePink)
        .sheet(isPresented: $showMoodSheet) {
            MoodLogSheet(selectedMood: $selectedMood)
        }
        .sheet(isPresented: $showMotivationSheet) {
            MotivationSheet(message: motivationMessage) {
                motivationMessage = BrocaMotivation.randomMessage()
            }
        }
    }

    private var topSection: some View {
        ZStack(alignment: .top) {
            ContinuumTheme.homePink
                .frame(height: 280)

            HStack {
                Button {
                    showMoodSheet = true
                } label: {
                    Image(systemName: "drop.fill")
                        .font(.title2)
                }
                .accessibilityLabel("Log your mood")

                Spacer()

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.7))
                            .frame(width: 150, height: 150)
                        Image("BrocaBear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .accessibilityLabel("Broca the Bear")
                    }
                    Text("Weekly streak: \(PracticeProgressStore.currentStreak) days")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.55))
                        .clipShape(Capsule())
                }

                Spacer()

                Button {
                    motivationMessage = BrocaMotivation.randomMessage()
                    showMotivationSheet = true
                } label: {
                    Text("motivation")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private var middleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggestion")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("You left off with “\(suggestedTarget.symbol)”. Today let's focus on “\(suggestedTarget.symbol)”")
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text("Today's goal: \(PracticeProgressStore.dailyGoalMinutes) minutes")
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.white.opacity(0.55))
                .clipShape(Capsule())

            if let mood = selectedMood {
                Text("Mood today: \(mood)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button {
                    onStartPractice(suggestedTarget)
                } label: {
                    Text("practice button")
                        .font(.headline.weight(.bold))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 18)
                        .background(.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ContinuumTheme.cardBorder, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ContinuumTheme.homeLavender)
    }
}

/// Broca delivers a quick pep talk from the motivation button.
struct MotivationSheet: View {
    let message: String
    let onAnother: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image("BrocaBear")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text("Broca says…")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(message)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Another one") {
                    onAnother()
                }
                .buttonStyle(.bordered)

                Button("Let's go!") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}

/// Sheet for logging the child's mood before or after practice.
struct MoodLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMood: String?

    private let moods = ["Happy", "Okay", "Frustrated", "Tired", "Excited"]

    var body: some View {
        NavigationStack {
            List(moods, id: \.self) { mood in
                Button(mood) {
                    selectedMood = mood
                    PracticeProgressStore.todayMood = mood
                    dismiss()
                }
            }
            .navigationTitle("Log your mood")
        }
        .presentationDetents([.medium])
    }
}
