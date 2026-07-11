import SwiftUI

/// Practice tab entry: pick a target, browse activities, launch one full-screen.
struct PracticeHubView: View {
    let initialTarget: PracticeTarget?

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
        .onAppear {
            if selectedTarget == nil {
                selectedTarget = initialTarget
            }
        }
        .onChange(of: initialTarget?.id) { _, _ in
            if let initialTarget {
                selectedTarget = initialTarget
            }
        }
    }
}

/// Wireframe step 1: choose one of the 44 English phonemes.
struct PhonemeSelectionView: View {
    let onSelect: (PracticeTarget) -> Void

    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Which sound?")
                    .font(ContinuumTheme.kidSectionHeaderFont)

                phonemeSection(title: "Consonants", phonemes: Phoneme.consonants)
                phonemeSection(title: "Vowels", phonemes: Phoneme.vowels)
            }
            .padding()
        }
    }

    private func phonemeSection(title: String, phonemes: [Phoneme]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.tabPurple)

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(phonemes) { phoneme in
                    if let target = PracticeTarget.allPhonemes.first(where: { $0.linkedPhoneme == phoneme }) {
                        Button {
                            onSelect(target)
                        } label: {
                            VStack(spacing: 4) {
                                Text(target.symbol)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                Text(phoneme.exampleWord)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(.white.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ContinuumTheme.cardBorder, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(phoneme.displayName), as in \(phoneme.exampleWord)")
                    }
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

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var usesColumnLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: onBack) {
                            Label("Back", systemImage: "chevron.left")
                                .font(ContinuumTheme.kidButtonFont)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white.opacity(0.85))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }

                    Text("Practice \(target.displayLabel)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    phonemePreviewCard(
                        cardHeight: max(geometry.size.height * 0.22, usesColumnLayout ? 160 : 200),
                        symbolSize: min(geometry.size.width * 0.38, geometry.size.height * 0.16)
                    )

                    Text("Choose an activity")
                        .font(ContinuumTheme.kidSectionHeaderFont)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if usesColumnLayout {
                        VStack(spacing: 16) {
                            ForEach(PracticeActivity.allCases) { activity in
                                Button {
                                    onSelectActivity(activity)
                                } label: {
                                    activityTile(
                                        for: activity,
                                        layout: .column,
                                        tileSide: activityTileSide(in: geometry)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(PracticeActivity.allCases) { activity in
                                Button {
                                    onSelectActivity(activity)
                                } label: {
                                    activityTile(
                                        for: activity,
                                        layout: .grid,
                                        tileSide: activityTileSide(in: geometry)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Large preview card showing the practice phoneme clearly.
    private func phonemePreviewCard(cardHeight: CGFloat, symbolSize: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(ContinuumTheme.cardBorder.opacity(0.2), lineWidth: 2)
                )

            VStack(spacing: 8) {
                Text(target.symbol)
                    .font(.system(size: symbolSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("“\(target.exampleWord)”")
                    .font(ContinuumTheme.kidSubheadFont)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
    }

    /// Side length for square activity tiles on iPad, or row height reference on iPhone.
    private func activityTileSide(in geometry: GeometryProxy) -> CGFloat {
        let horizontalPadding: CGFloat = 40
        if usesColumnLayout {
            return max(geometry.size.width - horizontalPadding, 280)
        }
        let spacing: CGFloat = 16
        let availableWidth = geometry.size.width - horizontalPadding - spacing
        return max(availableWidth / 2, 150)
    }

    private enum ActivityTileLayout {
        case grid
        case column
    }

    /// One colored activity option in the practice picker.
    private func activityTile(
        for activity: PracticeActivity,
        layout: ActivityTileLayout,
        tileSide: CGFloat
    ) -> some View {
        let theme = ActivityTileTheme.theme(for: activity)
        let iconSize: CGFloat = layout == .grid ? tileSide * 0.34 : 52

        let tileContent = Group {
            switch layout {
            case .grid:
                VStack(spacing: 14) {
                    Image(systemName: activity.systemImage)
                        .font(.system(size: iconSize))
                    Text(activity.subtitle)
                        .font(ContinuumTheme.kidSectionHeaderFont)
                    Text(activity.title)
                        .font(ContinuumTheme.kidSubheadFont)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            case .column:
                HStack(spacing: 18) {
                    Image(systemName: activity.systemImage)
                        .font(.system(size: iconSize))
                        .frame(width: iconSize + 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(activity.subtitle)
                            .font(ContinuumTheme.kidSectionHeaderFont)
                        Text(activity.title)
                            .font(ContinuumTheme.kidSubheadFont)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
            }
        }
        .foregroundStyle(theme.foreground)

        return tileContent
            .frame(maxWidth: .infinity)
            .frame(
                width: layout == .grid ? tileSide : nil,
                height: layout == .grid ? tileSide : nil
            )
            .frame(minHeight: layout == .column ? ContinuumTheme.kidMinTapHeight + 36 : nil)
            .padding(.vertical, layout == .column ? 18 : 0)
            .background(
                LinearGradient(
                    colors: theme.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.border, lineWidth: 2.5)
            )
            .shadow(color: theme.border.opacity(0.2), radius: 6, y: 3)
    }
}

/// Color styling for each practice activity tile.
private struct ActivityTileTheme {
    let gradient: [Color]
    let foreground: Color
    let border: Color

    static func theme(for activity: PracticeActivity) -> ActivityTileTheme {
        switch activity {
        case .sandbox:
            return ActivityTileTheme(
                gradient: [ContinuumTheme.beachSunYellow, ContinuumTheme.beachCoral],
                foreground: ContinuumTheme.beachCoralPen,
                border: ContinuumTheme.beachCoralPen.opacity(0.85)
            )
        case .flash:
            return ActivityTileTheme(
                gradient: [ContinuumTheme.lightningGlow, ContinuumTheme.stormBlue],
                foreground: ContinuumTheme.stormBlueDeep,
                border: ContinuumTheme.stormBlueDeep
            )
        case .tryDemo:
            return ActivityTileTheme(
                gradient: [ContinuumTheme.stormBlue, ContinuumTheme.homeLavender],
                foreground: ContinuumTheme.tabPurple,
                border: ContinuumTheme.tabPurple
            )
        case .test:
            return ActivityTileTheme(
                gradient: [ContinuumTheme.homePink, ContinuumTheme.tabPurple],
                foreground: Color(red: 0.82, green: 0.36, blue: 0.54),
                border: ContinuumTheme.tabPurple
            )
        }
    }
}

/// Routes to the selected practice activity screen.
struct ActivityDetailView: View {
    let target: PracticeTarget
    let activity: PracticeActivity

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
    }
}

extension PracticeActivity: Hashable {}
