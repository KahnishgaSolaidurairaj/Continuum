import SwiftUI

/// Primary tab destinations for Continuum.
enum AppTab: Hashable {
    case home
    case practice
    case dashboard
}

/// Root tab shell matching the wireframe home / practice / dashboard flow.
struct MainTabView: View {
    @Environment(\.continuumDeviceLayout) private var layout

    @State private var selectedTab: AppTab = .home
    @State private var practiceRootID = UUID()
    @State private var shouldPulsePrioritySection = false
    @State private var tabBarVisibility = TabBarVisibility()
    @State private var parentMode = ParentModeController()
    @State private var showEducationalDisclaimer = !EducationalDisclaimerStore.hasAcknowledgedDisclaimer
    @State private var showAppTour = false
    @State private var appTourStepIndex = 0
    @State private var tourHighlightFrames: [AppTourAnchor: CGRect] = [:]
    @State private var showPostTourPINSetup = false

    private var currentTourStep: AppTourStep? {
        guard showAppTour, AppTourStep.steps.indices.contains(appTourStepIndex) else { return nil }
        return AppTourStep.steps[appTourStepIndex]
    }

    private var tourPreviewTarget: PracticeTarget? {
        guard currentTourStep?.showsActivityPreview == true else { return nil }
        return PracticeTarget.allPhonemes.first
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        onOpenPracticeTab: openPracticeHub,
                        onOpenPracticeWithPriorityFocus: openPracticeHubWithPriorityFocus
                    )
                case .practice:
                    PracticeHubView(
                        shouldPulsePrioritySection: shouldPulsePrioritySection,
                        onPriorityPulseComplete: {
                            shouldPulsePrioritySection = false
                        },
                        tourPreviewTarget: tourPreviewTarget,
                        tourEmphasizePriorityManage: currentTourStep?.emphasizePriorityManage ?? false,
                        appTourStepIndex: showAppTour ? appTourStepIndex : nil,
                        isChildMode: parentMode.isChildMode
                    )
                    .id(practiceRootID)
                case .dashboard:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !tabBarVisibility.isHidden {
                    tabBarChrome
                }
            }

            if showAppTour, !tabBarVisibility.isHidden {
                AppPreviewTourView(
                    stepIndex: $appTourStepIndex,
                    highlightFrames: tourHighlightFrames,
                    onSelectTab: selectTab,
                    onFinish: completeAppTour,
                    onSkip: completeAppTour
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .coordinateSpace(name: "AppTourSpace")
        .onPreferenceChange(AppTourHighlightFramePreferenceKey.self) { frames in
            tourHighlightFrames = frames
        }
        .environment(tabBarVisibility)
        .environment(parentMode)
        .animation(.easeInOut(duration: 0.25), value: tabBarVisibility.isHidden)
        .animation(.easeInOut(duration: 0.25), value: showAppTour)
        .onChange(of: parentMode.isChildMode) { _, isChildMode in
            practiceRootID = UUID()
            if isChildMode, selectedTab == .dashboard {
                selectedTab = .home
            }
        }
        .onAppear(perform: presentFirstLaunchFlowIfNeeded)
        .alert("Important Notice", isPresented: $showEducationalDisclaimer) {
            Button("I Understand") {
                acknowledgeEducationalDisclaimer()
            }
        } message: {
            Text("This is an educational app and is not intended to replace professional speech therapists.")
        }
        .sheet(isPresented: $showPostTourPINSetup) {
            ParentPINSetupSheet()
        }
    }

    /// Shows the preview tour after the disclaimer when both are still pending.
    private func presentFirstLaunchFlowIfNeeded() {
        guard EducationalDisclaimerStore.hasAcknowledgedDisclaimer else { return }
        showAppTour = !AppTourStore.hasCompletedAppTour
    }

    /// Saves disclaimer acceptance and continues into the first-launch tour when needed.
    private func acknowledgeEducationalDisclaimer() {
        EducationalDisclaimerStore.markAcknowledged()
        showEducationalDisclaimer = false
        showAppTour = !AppTourStore.hasCompletedAppTour
    }

    /// Opens the practice tab at phoneme selection every time.
    private func openPracticeHub() {
        shouldPulsePrioritySection = false
        practiceRootID = UUID()
        selectedTab = .practice
    }

    /// Opens the practice tab and pulses the priority sounds section.
    private func openPracticeHubWithPriorityFocus() {
        shouldPulsePrioritySection = true
        practiceRootID = UUID()
        selectedTab = .practice
    }

    /// Switches tabs and resets practice navigation when Practice is chosen.
    /// - Parameter tab: Destination tab.
    private func selectTab(_ tab: AppTab) {
        if tab == .practice {
            shouldPulsePrioritySection = false
            practiceRootID = UUID()
        } else {
            tabBarVisibility.isHidden = false
        }
        selectedTab = tab
    }

    /// Marks the first-launch tour complete and dismisses the overlay.
    private func completeAppTour() {
        AppTourStore.markCompleted()
        showAppTour = false
        appTourStepIndex = 0
        selectedTab = .home
        practiceRootID = UUID()
        parentMode.switchToParentModeWithoutPIN()
        if !ParentModeStore.hasPINConfigured {
            showPostTourPINSetup = true
        }
    }

    /// Bottom tab bar inset anchored to the screen bottom on iPhone.
    private var tabBarChrome: some View {
        VStack(spacing: 0) {
            ContinuumTabBar(
                selectedTab: $selectedTab,
                onTabSelected: selectTab,
                showsDashboardTab: !parentMode.isChildMode
            )
            .padding(.horizontal, layout.scaled(28, phone: 16))
            .padding(.top, layout.isPhone ? 8 : 10)
            .padding(.bottom, layout.isPhone ? 2 : 10)
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Floating bottom navigation bar from the updated Continuum mockup.
struct ContinuumTabBar: View {
    @Binding var selectedTab: AppTab
    let onTabSelected: (AppTab) -> Void
    var showsDashboardTab = true

    @Environment(\.continuumDeviceLayout) private var layout

    /// Approximate layout height used to keep tab content from crowding the bar.
    static let layoutHeight: CGFloat = 76
    static let phoneLayoutHeight: CGFloat = 68

    /// Space scroll content should leave above the floating tab bar.
    static let contentBottomPadding: CGFloat = layoutHeight + 18

    /// Returns bottom padding for scroll content based on the active device layout.
    static func contentBottomPadding(for layout: ContinuumDeviceLayout) -> CGFloat {
        if layout.isPhone {
            return 8
        }
        return layoutHeight + 18
    }

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                tab: .home,
                title: "Home",
                systemImage: "house",
                selectedSystemImage: "house.fill"
            )
            tabButton(
                tab: .practice,
                title: "Practice",
                systemImage: "text.bubble",
                selectedSystemImage: "text.bubble.fill"
            )
            if showsDashboardTab {
                tabButton(
                    tab: .dashboard,
                    title: "Dashboard",
                    systemImage: "chart.bar",
                    selectedSystemImage: "chart.bar.fill"
                )
            }
        }
        .padding(.horizontal, layout.scaled(18, phone: 14))
        .padding(.vertical, layout.scaled(12, phone: 10))
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            ContinuumTheme.tabPurple,
                            Color(red: 0.52, green: 0.42, blue: 0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: ContinuumTheme.tabPurple.opacity(0.35), radius: 16, y: 6)
        )
    }

    private func tabButton(
        tab: AppTab,
        title: String,
        systemImage: String,
        selectedSystemImage: String
    ) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            onTabSelected(tab)
        } label: {
            VStack(spacing: layout.scaled(6, phone: 4)) {
                Image(systemName: isSelected ? selectedSystemImage : systemImage)
                    .font(.system(size: layout.scaled(24, phone: 20), weight: .semibold))
                Text(title)
                    .font(.system(size: layout.scaled(15, phone: 13), weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.62))
            .padding(.vertical, 6)
            .appTourHighlight(tabHighlight(for: tab))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func tabHighlight(for tab: AppTab) -> AppTourAnchor {
        switch tab {
        case .home: return .tabHome
        case .practice: return .tabPractice
        case .dashboard: return .tabDashboard
        }
    }
}
