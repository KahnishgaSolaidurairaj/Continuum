import SwiftUI
import SwiftData

/// Simplified home screen shown in child mode.
struct ChildHomeView: View {
    let onOpenPracticeWithPriorityFocus: () -> Void
    let onDone: () -> Void

    @Environment(\.continuumDeviceLayout) private var layout

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
        Group {
            if layout.isPhone {
                VStack(spacing: 14) {
                    warmUpButton
                    practiceFocusButton
                }
            } else {
                HStack(spacing: 14) {
                    warmUpButton
                    practiceFocusButton
                }
            }
        }
    }

    private var warmUpButton: some View {
        Button {
            showWarmUpSheet = true
        } label: {
            Text("Warm up")
                .font(layout.font(24, phoneSize: 20, weight: .bold))
                .foregroundStyle(ContinuumTheme.homeMintText)
                .frame(maxWidth: .infinity, minHeight: layout.scaled(64, phone: 52))
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
        Group {
            if layout.isPhone {
                phoneGoalProgressRow
            } else {
                padGoalProgressRow
            }
        }
        .padding(layout.scaled(18, phone: 14))
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

    private var padGoalProgressRow: some View {
        HStack(alignment: .center, spacing: 12) {
            goalBrocaImage

            VStack(alignment: .leading, spacing: 10) {
                goalTextContent
                goalProgressBar
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            doneButton
        }
    }

    private var phoneGoalProgressRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                goalBrocaImage
                goalTextContent
            }

            goalProgressBar

            doneButton
                .frame(maxWidth: .infinity)
        }
    }

    private var goalBrocaImage: some View {
        Image(BrocaBearCatalog.goalProgressPose)
            .resizable()
            .scaledToFit()
            .frame(width: layout.scaled(80, phone: 64), height: layout.scaled(80, phone: 64))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            .accessibilityLabel("Broca the Bear")
    }

    private var goalTextContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's goal")
                .font(layout.font(22, phoneSize: 18, weight: .bold))
                .foregroundStyle(ContinuumTheme.pencilLead)

            Text("\(todayPracticeMinutes) of \(dailyGoalMinutes) minutes")
                .font(layout.font(18, phoneSize: 15, weight: .semibold))
                .foregroundStyle(ContinuumTheme.subtitleGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Done")
                .font(layout.font(18, phoneSize: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(minWidth: layout.isPhone ? nil : 96, minHeight: layout.scaled(52, phone: 48))
                .frame(maxWidth: layout.isPhone ? .infinity : nil)
                .padding(.horizontal, layout.isPhone ? 16 : 0)
                .background(ContinuumTheme.testMagenta, in: Capsule())
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .accessibilityLabel("Done practicing")
        .accessibilityHint("Enter parent PIN to return to parent mode")
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
