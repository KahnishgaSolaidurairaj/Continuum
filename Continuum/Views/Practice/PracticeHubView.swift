import SwiftUI
import SwiftData

/// Practice tab entry: pick a target, browse activities, launch one full-screen.
struct PracticeHubView: View {
    @State private var selectedTarget: PracticeTarget?
    @State private var activeActivity: PracticeActivity?

    var body: some View {
        NavigationStack {
            Group {
                if let target = selectedTarget {
                    ActivityCarouselView(
                        target: target,
                        onSelectActivity: { activity in
                            activeActivity = activity
                        },
                        onBack: {
                            selectedTarget = nil
                        }
                    )
                } else {
                    PhonemeSelectionView { target in
                        selectedTarget = target
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ContinuumTheme.practiceCream)
            .navigationDestination(item: $activeActivity) { activity in
                if let target = selectedTarget {
                    ActivityDetailView(target: target, activity: activity)
                }
            }
        }
    }
}

/// Wireframe step 1: choose one of the 44 English sounds.
struct PhonemeSelectionView: View {
    let onSelect: (PracticeTarget) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columnCount: Int {
        horizontalSizeClass == .compact ? 2 : 4
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Which sound?")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .frame(maxWidth: .infinity)

                soundSection(title: "Vowels", sounds: PracticeSoundCatalog.vowels)
                soundSection(title: "Consonants", sounds: PracticeSoundCatalog.consonants)
                soundSection(title: "Vowel Teams", sounds: PracticeSoundCatalog.vowelTeams)
            }
            .padding()
        }
    }

