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
    @State private var practiceTarget: PracticeTarget?

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        onStartPractice: { target in
                            practiceTarget = target
                            selectedTab = .practice
                        },
                        onOpenPracticeTab: {
                            selectedTab = .practice
                        }
                    )
                case .practice:
                    PracticeHubView(initialTarget: practiceTarget)
                case .dashboard:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ContinuumTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Custom purple bottom navigation from the wireframes.
struct ContinuumTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack {
            tabButton(tab: .home, title: "Home", systemImage: "house.fill")
            Spacer()
            tabButton(tab: .practice, title: "Practice", systemImage: "play.circle.fill", isRaised: true)
            Spacer()
            tabButton(tab: .dashboard, title: "Dashboard", systemImage: "chart.bar.fill")
        }
        .padding(.horizontal, 36)
        .padding(.top, 14)
        .padding(.bottom, 24)
        .background(ContinuumTheme.tabPurple)
        .foregroundStyle(.white)
    }

    private func tabButton(tab: AppTab, title: String, systemImage: String, isRaised: Bool = false) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(isRaised ? .system(size: 40) : .title)
                    .offset(y: isRaised ? -8 : 0)
                if !isRaised {
                    Text(title)
                        .font(ContinuumTheme.kidCaptionFont)
                }
            }
            .opacity(selectedTab == tab ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
