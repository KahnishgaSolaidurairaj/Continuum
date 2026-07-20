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
        VStack(spacing: 0) {
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
        }
        .ignoresSafeArea(edges: .bottom)
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

/// Custom purple bottom navigation from the wireframes.
struct ContinuumTabBar: View {
    @Binding var selectedTab: AppTab
    let onTabSelected: (AppTab) -> Void

    /// Approximate layout height used to keep tab content from crowding the bar.
    static let layoutHeight: CGFloat = 88

    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .home, title: "Home", systemImage: "house.fill")
            tabButton(tab: .practice, title: "Practice", systemImage: "play.circle.fill", isRaised: true)
            tabButton(tab: .dashboard, title: "Dashboard", systemImage: "chart.bar.fill")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(ContinuumTheme.tabPurple)
        .foregroundStyle(.white)
    }

    private func tabButton(tab: AppTab, title: String, systemImage: String, isRaised: Bool = false) -> some View {
        Button {
            onTabSelected(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(isRaised ? .system(size: 34) : .title2)
                    .offset(y: isRaised ? -4 : 0)
                Text(title)
                    .font(ContinuumTheme.kidCaptionFont)
            }
            .frame(maxWidth: .infinity)
            .opacity(selectedTab == tab ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
