import SwiftUI
import SwiftData

/// Practice tab entry: pick a target, browse activities, launch one full-screen.
struct PracticeHubView: View {
    var shouldPulsePrioritySection = false
    var onPriorityPulseComplete: (() -> Void)? = nil

    @Environment(TabBarVisibility.self) private var tabBarVisibility

    @State private var selectedTarget: PracticeTarget?
    @State private var activeActivity: PracticeActivity?

    var body: some View {
        NavigationStack {
            Group {
                if let target = selectedTarget {
                    ActivityCarouselView(
                        target: target,
                        onSelectActivity: { activity in
                            tabBarVisibility.isHidden = true
                            activeActivity = activity
                        },
                        onBack: {
                            selectedTarget = nil
                        }
                    )
                } else {
                    PhonemeSelectionView(
                        onSelect: { target in
                            selectedTarget = target
                        },
                        shouldPulsePrioritySection: shouldPulsePrioritySection,
                        onPriorityPulseComplete: onPriorityPulseComplete
                    )
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
            .onChange(of: activeActivity) { _, activity in
                if activity == nil {
                    tabBarVisibility.isHidden = false
                }
            }
        }
    }
}

/// Wireframe step 1: choose one of the 44 English sounds.
struct PhonemeSelectionView: View {
    static let prioritySectionScrollID = "prioritySoundsSection"

    let onSelect: (PracticeTarget) -> Void
    var shouldPulsePrioritySection = false
    var onPriorityPulseComplete: (() -> Void)? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var expandedSections: Set<String> = []
    @State private var prioritySoundIDs: [String] = PracticePriorityStore.prioritySoundIDs
    @State private var isManagingPriority = false
    @State private var showPriorityPicker = false
    @State private var priorityPulseScale: CGFloat = 1
    @State private var priorityPulseRingOpacity = 0.0
    @State private var priorityPulseShadowOpacity = 0.0

    private var columnCount: Int {
        horizontalSizeClass == .compact ? 2 : 4
    }

    private var prioritySounds: [PracticeSound] {
        prioritySoundIDs.compactMap { PracticeSoundCatalog.sound(withID: $0) }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Which sound?")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.pencilLead)
                        .frame(maxWidth: .infinity)

                    prioritySoundsSection
                        .id(Self.prioritySectionScrollID)

                    collapsibleSoundSection(title: "Vowels", sounds: PracticeSoundCatalog.vowels)
                    collapsibleSoundSection(title: "Consonants", sounds: PracticeSoundCatalog.consonants)
                    collapsibleSoundSection(title: "Vowel Teams", sounds: PracticeSoundCatalog.vowelTeams)
                }
                .padding(.horizontal, ContinuumTheme.pageHorizontalPadding)
                .padding(.top, 20)
                .padding(.bottom, ContinuumTabBar.contentBottomPadding)
            }
            .scrollIndicators(.visible)
            .onAppear {
                reloadPrioritySounds()
                beginPrioritySectionEmphasisIfNeeded(scrollProxy: scrollProxy)
            }
        }
        .sheet(isPresented: $showPriorityPicker, onDismiss: reloadPrioritySounds) {
            AddPrioritySoundSheet(existingSoundIDs: prioritySoundIDs) { sound in
                PracticePriorityStore.add(soundID: sound.id)
                reloadPrioritySounds()
            }
        }
    }

    /// Priority sounds pinned to the top for focused practice.
    private var prioritySoundsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Label("Priority Sounds", systemImage: "folder.fill")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.tabPurple)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isManagingPriority.toggle()
                    }
                } label: {
                    Text(isManagingPriority ? "Done" : "Manage")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(ContinuumTheme.tabPurple)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if isManagingPriority {
                    Button {
                        showPriorityPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.tabPurple)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(ContinuumTheme.tabPurple.opacity(0.35), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if prioritySounds.isEmpty {
                Button {
                    isManagingPriority = true
                    showPriorityPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(ContinuumTheme.tabPurple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add focus sounds")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(ContinuumTheme.pencilLead)
                            Text("Pin issue sounds here so your child sees them first.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(ContinuumTheme.subtitleGray)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.82))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ContinuumTheme.tabPurple.opacity(0.2), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            } else {
                soundGrid(
                    sounds: prioritySounds,
                    showsRemoveButton: isManagingPriority,
                    onRemove: removePrioritySound
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [ContinuumTheme.homePink, ContinuumTheme.testPinkSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ContinuumTheme.tabPurple.opacity(0.22), lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ContinuumTheme.tabPurple.opacity(priorityPulseRingOpacity), lineWidth: 4)
        )
        .scaleEffect(priorityPulseScale)
        .shadow(
            color: ContinuumTheme.tabPurple.opacity(priorityPulseShadowOpacity),
            radius: 18,
            y: 0
        )
    }

    /// Scrolls to and pulses the priority section when opened from Home practice focus.
    private func beginPrioritySectionEmphasisIfNeeded(scrollProxy: ScrollViewProxy) {
        guard shouldPulsePrioritySection else { return }

        onPriorityPulseComplete?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.45)) {
                scrollProxy.scrollTo(Self.prioritySectionScrollID, anchor: .top)
            }
            runPriorityPulseAnimation()
        }
    }

    /// Runs a short pulsing animation on the priority sounds card.
    private func runPriorityPulseAnimation() {
        Task { @MainActor in
            for _ in 0..<4 {
                withAnimation(.easeInOut(duration: 0.55)) {
                    priorityPulseScale = 1.025
                    priorityPulseRingOpacity = 0.85
                    priorityPulseShadowOpacity = 0.35
                }
                try? await Task.sleep(for: .milliseconds(550))
                withAnimation(.easeInOut(duration: 0.55)) {
                    priorityPulseScale = 1.0
                    priorityPulseRingOpacity = 0
                    priorityPulseShadowOpacity = 0
                }
                try? await Task.sleep(for: .milliseconds(550))
            }
        }
    }

    /// Collapsible sound category shown as a dropdown section.
    private func collapsibleSoundSection(title: String, sounds: [PracticeSound]) -> some View {
        let isExpanded = expandedSections.contains(title)

        return VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    toggleSection(title)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isExpanded ? "folder.fill.badge.minus" : "folder.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(ContinuumTheme.tabPurple)

                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.tabPurple)

                    Text("\(sounds.count)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.tabPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.85))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ContinuumTheme.tabPurple)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .shadow(color: ContinuumTheme.navBarShadow, radius: 6, y: 3)
                )
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(sounds.count) sounds")
            .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")

            if isExpanded {
                soundGrid(sounds: sounds)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// Shared grid of selectable practice sound tiles.
    private func soundGrid(
        sounds: [PracticeSound],
        showsRemoveButton: Bool = false,
        onRemove: ((PracticeSound) -> Void)? = nil
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columnCount),
            spacing: 14
        ) {
            ForEach(sounds) { sound in
                PracticeSoundTile(
                    sound: sound,
                    showsRemoveButton: showsRemoveButton,
                    onSelect: { onSelect(PracticeTarget(id: sound.id, practiceSound: sound)) },
                    onRemove: { onRemove?(sound) }
                )
            }
        }
    }

    /// Toggles a collapsible section open or closed.
    private func toggleSection(_ title: String) {
        if expandedSections.contains(title) {
            expandedSections.remove(title)
        } else {
            expandedSections.insert(title)
        }
    }

    /// Reloads priority sound IDs from persistent storage.
    private func reloadPrioritySounds() {
        prioritySoundIDs = PracticePriorityStore.prioritySoundIDs
    }

    /// Removes a sound from the priority list.
    private func removePrioritySound(_ sound: PracticeSound) {
        PracticePriorityStore.remove(soundID: sound.id)
        reloadPrioritySounds()
    }
}

/// One selectable sound tile used in the practice picker grids.
private struct PracticeSoundTile: View {
    let sound: PracticeSound
    let showsRemoveButton: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onSelect) {
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

            if showsRemoveButton {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white))
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
                .accessibilityLabel("Remove \(sound.displayName) from priority sounds")
            }
        }
    }
}

