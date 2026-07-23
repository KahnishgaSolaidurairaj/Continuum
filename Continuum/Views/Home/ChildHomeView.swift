import SwiftUI
import SwiftData

/// Simplified home screen shown in child mode.
struct ChildHomeView: View {
    let onOpenPracticeWithPriorityFocus: () -> Void
    let onDone: () -> Void

    @Query(sort: \ActivityEngagementRecord.endedAt, order: .reverse)
    private var engagements: [ActivityEngagementRecord]

    @State private var showWarmUpSheet = false
    @State private var motivationMessage = BrocaMotivation.randomMessage()
    @State private var brocaPoseName = BrocaBearCatalog.defaultPose
    @State private var confettiTrigger = 0
    @State private var dailyGoalMinutes = PracticeProgressStore.dailyGoalMinutes

    private var todayPracticeMinutes: Int {
        let seconds = ActivityEngagementAnalytics.engagements(on: .now, records: engagements)
            .reduce(0) { $0 + $1.durationSeconds }
        return max(Int((seconds / 60.0).rounded()), seconds > 0 ? 1 : 0)
    }

    private var goalProgress: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(Double(todayPracticeMinutes) / Double(dailyGoalMinutes), 1.0)
    }

    var body: some View {
        VStack(spacing: 14) {
            primaryActionRow
                .padding(.bottom, 18)

            brocaGoalProgressRow
            HomeMotivationRow(
                motivationMessage: motivationMessage,
                brocaPoseName: brocaPoseName,
                confettiTrigger: confettiTrigger,
                onRefresh: refreshMotivation
            )
            HomeStreakRow()
        }
        .sheet(isPresented: $showWarmUpSheet) {
            WarmUpSheet()
        }
    }

    private var primaryActionRow: some View {
        HStack(spacing: 14) {
            warmUpButton
            practiceFocusButton
        }
    }

    private var warmUpButton: some View {
        Button {
            showWarmUpSheet = true
        } label: {
            Text("Warm up")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.homeMintText)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.78, green: 0.96, blue: 0.82), ContinuumTheme.homeMint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: ContinuumTheme.homeMintText.opacity(0.22), radius: 8, y: 4)
                .fullCapsuleHitTarget()
        }
        .buttonStyle(.plain)
    }

    private var practiceFocusButton: some View {
        Button(action: onOpenPracticeWithPriorityFocus) {
            Text("Practice focus")
                .homePracticeCapsuleStyle()
        }
        .buttonStyle(.plain)
    }

    private var brocaGoalProgressRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(BrocaBearCatalog.goalProgressPose)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .accessibilityLabel("Broca the Bear")

            VStack(alignment: .leading, spacing: 10) {
                Text("Today's goal")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)

                Text("\(todayPracticeMinutes) of \(dailyGoalMinutes) minutes")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.subtitleGray)

                goalProgressBar
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(minWidth: 96, minHeight: 52)
                    .background(ContinuumTheme.testMagenta, in: Capsule())
            }
            .buttonStyle(.plain)
            .contentShape(Capsule())
            .accessibilityLabel("Done practicing")
            .accessibilityHint("Enter parent PIN to return to parent mode")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [ContinuumTheme.homePink, ContinuumTheme.testPinkSoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ContinuumTheme.testMagenta.opacity(0.25), lineWidth: 2)
        )
    }

    /// Thick capsule progress bar for today's practice goal.
    private var goalProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.65))

                Capsule()
                    .fill(ContinuumTheme.testMagenta)
                    .frame(width: max(geometry.size.width * goalProgress, goalProgress > 0 ? 12 : 0))
            }
        }
        .frame(height: 16)
        .accessibilityLabel("Today's goal progress")
        .accessibilityValue("\(Int(goalProgress * 100)) percent")
    }

    /// Shuffles Broca's quote and pose, then triggers confetti.
    private func refreshMotivation() {
        motivationMessage = BrocaMotivation.randomMessage(excluding: motivationMessage)
        brocaPoseName = BrocaBearCatalog.randomPose(excluding: brocaPoseName)
        confettiTrigger += 1
    }
}
