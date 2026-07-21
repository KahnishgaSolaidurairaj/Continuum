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
            .background(
                LinearGradient(
                    colors: [
                        ContinuumTheme.practicePageLavender,
                        ContinuumTheme.practicePageCream,
                        ContinuumTheme.homeOffWhite
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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
            VStack(alignment: .leading, spacing: 28) {
                Text("Which sound?")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                    .frame(maxWidth: .infinity)

                soundSection(title: "Vowels", sounds: PracticeSoundCatalog.vowels)
                soundSection(title: "Consonants", sounds: PracticeSoundCatalog.consonants)
                soundSection(title: "Vowel Teams", sounds: PracticeSoundCatalog.vowelTeams)
            }
            .padding(.horizontal, ContinuumTheme.pageHorizontalPadding)
            .padding(.top, 20)
            .padding(.bottom, ContinuumTabBar.contentBottomPadding)
        }
        .scrollIndicators(.visible)
    }

    private func soundSection(title: String, sounds: [PracticeSound]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.tabPurple)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columnCount), spacing: 14) {
                ForEach(sounds) { sound in
                    Button {
                        onSelect(PracticeTarget(id: sound.id, practiceSound: sound))
                    } label: {
                        VStack(spacing: 10) {
                            Text(sound.displayName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            HighlightedWordText(
                                word: sound.level1Example.word,
                                highlights: sound.level1Example.highlights,
                                font: .system(size: 22, weight: .semibold, design: .rounded),
                                baseColor: ContinuumTheme.pencilLead,
                                highlightColor: ContinuumTheme.tabPurple
                            )
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, minHeight: 104)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.white)
                                .shadow(color: ContinuumTheme.navBarShadow, radius: 8, y: 4)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    private var activityCardsSpacing: CGFloat {
        usesColumnLayout ? 24 : 16
    }

    private var pageHorizontalPadding: CGFloat {
        ContinuumTheme.pageHorizontalPadding
    }

    private var activityIconContainerSize: CGFloat {
        usesColumnLayout ? 92 : 72
    }

    private var activityIconSize: CGFloat {
        usesColumnLayout ? 44 : 34
    }

    private var activityCardPadding: CGFloat {
        usesColumnLayout ? 28 : 22
    }

    private var activityCardInnerSpacing: CGFloat {
        usesColumnLayout ? 22 : 18
    }

    var body: some View {
        ScrollView {
            VStack(spacing: usesColumnLayout ? 24 : 24) {
                headerSection

                if usesColumnLayout {
                    VStack(spacing: activityCardsSpacing) {
                        ForEach(PracticeActivity.allCases) { activity in
                            activityCard(for: activity)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    let activities = PracticeActivity.allCases
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            activityCard(for: activities[0])
                            activityCard(for: activities[1])
                        }
                        HStack(spacing: 16) {
                            activityCard(for: activities[2])
                            activityCard(for: activities[3])
                        }
                    }
                }
            }
            .padding(.horizontal, pageHorizontalPadding)
            .padding(.top, usesColumnLayout ? 16 : 12)
            .padding(.bottom, ContinuumTabBar.contentBottomPadding)
        }
    }

    private var headerSection: some View {
        VStack(spacing: usesColumnLayout ? 16 : 20) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(ContinuumTheme.pencilLead)
                        .frame(width: 48, height: 48)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: ContinuumTheme.navBarShadow, radius: 8, y: 3)
                }
                .accessibilityLabel("Back")

                Spacer()
            }

            Text("Practice \(target.displayLabel)")
                .font(.system(size: usesColumnLayout ? 32 : 38, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            phonemePreviewCard

            Text("Choose an activity")
                .font(.system(size: usesColumnLayout ? 26 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    /// One mockup-style activity card with icon, copy, and a call-to-action button.
    private func activityCard(for activity: PracticeActivity) -> some View {
        let theme = ActivityTileTheme.theme(for: activity)

        return VStack(alignment: .leading, spacing: activityCardInnerSpacing) {
            HStack(alignment: .top, spacing: usesColumnLayout ? 20 : 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(theme.iconBackground)
                        .frame(width: activityIconContainerSize, height: activityIconContainerSize)
                    Image(systemName: activity.systemImage)
                        .font(.system(size: activityIconSize, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(activity.subtitle)
                        .font(.system(size: usesColumnLayout ? 30 : 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                    Text(activity.title)
                        .font(.system(size: usesColumnLayout ? 20 : 18, weight: .medium, design: .rounded))
                        .foregroundStyle(ContinuumTheme.subtitleGray)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                onSelectActivity(activity)
            } label: {
                Text(activity.actionLabel)
                    .font(.system(size: usesColumnLayout ? 22 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.buttonForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, usesColumnLayout ? 18 : 16)
                    .background(theme.buttonBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        if theme.usesOutlinedButton {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(theme.accent, lineWidth: 2)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(activityCardPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: usesColumnLayout ? 210 : 220,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.cardBackground)
                .shadow(color: ContinuumTheme.navBarShadow, radius: 12, y: 6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.subtitle). \(activity.title)")
        .accessibilityHint("Double tap to \(activity.actionLabel.lowercased())")
    }

    /// Large preview card showing the practice phoneme; tap to return to sound selection.
    private var phonemePreviewCard: some View {
        Button(action: onBack) {
            Text(target.traceCharacter.uppercased())
                .font(.system(size: usesColumnLayout ? 56 : 72, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: usesColumnLayout ? 120 : 148)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white)
                        .shadow(color: ContinuumTheme.navBarShadow, radius: 14, y: 6)
                )
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to all sounds")
        .accessibilityHint("Returns to the sound selection screen")
    }
}

/// Color styling for each practice activity card.
private struct ActivityTileTheme {
    let cardBackground: Color
    let accent: Color
    let iconBackground: Color
    let buttonBackground: Color
    let buttonForeground: Color
    let usesOutlinedButton: Bool

    static func theme(for activity: PracticeActivity) -> ActivityTileTheme {
        switch activity {
        case .sandbox:
            return ActivityTileTheme(
                cardBackground: ContinuumTheme.sandboxMintSoft,
                accent: ContinuumTheme.sandboxMint,
                iconBackground: Color.white.opacity(0.75),
                buttonBackground: ContinuumTheme.sandboxMint,
                buttonForeground: .white,
                usesOutlinedButton: false
            )
        case .flash:
            return ActivityTileTheme(
                cardBackground: ContinuumTheme.flashLavenderSoft,
                accent: ContinuumTheme.tabPurple,
                iconBackground: Color.white.opacity(0.75),
                buttonBackground: ContinuumTheme.tabPurple,
                buttonForeground: .white,
                usesOutlinedButton: false
            )
        case .tryDemo:
            return ActivityTileTheme(
                cardBackground: ContinuumTheme.tryBlueSoft,
                accent: ContinuumTheme.stormBlueDeep,
                iconBackground: Color.white.opacity(0.75),
                buttonBackground: ContinuumTheme.stormBlueDeep,
                buttonForeground: .white,
                usesOutlinedButton: false
            )
        case .test:
            return ActivityTileTheme(
                cardBackground: ContinuumTheme.testPinkSoft,
                accent: ContinuumTheme.testMagenta,
                iconBackground: Color.white.opacity(0.75),
                buttonBackground: ContinuumTheme.testMagenta,
                buttonForeground: .white,
                usesOutlinedButton: false
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