/// Sheet for adding a sound to the priority list.
private struct AddPrioritySoundSheet: View {
    @Environment(\.dismiss) private var dismiss

    let existingSoundIDs: [String]
    let onAdd: (PracticeSound) -> Void

    @State private var searchText = ""
    @State private var addedSoundIDs: Set<String> = []

    private var excludedSoundIDs: Set<String> {
        Set(existingSoundIDs.map { PracticeSoundAssetBridge.canonicalSoundID($0) })
            .union(addedSoundIDs)
    }

    private func availableSounds(from sounds: [PracticeSound]) -> [PracticeSound] {
        sounds.filter { sound in
            !excludedSoundIDs.contains(PracticeSoundAssetBridge.canonicalSoundID(sound.id))
        }
    }

    private func filteredSounds(from sounds: [PracticeSound]) -> [PracticeSound] {
        let available = availableSounds(from: sounds)
        guard !searchText.isEmpty else { return available }
        let query = searchText.lowercased()
        return available.filter {
            $0.displayName.lowercased().contains(query) || $0.primaryExample.lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack {
            ContinuumTheme.homeLavender
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Add Priority Sound")
                        .font(ContinuumTheme.kidSectionHeaderFont)
                        .foregroundStyle(ContinuumTheme.tabPurple)

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ContinuumTheme.tabPurple)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(ContinuumTheme.tabPurple)
                    TextField("Search sounds", text: $searchText)
                        .font(ContinuumTheme.kidBodyFont)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ContinuumTheme.tabPurple.opacity(0.2), lineWidth: 1.5)
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        priorityPickerCategory(title: "Vowels", sounds: filteredSounds(from: PracticeSoundCatalog.vowels))
                        priorityPickerCategory(title: "Consonants", sounds: filteredSounds(from: PracticeSoundCatalog.consonants))
                        priorityPickerCategory(title: "Vowel Teams", sounds: filteredSounds(from: PracticeSoundCatalog.vowelTeams))
                    }
                }
            }
            .padding(24)
            .continuumSheetInset()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    /// One categorized block of addable sounds inside the priority picker sheet.
    private func priorityPickerCategory(title: String, sounds: [PracticeSound]) -> some View {
        Group {
            if !sounds.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.tabPurple)

                    VStack(spacing: 10) {
                        ForEach(sounds) { sound in
                            Button {
                                onAdd(sound)
                                addedSoundIDs.insert(PracticeSoundAssetBridge.canonicalSoundID(sound.id))
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sound.displayName)
                                            .font(ContinuumTheme.kidBodyFont.weight(.semibold))
                                            .foregroundStyle(ContinuumTheme.pencilLead)
                                        Text("as in \(sound.primaryExample)")
                                            .font(ContinuumTheme.kidCaptionFont)
                                            .foregroundStyle(ContinuumTheme.subtitleGray)
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(ContinuumTheme.tabPurple)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .kidChoiceButtonStyle(isSelected: false)
                            }
                            .buttonStyle(.plain)
                        }
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
    @Environment(TabBarVisibility.self) private var tabBarVisibility

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
            tabBarVisibility.isHidden = true
            tracker.start(activity: activity, target: target)
        }
        .onDisappear {
            tabBarVisibility.isHidden = false
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