    private func soundSection(title: String, sounds: [PracticeSound]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.tabPurple)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount), spacing: 12) {
                ForEach(sounds) { sound in
                    Button {
                        onSelect(PracticeTarget(id: sound.id, practiceSound: sound))
                    } label: {
                        VStack(spacing: 8) {
                            Text(sound.displayName)
                                .font(ContinuumTheme.kidCaptionFont.weight(.bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            HighlightedWordText(
                                word: sound.level1Example.word,
                                highlights: sound.level1Example.highlights,
                                font: ContinuumTheme.kidSubheadFont,
                                baseColor: .primary,
                                highlightColor: ContinuumTheme.tabPurple
                            )
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .background(.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ContinuumTheme.cardBorder.opacity(0.35), lineWidth: 2)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(sound.displayName), as in \(sound.primaryExample)")
                }
            }
        }
    }
}

/// Wireframe step 2: activity picker for the selected target.
struct ActivityCarouselView: View {
    let target: PracticeTarget
    let onSelectActivity: (PracticeActivity) -> Void
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var usesColumnLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 6) {
                headerSection

                if usesColumnLayout {
                    VStack(spacing: 8) {
                        ForEach(PracticeActivity.allCases) { activity in
                            Button {
                                onSelectActivity(activity)
                            } label: {
                                activityTile(
                                    for: activity,
                                    layout: .column,
                                    fillsAvailableSpace: true
                                )
                            }
                            .buttonStyle(.plain)
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    let activities = PracticeActivity.allCases
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            gameButton(for: activities[0], layout: .grid)
                            gameButton(for: activities[1], layout: .grid)
                        }
                        .frame(maxHeight: .infinity)

                        HStack(spacing: 10) {
                            gameButton(for: activities[2], layout: .grid)
                            gameButton(for: activities[3], layout: .grid)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 12)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                }
                Spacer()
            }

            Text("Practice \(target.displayLabel)")
                .font(.system(size: usesColumnLayout ? 26 : 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            phonemePreviewCard(
                cardHeight: usesColumnLayout ? 56 : 96,
                symbolSize: usesColumnLayout ? 32 : 46
            )

            Text("Choose an activity")
                .font(.system(size: usesColumnLayout ? 21 : 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func gameButton(for activity: PracticeActivity, layout: ActivityTileLayout) -> some View {
        Button {
            onSelectActivity(activity)
        } label: {
            activityTile(
                for: activity,
                layout: layout,
                fillsAvailableSpace: true
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Large preview card showing the practice phoneme; tap to return to sound selection.
    private func phonemePreviewCard(cardHeight: CGFloat, symbolSize: CGFloat) -> some View {
        Button(action: onBack) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [.white, ContinuumTheme.homeLavender.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(ContinuumTheme.tabPurple.opacity(0.18), lineWidth: 2)
                    )
                    .shadow(color: ContinuumTheme.tabPurple.opacity(0.12), radius: 8, y: 4)

                Text(target.traceCharacter.uppercased())
                    .font(.system(size: symbolSize, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to all sounds")
        .accessibilityHint("Returns to the sound selection screen")
    }

    private enum ActivityTileLayout {
        case grid
        case column
    }

    /// One colored activity option in the practice picker.
    private func activityTile(
        for activity: PracticeActivity,
        layout: ActivityTileLayout,
        fillsAvailableSpace: Bool = false
    ) -> some View {
        let theme = ActivityTileTheme.theme(for: activity)
        let iconSize: CGFloat = layout == .grid ? 40 : 38
        let titleFont: Font = .system(size: layout == .column ? 24 : 22, weight: .bold, design: .rounded)
        let subtitleFont: Font = .system(size: layout == .column ? 17 : 16, weight: .semibold, design: .rounded)

        let tileContent = Group {
            switch layout {
            case .grid:
                VStack(spacing: 10) {
                    iconBadge(systemName: activity.systemImage, size: iconSize, theme: theme)
                    Text(activity.subtitle)
                        .font(titleFont)
                    Text(activity.title)
                        .font(subtitleFont)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .column:
                HStack(spacing: 14) {
                    iconBadge(systemName: activity.systemImage, size: iconSize, theme: theme)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.subtitle)
                            .font(titleFont)
                        Text(activity.title)
                            .font(subtitleFont)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(theme.foreground)

        return tileContent
            .frame(maxWidth: .infinity)
            .frame(maxHeight: fillsAvailableSpace ? .infinity : nil)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.fill)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [theme.highlight, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.border, lineWidth: 2.5)
            )
            .shadow(color: theme.shadow.opacity(0.28), radius: 8, y: 5)
            .shadow(color: .white.opacity(0.45), radius: 0, y: -1)
    }

    private func iconBadge(systemName: String, size: CGFloat, theme: ActivityTileTheme) -> some View {
        ZStack {
            Circle()
                .fill(theme.badgeFill)
                .frame(width: size + 26, height: size + 26)
            Image(systemName: systemName)
                .font(.system(size: size, weight: .bold))
        }
    }
}

/// Color styling for each practice activity tile.
private struct ActivityTileTheme {
    let fill: Color
    let foreground: Color
    let border: Color
    let shadow: Color
    let highlight: Color
    let badgeFill: Color

    static func theme(for activity: PracticeActivity) -> ActivityTileTheme {
        switch activity {
        case .sandbox:
            return ActivityTileTheme(
                fill: Color(red: 1.0, green: 0.82, blue: 0.38),
                foreground: ContinuumTheme.beachCoralPen,
                border: ContinuumTheme.beachCoral.opacity(0.9),
                shadow: ContinuumTheme.beachCoralPen,
                highlight: Color.white.opacity(0.42),
                badgeFill: Color.white.opacity(0.35)
            )
        case .flash:
            return ActivityTileTheme(
                fill: Color(red: 0.30, green: 0.62, blue: 0.98),
                foreground: .white,
                border: ContinuumTheme.stormBlueDeep,
                shadow: ContinuumTheme.stormBlueDeep,
                highlight: Color.white.opacity(0.35),
                badgeFill: Color.white.opacity(0.24)
            )
        case .tryDemo:
            return ActivityTileTheme(
                fill: Color(red: 0.80, green: 0.72, blue: 0.98),
                foreground: ContinuumTheme.stormBlueDeep,
                border: ContinuumTheme.tabPurple.opacity(0.55),
                shadow: ContinuumTheme.tabPurple,
                highlight: Color.white.opacity(0.4),
                badgeFill: Color.white.opacity(0.34)
            )
        case .test:
            return ActivityTileTheme(
                fill: Color(red: 0.72, green: 0.52, blue: 0.92),
                foreground: .white,
                border: ContinuumTheme.tabPurple,
                shadow: ContinuumTheme.tabPurple,
                highlight: Color.white.opacity(0.32),
                badgeFill: Color.white.opacity(0.22)
            )
        }
    }
}

/// Routes to the selected practice activity screen.
struct ActivityDetailView: View {
    let target: PracticeTarget
    let activity: PracticeActivity

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var tracker = ActivitySessionTracker()
    @State private var showMoodSheet = false

    var body: some View {
        Group {
            switch activity {
            case .sandbox:
                SandboxActivityView(target: target)
            case .flash:
                FlashActivityView(target: target)
            case .tryDemo:
                TryActivityView(target: target)
            case .test:
                TestActivityView(target: target)
            }
        }
        .kidFriendlyNavigationTitle(activity.subtitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("I'm Done") {
                    showMoodSheet = true
                }
                .font(ContinuumTheme.kidButtonFont)
                .foregroundStyle(ContinuumTheme.tabPurple)
            }
        }
        .onAppear {
            tracker.start(activity: activity, target: target)
        }
        .onDisappear {
            if tracker.hasActiveSession {
                tracker.abandon(modelContext: modelContext)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                tracker.resume()
            case .background, .inactive:
                tracker.pause()
            @unknown default:
                break
            }
        }
        .sheet(isPresented: $showMoodSheet) {
            ActivityMoodSheet { mood in
                tracker.end(mood: mood, modelContext: modelContext)
                dismiss()
            }
        }
    }
}

extension PracticeActivity: Hashable {}
