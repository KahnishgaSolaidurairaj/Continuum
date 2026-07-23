import SwiftUI
import SwiftData

/// Home screen router with parent and child experiences plus a mode toggle.
struct HomeView: View {
    let onOpenPracticeTab: () -> Void
    let onOpenPracticeWithPriorityFocus: () -> Void

    @Environment(ParentModeController.self) private var parentMode

    @Query(sort: \ActivityEngagementRecord.endedAt, order: .reverse)
    private var engagements: [ActivityEngagementRecord]

    @State private var showGoalSheet = false
    @State private var showWarmUpSheet = false
    @State private var showPINSetupSheet = false
    @State private var showPINUnlockSheet = false
    @State private var showViewPINAlert = false
    @State private var viewedPIN = ""
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
        .sheet(isPresented: $showPINSetupSheet) {
            ParentPINSetupSheet()
        }
        .fullScreenCover(isPresented: $showPINUnlockSheet) {
            ParentPINUnlockSheet {
                parentMode.switchToParentModeWithoutPIN()
            }
        }
        .onChange(of: parentMode.isChildMode) { _, isChildMode in
            if !isChildMode {
                presentParentPINUpdateIfNeeded()
            }
        }
        .onAppear {
            presentParentPINUpdateIfNeeded()
        }
        .alert("Your Parent PIN", isPresented: $showViewPINAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewedPIN)
        }
    }

    /// Opens PIN setup when the parent returned using a temporary recovery code.
    private func presentParentPINUpdateIfNeeded() {
        guard !parentMode.isChildMode, ParentModeStore.needsParentPINUpdate else { return }
        showPINSetupSheet = true
    }

    /// Hills header with welcome copy and Broca mascot.
    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            HomeHillsBackground()

            GeometryReader { geometry in
                let mascotSize = min(geometry.size.width * 0.38, 196)

                HStack(alignment: .bottom, spacing: 6) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(parentMode.isChildMode ? "Let's practice!" : "Welcome to")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .foregroundStyle(ContinuumTheme.pencilLead)

                        Text("Continuum")
                            .font(.system(size: 68, weight: .bold, design: .rounded))
                            .foregroundStyle(ContinuumTheme.pencilLead)
                            .shadow(color: .white.opacity(0.9), radius: 0, x: 1, y: 1)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        Text(parentMode.isChildMode ? "Your practice space" : "Continue therapy at home")
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

    /// White rounded panel with parent or child content.
    private var mainPanel: some View {
        VStack(spacing: 14) {
            if parentMode.isChildMode {
                ChildHomeView(
                    onOpenPracticeWithPriorityFocus: onOpenPracticeWithPriorityFocus,
                    onDone: handleChildDone
                )
            } else {
                parentHomeContent
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(homePanelBackground(shadowY: -6))
    }

    /// Full parent home content with setup tools and quick actions.
    private var parentHomeContent: some View {
        VStack(spacing: 14) {
            primaryActionRow
            suggestionsSection
            parentPinSettingsSection
        }
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
                    .fullCapsuleHitTarget()
                    .appTourHighlight(.homeWarmUp)
            }
            .buttonStyle(.plain)

            Button {
                onOpenPracticeTab()
            } label: {
                Text("Practice Sounds")
                    .homePracticeCapsuleStyle()
                    .appTourHighlight(.homePracticeSounds)
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

    /// Parent-only controls for PIN setup beside the mode toggle card.
    private var parentPinSettingsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            parentLockCard
                .frame(maxWidth: .infinity, alignment: .leading)

            parentModeToggleCard
        }
    }

    /// PIN setup card shown on the left side of the parent lock row.
    private var parentLockCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Parent Lock", systemImage: "lock.shield.fill")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.testMagenta)

            Text(
                ParentModeStore.hasPINConfigured
                    ? "A 4-digit PIN protects parent settings. Switch to child mode when your child is ready to practice."
                    : "Add a 4-digit PIN before switching to child mode."
            )
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .foregroundStyle(ContinuumTheme.subtitleGray)
            .fixedSize(horizontal: false, vertical: true)

            if ParentModeStore.hasPINConfigured {
                Button("View PIN") {
                    presentStoredPIN()
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(ContinuumTheme.testMagenta)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .fullRoundedHitTarget(cornerRadius: 14)
                .buttonStyle(.plain)
            } else {
                Button("Set PIN") {
                    showPINSetupSheet = true
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(ContinuumTheme.testMagenta)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .fullRoundedHitTarget(cornerRadius: 14)
                .buttonStyle(.plain)
            }

            /*
            if let backupPhone = ParentModeStore.backupPhoneNumber, !backupPhone.isEmpty {
                Text("Backup phone: \(formattedPhone(backupPhone))")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.8))
            }
            */
        }
        .padding(18)
        .background(parentSettingsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(parentSettingsCardBorder)
        .appTourHighlight(.homeParentLock)
    }

    /// Mode toggle card shown on the right side of the parent lock row.
    private var parentModeToggleCard: some View {
        VStack {
            HomeModeToggle(
                isChildMode: parentMode.isChildMode,
                onSelectParent: handleSelectParentMode,
                onSelectChild: { parentMode.switchToChildMode() },
                usesVerticalLayout: true
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
        .frame(width: 118)
        .background(parentSettingsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(parentSettingsCardBorder)
    }

    private var parentSettingsCardBackground: some View {
        LinearGradient(
            colors: [ContinuumTheme.homePink.opacity(0.65), ContinuumTheme.testPinkSoft.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var parentSettingsCardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(ContinuumTheme.testMagenta.opacity(0.25), lineWidth: 2)
    }

    /// Shows the saved parent PIN in a popup alert.
    private func presentStoredPIN() {
        if let pin = ParentModeStore.storedPIN() {
            viewedPIN = pin
            showViewPINAlert = true
        } else {
            viewedPIN = "PIN unavailable. Set a new PIN to store it on this device."
            showViewPINAlert = true
        }
    }

    /// Routes parent-mode selection through PIN unlock when one is configured.
    private func handleSelectParentMode() {
        guard parentMode.isChildMode else { return }

        if parentMode.requiresPINToUnlockParentMode {
            showPINUnlockSheet = true
        } else {
            parentMode.switchToParentModeWithoutPIN()
        }
    }

    /// Returns to parent mode from child home via PIN when configured.
    private func handleChildDone() {
        handleSelectParentMode()
    }

    /// Formats a stored phone number for display.
    private func formattedPhone(_ digits: String) -> String {
        guard digits.count == 10 else { return digits }
        let area = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let last = digits.suffix(4)
        return "(\(area)) \(middle)-\(last)"
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
