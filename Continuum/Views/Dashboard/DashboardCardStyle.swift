import SwiftUI

/// Fixed heights for dashboard cards so the layout stays consistent.
enum DashboardLayout {
    static let thisWeekHeight: CGFloat = 228
    static let calendarHeight: CGFloat = 360
    static let statPairHeight: CGFloat = 280
    static let moodsHeight: CGFloat = 360
    static let speechAccuracyHeight: CGFloat = 380
    static let analysisHeight: CGFloat = 220
    static let scrollFadeDistance: CGFloat = 720
    static let sectionSpacing: CGFloat = 14
    static let miniBoxRowHeight: CGFloat = 40
    static let miniBoxSpacing: CGFloat = 8

    /// Matches the stacked height of the three weekly summary rows.
    static var miniBoxStackHeight: CGFloat {
        miniBoxRowHeight * 3 + miniBoxSpacing * 2
    }
}

/// Shared white card styling for dashboard sections.
struct DashboardCard<Content: View>: View {
    var height: CGFloat?
    let content: Content

    init(height: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.height = height
        self.content = content()
    }

    var body: some View {
        Group {
            if let height {
                content
                    .padding(18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .frame(height: height, alignment: .top)
            } else {
                content
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

/// Header row used across dashboard cards.
struct DashboardCardHeader: View {
    let title: String
    let systemImage: String
    let subtitle: String?

    init(title: String, systemImage: String, subtitle: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ContinuumTheme.tabPurple)

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 26)
            }
        }
    }
}

/// Compact tinted row used in dashboard summary cards.
struct DashboardMiniBox: View {
    let systemImage: String
    var label: String?
    let text: String
    var trailingText: String?
    var minHeight: CGFloat = DashboardLayout.miniBoxRowHeight

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ContinuumTheme.tabPurple)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                if let label {
                    Text(label)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                }

                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
                    .lineLimit(label == nil ? 2 : 4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let trailingText {
                Spacer(minLength: 4)
                Text(trailingText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.tabPurple)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .background(ContinuumTheme.dashboardPurple.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ContinuumTheme.tabPurple.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Tracks vertical scroll position for the dashboard background fade.
struct DashboardScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Invisible marker used to measure dashboard scroll offset.
struct DashboardScrollOffsetReader: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: DashboardScrollOffsetKey.self,
                value: geometry.frame(in: .named("dashboardScroll")).minY
            )
        }
        .frame(height: 0)
    }
}

/// Dashboard background that subtly lightens toward whitish purple while scrolling.
struct DashboardScrollBackground: View {
    let scrollOffset: CGFloat

    var body: some View {
        fadedPurple
    }

    private var fadedPurple: Color {
        let scrollDepth = max(-scrollOffset, 0)
        let progress = min(scrollDepth / DashboardLayout.scrollFadeDistance, 1)
        let blend = progress * 0.38

        return Color(
            red: 0.78 + (0.95 - 0.78) * blend,
            green: 0.73 + (0.93 - 0.73) * blend,
            blue: 0.92 + (0.99 - 0.92) * blend
        )
    }
}
