import SwiftUI
import SwiftData

/// Home screen with mascot, mood logging, motivation, and practice prompt.
struct HomeView: View {
    let onOpenPracticeTab: () -> Void

    @Query(sort: \ActivityEngagementRecord.endedAt, order: .reverse)
    private var engagements: [ActivityEngagementRecord]

    @State private var showGoalSheet = false
    @State private var motivationMessage = BrocaMotivation.randomMessage()
    @State private var dailyGoalMinutes = PracticeProgressStore.dailyGoalMinutes

    private var latestMood: String? {
        ActivityEngagementAnalytics.latestMoodToday(records: engagements)
    }

    private var suggestedTarget: PracticeTarget {
        if let lastID = PracticeProgressStore.lastPracticeTargetID,
           let match = PracticeTarget.allPhonemes.first(where: { $0.id == lastID }) {
            return match
        }
        return PracticeTarget.allPhonemes[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            topSection
            middleSection
        }
        .background(ContinuumTheme.homePink)
        .sheet(isPresented: $showGoalSheet) {
            DailyGoalSheet(goalMinutes: $dailyGoalMinutes)
        }
    }

    /// Pink header with Broca and the weekly streak.
    private var topSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.75))
                    .frame(width: 170, height: 170)
                Image("BrocaBear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .accessibilityLabel("Broca the Bear")
            }

            Text("Weekly streak: \(PracticeProgressStore.currentStreak) days")
                .font(ContinuumTheme.kidSubheadFont)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.white.opacity(0.65))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .background(ContinuumTheme.homePink)
    }

    /// Lavender content area with mood, motivation, suggestion, goal, and practice.
    private var middleSection: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: 24) {
                    moodSummaryCard

                    HomeMotivationCard(message: motivationMessage) {
                        motivationMessage = BrocaMotivation.randomMessage()
                    } onLetsGo: {
                        withAnimation {
                            scrollProxy.scrollTo("practiceButton", anchor: .center)
                        }
                    }

                    suggestionSection

                    todayGoalButton

                    practiceButton
                        .id("practiceButton")
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ContinuumTheme.homeLavender)
    }

    /// Shows the latest mood logged from a completed practice activity today.
    private var moodSummaryCard: some View {
        HStack(spacing: 14) {
            Text(selectedMoodEmoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Mood")
                    .font(ContinuumTheme.kidButtonFont)
                if let mood = latestMood {
                    Text("Latest: \(mood)")
                        .font(ContinuumTheme.kidCaptionFont)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Finish an activity to log how you feel")
                        .font(ContinuumTheme.kidCaptionFont)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ContinuumTheme.cardBorder.opacity(0.2), lineWidth: 2)
        )
        .accessibilityLabel(latestMood.map { "Today's mood: \($0)" } ?? "No mood logged yet today")
    }

    private var selectedMoodEmoji: String {
        guard let latestMood else { return "😊" }
        return MoodChoice.emoji(for: latestMood)
    }

    /// Shows the suggested sound to practice today.
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggestion")
                .font(ContinuumTheme.kidCaptionFont)
                .foregroundStyle(.secondary)

            Text("You left off with “\(suggestedTarget.symbol)”. Today let's focus on “\(suggestedTarget.symbol)”")
                .font(ContinuumTheme.kidBodyFont.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Opens the goal sheet so the child can set today's practice target.
    private var todayGoalButton: some View {
        Button {
            showGoalSheet = true
        } label: {
            HStack {
                Label {
                    Text("Today's goal: \(dailyGoalMinutes) minutes")
                        .font(ContinuumTheme.kidSubheadFont)
                } icon: {
                    Image(systemName: "target")
                        .font(.title2)
                }

                Spacer()

                Text("Change")
                    .font(ContinuumTheme.kidButtonFont)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
            .background(.white.opacity(0.65))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change today's goal")
    }

    /// Centered call-to-action to start practicing.
    private var practiceButton: some View {
        Button {
            onOpenPracticeTab()
        } label: {
            Text("Practice")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .padding(.horizontal, 48)
                .padding(.vertical, 22)
                .frame(minWidth: 220, minHeight: 72)
                .background(.white.opacity(0.92))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(ContinuumTheme.cardBorder, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

/// Inline motivation card shown when the home screen opens.
struct HomeMotivationCard: View {
    let message: String
    let onAnother: () -> Void
    let onLetsGo: () -> Void

    @State private var confettiTrigger = 0

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                Image("BrocaBear")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Text("Broca says…")
                    .font(ContinuumTheme.kidSubheadFont)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(ContinuumTheme.kidBodyFont.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 14) {
                    Button("Another one", action: onAnother)
                        .kidSecondaryButtonStyle()
                        .frame(maxWidth: .infinity)

                    Button("Let's go!") {
                        confettiTrigger += 1
                        onLetsGo()
                    }
                    .kidPrimaryButtonStyle()
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(ContinuumTheme.cardBorder.opacity(0.15), lineWidth: 2)
            )

            ConfettiEmojiBurst(trigger: confettiTrigger)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }
}

/// Bursts confetti emojis across the motivation card when triggered.
private struct ConfettiEmojiBurst: View {
    let trigger: Int

    private let emojis = ["🎉", "🎊", "✨", "🎈", "⭐", "🌟"]

    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    Text(piece.emoji)
                        .font(.system(size: piece.fontSize))
                        .rotationEffect(.degrees(piece.rotation))
                        .offset(x: piece.offsetX, y: piece.offsetY)
                        .opacity(piece.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: trigger) { _, _ in
                launchConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    /// Spawns and animates confetti emoji particles from the card center.
    private func launchConfetti(in size: CGSize) {
        _ = size

        pieces = (0..<18).map { index in
            let angle = (Double(index) / 18.0) * (.pi * 2)
            let spread = CGFloat.random(in: 70...150)
            return ConfettiPiece(
                emoji: emojis[index % emojis.count],
                fontSize: CGFloat.random(in: 22...34),
                offsetX: 0,
                offsetY: 0,
                targetOffsetX: cos(angle) * spread,
                targetOffsetY: sin(angle) * spread - 30,
                rotation: 0,
                targetRotation: Double.random(in: -180...180),
                opacity: 1
            )
        }

        withAnimation(.easeOut(duration: 1.1)) {
            pieces = pieces.map { piece in
                var updated = piece
                updated.offsetX = piece.targetOffsetX
                updated.offsetY = piece.targetOffsetY
                updated.rotation = piece.targetRotation
                updated.opacity = 0
                return updated
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            pieces = []
        }
    }
}

/// A single animated confetti emoji particle.
private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let emoji: String
    let fontSize: CGFloat
    var offsetX: CGFloat
    var offsetY: CGFloat
    let targetOffsetX: CGFloat
    let targetOffsetY: CGFloat
    var rotation: Double
    let targetRotation: Double
    var opacity: Double
}

/// Sheet for setting the daily practice goal in minutes.
struct DailyGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goalMinutes: Int

    private let goalOptions = [5, 10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 14) {
                    Text("How many minutes do you want to practice today?")
                        .font(ContinuumTheme.kidBodyFont)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)

                    ForEach(goalOptions, id: \.self) { minutes in
                        Button {
                            goalMinutes = minutes
                            PracticeProgressStore.dailyGoalMinutes = minutes
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(minutes) minutes")
                                    .font(ContinuumTheme.kidBodyFont.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Spacer()

                                if goalMinutes == minutes {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(ContinuumTheme.tabPurple)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .kidChoiceButtonStyle(isSelected: goalMinutes == minutes)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(24)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
            .background(ContinuumTheme.homeLavender)
            .kidFriendlyNavigationTitle("Today's Goal")
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
