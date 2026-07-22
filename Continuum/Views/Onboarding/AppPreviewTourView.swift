import SwiftUI

/// One concise step in the first-launch app preview tour.
struct AppTourStep: Identifiable {
    let id: Int
    let tab: AppTab
    let title: String
    let message: String
    let actionHint: String
    let systemImage: String
    let accent: Color
    let highlightAnchors: [AppTourAnchor]
    let showsActivityPreview: Bool
    let emphasizePriorityManage: Bool

    static let steps: [AppTourStep] = [
        AppTourStep(
            id: 0,
            tab: .home,
            title: "Welcome to Continuum",
            message: "Practice English speech sounds at home with Broca the Bear.",
            actionHint: "Use the Home tab as your starting point.",
            systemImage: "hand.wave.fill",
            accent: ContinuumTheme.tabPurple,
            highlightAnchors: [.tabHome],
            showsActivityPreview: false,
            emphasizePriorityManage: false
        ),
        AppTourStep(
            id: 1,
            tab: .home,
            title: "Start on Home",
            message: "Warm up first, or jump straight into sounds.",
            actionHint: "Tap Warm up or Practice Sounds here.",
            systemImage: "house.fill",
            accent: ContinuumTheme.homeMintText,
            highlightAnchors: [.homeWarmUp, .homePracticeSounds],
            showsActivityPreview: false,
            emphasizePriorityManage: false
        ),
        AppTourStep(
            id: 2,
            tab: .practice,
            title: "Priority Sounds",
            message: "Pin the sounds that need the most practice at the top.",
            actionHint: "This section stays above the full sound list.",
            systemImage: "star.fill",
            accent: ContinuumTheme.testMagenta,
            highlightAnchors: [.tabPractice, .practicePrioritySection],
            showsActivityPreview: false,
            emphasizePriorityManage: false
        ),
        AppTourStep(
            id: 3,
            tab: .practice,
            title: "Add a priority sound",
            message: "Tap Manage, then Add, and choose a sound from the list.",
            actionHint: "Pinned sounds appear in the pink Priority Sounds box.",
            systemImage: "plus.circle.fill",
            accent: ContinuumTheme.tabPurple,
            highlightAnchors: [.practicePrioritySection, .practiceManageButton],
            showsActivityPreview: false,
            emphasizePriorityManage: true
        ),
        AppTourStep(
            id: 4,
            tab: .practice,
            title: "Open a sound",
            message: "Tap any pinned sound to open its practice page.",
            actionHint: "You can also tap sounds in Vowels, Consonants, or Vowel Teams.",
            systemImage: "hand.tap.fill",
            accent: ContinuumTheme.sandboxMint,
            highlightAnchors: [.practicePrioritySection],
            showsActivityPreview: false,
            emphasizePriorityManage: false
        ),
        AppTourStep(
            id: 5,
            tab: .practice,
            title: "Four ways to practice",
            message: "Each sound includes Sandbox, Flash, Watch, and Test.",
            actionHint: "Tap an activity card to start that practice mode.",
            systemImage: "square.grid.2x2.fill",
            accent: ContinuumTheme.tabPurple,
            highlightAnchors: [.practiceActivities],
            showsActivityPreview: true,
            emphasizePriorityManage: false
        ),
        AppTourStep(
            id: 6,
            tab: .dashboard,
            title: "Track progress",
            message: "The Dashboard shows streaks, practice time, and speech scores.",
            actionHint: "Open Dashboard anytime to review how practice is going.",
            systemImage: "chart.bar.fill",
            accent: ContinuumTheme.stormBlueDeep,
            highlightAnchors: [.tabDashboard],
            showsActivityPreview: false,
            emphasizePriorityManage: false
        )
    ]
}

/// First-launch overlay that walks through Continuum's main tabs and actions.
struct AppPreviewTourView: View {
    @Binding var stepIndex: Int
    let highlightFrames: [AppTourAnchor: CGRect]
    let onSelectTab: (AppTab) -> Void
    let onFinish: () -> Void
    let onSkip: () -> Void

    private var currentStep: AppTourStep {
        AppTourStep.steps[stepIndex]
    }

    private var isFinalStep: Bool {
        stepIndex >= AppTourStep.steps.count - 1
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppTourSpotlightOverlay(
                highlightFrames: highlightFrames,
                activeAnchors: currentStep.highlightAnchors
            )

            VStack(spacing: 0) {
                skipButton
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                Spacer()

                stepCard
                    .padding(.horizontal, 24)

                pageIndicator
                    .padding(.top, 16)

                nextButton
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, ContinuumTabBar.layoutHeight + 28)
            }
        }
        .onAppear {
            applyTab(for: stepIndex)
        }
        .onChange(of: stepIndex) { _, newIndex in
            applyTab(for: newIndex)
        }
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button(action: onSkip) {
                Text("Skip")
                    .font(ContinuumTheme.kidButtonFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip app tour")
        }
    }

    private var stepCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(currentStep.accent.opacity(0.14))
                    .frame(width: 88, height: 88)

                Image(systemName: currentStep.systemImage)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(currentStep.accent)
            }

            Text(currentStep.title)
                .font(ContinuumTheme.kidSectionHeaderFont)
                .foregroundStyle(ContinuumTheme.tabPurple)
                .multilineTextAlignment(.center)

            Text(currentStep.message)
                .font(ContinuumTheme.kidBodyFont)
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(currentStep.accent)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Look for the pulsing outline")
                        .font(ContinuumTheme.kidCaptionFont.weight(.bold))
                        .foregroundStyle(currentStep.accent)

                    Text(currentStep.actionHint)
                        .font(ContinuumTheme.kidSubheadFont)
                        .foregroundStyle(ContinuumTheme.subtitleGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(currentStep.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ContinuumTheme.tabPurple.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: ContinuumTheme.navBarShadow, radius: 12, y: 6)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(AppTourStep.steps) { step in
                Circle()
                    .fill(step.id == stepIndex ? Color.white : Color.white.opacity(0.45))
                    .frame(width: step.id == stepIndex ? 10 : 8, height: step.id == stepIndex ? 10 : 8)
            }
        }
        .accessibilityLabel("Step \(stepIndex + 1) of \(AppTourStep.steps.count)")
    }

    private var nextButton: some View {
        Button(action: advanceStep) {
            Text(isFinalStep ? "Get Started" : "Next")
                .font(ContinuumTheme.kidButtonFont)
                .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                .foregroundStyle(.white)
                .background(ContinuumTheme.tabPurple)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: ContinuumTheme.tabPurple.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFinalStep ? "Get started" : "Next step")
    }

    /// Switches the visible tab to match the active tour step.
    private func applyTab(for index: Int) {
        guard AppTourStep.steps.indices.contains(index) else { return }
        onSelectTab(AppTourStep.steps[index].tab)
    }

    /// Moves to the next tour step or finishes the tour on the last step.
    private func advanceStep() {
        if isFinalStep {
            onFinish()
        } else {
            stepIndex += 1
        }
    }
}
