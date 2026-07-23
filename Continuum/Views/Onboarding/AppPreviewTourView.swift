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
        ),
        AppTourStep(
            id: 7,
            tab: .home,
            title: "Set a parent PIN",
            message: "Create a 4-digit PIN to protect parent settings.",
            actionHint: "Use Set PIN in Parent Lock, then switch to child mode when ready.",
            systemImage: "lock.shield.fill",
            accent: ContinuumTheme.testMagenta,
            highlightAnchors: [.tabHome, .homeParentLock],
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

    private var tourCardBottomPadding: CGFloat {
        currentStep.showsActivityPreview
            ? ContinuumTabBar.layoutHeight + 96
            : ContinuumTabBar.layoutHeight + 12
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppTourSpotlightOverlay(
                highlightFrames: highlightFrames,
                activeAnchors: currentStep.highlightAnchors
            )

            VStack(spacing: 0) {
                Spacer()

                tourCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, tourCardBottomPadding)
            }
        }
        .onAppear {
            applyTab(for: stepIndex)
        }
        .onChange(of: stepIndex) { _, newIndex in
            applyTab(for: newIndex)
        }
    }

    private var tourCard: some View {
        VStack(spacing: 10) {
            Text(currentStep.title)
                .font(ContinuumTheme.kidSubheadFont.weight(.bold))
                .foregroundStyle(ContinuumTheme.testMagenta)
                .multilineTextAlignment(.center)

            Text(currentStep.message)
                .font(ContinuumTheme.kidCaptionFont)
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(currentStep.actionHint)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(ContinuumTheme.subtitleGray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            pageIndicator
                .padding(.top, 2)

            tourActionButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: 420)
        .background(
            LinearGradient(
                colors: [ContinuumTheme.homePink, ContinuumTheme.testPinkSoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ContinuumTheme.testMagenta.opacity(0.35), lineWidth: 2)
        )
        .shadow(color: ContinuumTheme.testMagenta.opacity(0.18), radius: 12, y: 6)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(AppTourStep.steps) { step in
                Circle()
                    .fill(step.id == stepIndex ? ContinuumTheme.testMagenta : ContinuumTheme.testMagenta.opacity(0.28))
                    .frame(width: step.id == stepIndex ? 8 : 6, height: step.id == stepIndex ? 8 : 6)
            }
        }
        .accessibilityLabel("Step \(stepIndex + 1) of \(AppTourStep.steps.count)")
    }

    private var tourActionButtons: some View {
        HStack(spacing: 10) {
            Button(action: onSkip) {
                Text("Skip")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .foregroundStyle(ContinuumTheme.testMagenta)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(ContinuumTheme.testMagenta.opacity(0.45), lineWidth: 2)
                    )
                    .fullRoundedHitTarget(cornerRadius: 14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip app tour")

            Button(action: advanceStep) {
                Text(isFinalStep ? (currentStep.id == 7 ? "Set PIN" : "Get Started") : "Next")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .foregroundStyle(.white)
                    .background(ContinuumTheme.testMagenta)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: ContinuumTheme.testMagenta.opacity(0.35), radius: 8, y: 4)
                    .fullRoundedHitTarget(cornerRadius: 14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFinalStep ? "Get started" : "Next step")
        }
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
