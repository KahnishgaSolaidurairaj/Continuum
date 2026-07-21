import SwiftUI
import SwiftData

/// Home screen with mascot hero, suggestions grid, motivation, and practice prompts.
struct HomeView: View {
    let onOpenPracticeTab: () -> Void
    let onOpenPracticeWithPriorityFocus: () -> Void

    @Query(sort: \ActivityEngagementRecord.endedAt, order: .reverse)
    private var engagements: [ActivityEngagementRecord]

    @State private var showGoalSheet = false
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

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [ContinuumTheme.homePink, ContinuumTheme.homeOffWhite],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroHeader
                    mainPanel
                        .padding(.horizontal, ContinuumTheme.pageHorizontalPadding)
                        .padding(.top, -20)
                }
                .padding(.bottom, ContinuumTabBar.contentBottomPadding)
            }
        }
        .sheet(isPresented: $showGoalSheet) {
            DailyGoalSheet(goalMinutes: $dailyGoalMinutes)
        }
        .sheet(isPresented: $showWarmUpSheet) {
            WarmUpSheet()
        }
    }

    /// Hills header with welcome copy and Broca mascot.
    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            HomeHillsBackground()

            GeometryReader { geometry in
                let mascotSize = min(geometry.size.width * 0.38, 196)

                HStack(alignment: .bottom, spacing: 6) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .foregroundStyle(ContinuumTheme.pencilLead)

                        Text("Continuum")
                            .font(.system(size: 68, weight: .bold, design: .rounded))
                            .foregroundStyle(ContinuumTheme.pencilLead)
                            .shadow(color: .white.opacity(0.9), radius: 0, x: 1, y: 1)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        Text("Continue therapy at home")
                            .font(.system(size: 26, weight: .medium, design: .rounded))
                            .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(BrocaBearCatalog.defaultPose)
                        .resizable()
                        .scaledToFit()
                        .frame(width: mascotSize, height: mascotSize)
                        .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
                        .accessibilityLabel("Broca the Bear")
                }
                .padding(.horizontal, ContinuumTheme.pageHorizontalPadding)
                .padding(.bottom, 30)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            }
        }
        .frame(height: 270)
        .frame(maxWidth: .infinity)
    }

    /// White rounded panel with actions, suggestions, motivation, and streak.
    private var mainPanel: some View {
        VStack(spacing: 14) {
            primaryActionRow
            suggestionsSection
            motivationRow
            streakRow
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(homePanelBackground(shadowY: -6))
    }

    /// Shared rounded white background used for the home page panel.
    private func homePanelBackground(shadowY: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(Color.white.opacity(0.98))
            .shadow(color: ContinuumTheme.tabPurple.opacity(0.12), radius: 16, y: shadowY)
    }

    /// Warm up and practice call-to-action buttons from the mockup.
    private var primaryActionRow: some View {
        HStack(spacing: 14) {
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
            }
            .buttonStyle(.plain)

            Button {
                onOpenPracticeTab()
            } label: {
                Text("Practice Sounds")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.tabPurple)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(
                        LinearGradient(
                            colors: [ContinuumTheme.homeLavender, Color(red: 0.80, green: 0.72, blue: 0.98)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: ContinuumTheme.tabPurple.opacity(0.2), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    /// 2x2 suggestions grid with quick actions.
    private var suggestionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Suggestions", systemImage: "sparkles")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                Spacer()
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                HomeSuggestionCard(
                    icon: "target",
                    title: "Practice focus",
                    description: "Jump to your priority sounds",
                    buttonTitle: "Continue",
                    tint: .purple,
                    action: onOpenPracticeWithPriorityFocus
                )

                HomeSuggestionCard(
                    icon: "flag.fill",
                    title: "Today's goal",
                    description: "\(todayPracticeMinutes) of \(dailyGoalMinutes) minutes",
                    buttonTitle: "Change goal",
                    tint: .blue,
                    action: { showGoalSheet = true }
                )
            }
        }
    }

    /// Quote row with mascot thumbnail and motivation refresh.
    private var motivationRow: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(brocaPoseName)
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .accessibilityLabel("Broca the Bear")
                .animation(.spring(response: 0.35, dampingFraction: 0.72), value: brocaPoseName)

            HStack(alignment: .top, spacing: 8) {
                Text("“")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.tabPurple.opacity(0.7))
                    .offset(y: -10)

                Text(motivationMessage)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Button(action: refreshMotivation) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                    Text("Motivation!")
                }
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(minHeight: ContinuumTheme.kidMinTapHeight)
                .background(
                    LinearGradient(
                        colors: [ContinuumTheme.tabPurple, Color(red: 0.68, green: 0.52, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: ContinuumTheme.tabPurple.opacity(0.28), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [ContinuumTheme.homeLavender.opacity(0.7), ContinuumTheme.homePink.opacity(0.45)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            ConfettiBurstView(trigger: confettiTrigger)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }

    /// Shuffles Broca's quote and pose, then triggers confetti.
    private func refreshMotivation() {
        motivationMessage = BrocaMotivation.randomMessage(excluding: motivationMessage)
        brocaPoseName = BrocaBearCatalog.randomPose(excluding: brocaPoseName)
        confettiTrigger += 1
    }

    /// Streak tracker with recent day checkmarks.
    private var streakRow: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.78, green: 0.96, blue: 0.82), ContinuumTheme.homeMint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                Image(systemName: "flame.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(ContinuumTheme.homeMintText)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("\(PracticeProgressStore.currentStreak) day streak")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                Text("Keep it up! You're doing great.")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 12) {
                ForEach(streakDayIndicators.indices, id: \.self) { index in
                    let practiced = streakDayIndicators[index]
                    ZStack {
                        Circle()
                            .fill(practiced ? ContinuumTheme.homeMint : Color.white)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(
                                        practiced ? ContinuumTheme.homeMintText.opacity(0.5) : Color.gray.opacity(0.25),
                                        lineWidth: 2
                                    )
                            )
                        if practiced {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(ContinuumTheme.homeMintText)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ContinuumTheme.sandboxMintSoft.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(ContinuumTheme.homeMint.opacity(0.85), lineWidth: 2.5)
        )
        .shadow(color: ContinuumTheme.homeMintText.opacity(0.14), radius: 8, y: 4)
    }

    /// Five streak slots filled left-to-right based on the current streak count.
    private var streakDayIndicators: [Bool] {
        let filledCount = min(PracticeProgressStore.currentStreak, 5)
        return (0..<5).map { index in
            index < filledCount
        }
    }
}

/// Soft hills layered on the home page gradient — no separate background fill.
private struct HomeHillsBackground: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            HomeHillShape()
                .fill(Color(red: 0.95, green: 0.80, blue: 0.78).opacity(0.55))
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .offset(y: 18)

            HomeHillShape()
                .fill(Color(red: 0.88, green: 0.72, blue: 0.70).opacity(0.38))
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .scaleEffect(x: -1, y: 1)
                .offset(y: 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .clipped()
    }
}

/// Simple rolling hill used behind the home hero.
private struct HomeHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.25, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.72, y: rect.maxY * 0.45)
        )
        path.closeSubpath()
        return path
    }
}

/// One suggestion tile in the home 2x2 grid.
private struct HomeSuggestionCard: View {
    enum Tint {
        case purple
        case green
        case blue
    }

    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let tint: Tint
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.22))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.pencilLead)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(description)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.75))
                        .lineLimit(4)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Button(buttonTitle, action: action)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(accentColor)
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.16), accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.28), lineWidth: 2)
        )
        .shadow(color: accentColor.opacity(0.14), radius: 6, y: 3)
    }

    private var accentColor: Color {
        switch tint {
        case .green:
            ContinuumTheme.homeMintText
        case .purple:
            ContinuumTheme.tabPurple
        case .blue:
            ContinuumTheme.stormBlue
        }
    }
}

/// Sheet for setting the daily practice goal in minutes.
struct DailyGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goalMinutes: Int

    private let goalOptions = [5, 10, 15, 20, 30]

    var body: some View {
        ZStack {
            ContinuumTheme.homeLavender
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("Today's Goal")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .foregroundStyle(ContinuumTheme.tabPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

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
            .continuumSheetInset()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
