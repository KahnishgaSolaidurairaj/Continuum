import SwiftUI

/// Fixed heights for dashboard cards so the layout stays consistent.
enum DashboardLayout {
    static let thisWeekHeight: CGFloat = 286
    static let calendarHeight: CGFloat = 410
    static let statPairHeight: CGFloat = 320
    static let moodsHeight: CGFloat = 420
    static let speechAccuracyHeight: CGFloat = 430
    static let analysisHeight: CGFloat = 260
    static let scrollFadeDistance: CGFloat = 720
    static let sectionSpacing: CGFloat = 16
    static let miniBoxRowHeight: CGFloat = 54
    static let miniBoxSpacing: CGFloat = 10

    /// Matches the stacked height of the three weekly summary rows.
    static var miniBoxStackHeight: CGFloat {
        miniBoxRowHeight * 3 + miniBoxSpacing * 2
    }

    /// Returns a fixed card height on iPad and intrinsic height on iPhone.
    static func cardHeight(_ padHeight: CGFloat, layout: ContinuumDeviceLayout) -> CGFloat? {
        layout.isPhone ? nil : padHeight
    }
}

/// Shared typography sized for kid- and parent-readable dashboard content.
enum DashboardTypography {
    static let cardTitle: Font = .system(size: 26, weight: .bold, design: .rounded)
    static let cardSubtitle: Font = ContinuumTheme.kidSubheadFont
    static let body: Font = ContinuumTheme.kidBodyFont
    static let bodyEmphasis: Font = ContinuumTheme.kidBodyFont.weight(.semibold)
    static let label: Font = ContinuumTheme.kidSubheadFont.weight(.bold)
    static let caption: Font = ContinuumTheme.kidCaptionFont
    static let headerIconSize: CGFloat = 24
    static let rowIconSize: CGFloat = 22

    /// Returns the dashboard card title font for the active device layout.
    static func cardTitle(for layout: ContinuumDeviceLayout) -> Font {
        layout.font(26, phoneSize: 22, weight: .bold)
    }

    /// Returns the dashboard card subtitle font for the active device layout.
    static func cardSubtitle(for layout: ContinuumDeviceLayout) -> Font {
        ContinuumTheme.kidSubheadFont(for: layout)
    }

    /// Returns the dashboard body font for the active device layout.
    static func body(for layout: ContinuumDeviceLayout) -> Font {
        ContinuumTheme.kidBodyFont(for: layout)
    }

    /// Returns the dashboard body emphasis font for the active device layout.
    static func bodyEmphasis(for layout: ContinuumDeviceLayout) -> Font {
        ContinuumTheme.kidBodyFont(for: layout).weight(.semibold)
    }

    /// Returns the dashboard label font for the active device layout.
    static func label(for layout: ContinuumDeviceLayout) -> Font {
        ContinuumTheme.kidSubheadFont(for: layout).weight(.bold)
    }

    /// Returns the dashboard caption font for the active device layout.
    static func caption(for layout: ContinuumDeviceLayout) -> Font {
        ContinuumTheme.kidCaptionFont(for: layout)
    }

    /// Returns the dashboard header icon size for the active device layout.
    static func headerIconSize(for layout: ContinuumDeviceLayout) -> CGFloat {
        layout.scaled(headerIconSize, phone: 20)
    }

    /// Returns the dashboard row icon size for the active device layout.
    static func rowIconSize(for layout: ContinuumDeviceLayout) -> CGFloat {
        layout.scaled(rowIconSize, phone: 18)
    }
}

/// Reports measured dashboard text height for adaptive padding.
struct DashboardTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .frame(height: height, alignment: .top)
            } else {
                content
                    .padding(20)
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

    @Environment(\.continuumDeviceLayout) private var layout

    init(title: String, systemImage: String, subtitle: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: DashboardTypography.headerIconSize(for: layout), weight: .semibold))
                    .foregroundStyle(ContinuumTheme.tabPurple)

                Text(title)
                    .font(DashboardTypography.cardTitle(for: layout))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            if let subtitle {
                Text(subtitle)
                    .font(DashboardTypography.cardSubtitle(for: layout))
                    .foregroundStyle(.secondary)
                    .padding(.leading, DashboardTypography.headerIconSize(for: layout) + 10)
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

    @State private var textBlockHeight: CGFloat = 0

    private static let singleLineTextHeight: CGFloat = 29

    private var isMultiline: Bool {
        textBlockHeight > Self.singleLineTextHeight
    }

    private var verticalPadding: CGFloat {
        isMultiline ? 16 : 12
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: DashboardTypography.rowIconSize, weight: .semibold))
                .foregroundStyle(ContinuumTheme.tabPurple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                if let label {
                    Text(label)
                        .font(DashboardTypography.label)
                        .foregroundStyle(.black)
                        .lineLimit(1)
                }

                Text(text)
                    .font(DashboardTypography.body)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(label == nil ? 3 : 4)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: DashboardTextHeightKey.self,
                                value: geometry.size.height
                            )
                        }
                    }
            }

            if let trailingText {
                Spacer(minLength: 4)
                Text(trailingText)
                    .font(DashboardTypography.bodyEmphasis)
                    .foregroundStyle(ContinuumTheme.tabPurple)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, verticalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: isMultiline ? minHeight + 10 : minHeight,
            alignment: .leading
        )
        .background(ContinuumTheme.dashboardPurple.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ContinuumTheme.tabPurple.opacity(0.1), lineWidth: 1)
        )
        .onPreferenceChange(DashboardTextHeightKey.self) { height in
            textBlockHeight = height
        }
    }
}

/// Compact stat tile used for the three-across practice summary row.
struct DashboardCompactStatBox: View {
    let systemImage: String
    let title: String
    let valueLine: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: DashboardTypography.rowIconSize, weight: .semibold))
                .foregroundStyle(ContinuumTheme.tabPurple)
                .frame(width: 24)

            Text(title)
                .font(DashboardTypography.label)
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            Text(valueLine)
                .font(DashboardTypography.bodyEmphasis)
                .foregroundStyle(ContinuumTheme.tabPurple)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: DashboardLayout.miniBoxRowHeight)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(ContinuumTheme.dashboardPurple.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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

/// Dashboard background that fades from purple at the top into home pink at the bottom.
struct DashboardScrollBackground: View {
    let scrollOffset: CGFloat

    var body: some View {
        LinearGradient(
            colors: [topColor, ContinuumTheme.homeLavender, ContinuumTheme.homePink],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topColor: Color {
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
