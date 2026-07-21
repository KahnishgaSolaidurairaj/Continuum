import SwiftUI

/// Primary tab destinations for Continuum.
enum AppTab: Hashable {
    case home
    case practice
    case dashboard
}

/// Root tab shell matching the wireframe home / practice / dashboard flow.
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var practiceRootID = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(onOpenPracticeTab: openPracticeHub)
                case .practice:
                    PracticeHubView()
                        .id(practiceRootID)
                case .dashboard:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ContinuumTabBar(selectedTab: $selectedTab, onTabSelected: selectTab)
                .padding(.horizontal, 28)
                .padding(.bottom, 10)
        }
    }

    /// Opens the practice tab at phoneme selection every time.
    private func openPracticeHub() {
        practiceRootID = UUID()
        selectedTab = .practice
    }

    /// Switches tabs and resets practice navigation when Practice is chosen.
    /// - Parameter tab: Destination tab.
    private func selectTab(_ tab: AppTab) {
        if tab == .practice {
            practiceRootID = UUID()
        }
        selectedTab = tab
    }
}

/// Floating bottom navigation bar from the updated Continuum mockup.
struct ContinuumTabBar: View {
    @Binding var selectedTab: AppTab
    let onTabSelected: (AppTab) -> Void

    /// Approximate layout height used to keep tab content from crowding the bar.
    static let layoutHeight: CGFloat = 76

    /// Space scroll content should leave above the floating tab bar.
    static let contentBottomPadding: CGFloat = layoutHeight + 18

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
            tabButton(
                tab: .dashboard,
                title: "Progress",
                systemImage: "chart.bar",
                selectedSystemImage: "chart.bar.fill"
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(color: ContinuumTheme.navBarShadow, radius: 16, y: 6)
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
            VStack(spacing: 6) {
                Image(systemName: isSelected ? selectedSystemImage : systemImage)
                    .font(.system(size: 24, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? ContinuumTheme.tabPurple : ContinuumTheme.navInactive)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
