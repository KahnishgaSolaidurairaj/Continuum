import SwiftUI

/// Shared layout chrome for the four practice activities.
enum PracticeActivityChrome {
    static let contentHorizontalPadding: CGFloat = 36
    static let contentVerticalPadding: CGFloat = 40
    static let contentSpacing: CGFloat = 24
    static let cardInnerPadding: CGFloat = 24

    /// Returns horizontal padding for the active device layout.
    static func contentHorizontalPadding(for layout: ContinuumDeviceLayout) -> CGFloat {
        layout.scaled(contentHorizontalPadding, phone: 18)
    }

    /// Returns vertical padding for the active device layout.
    static func contentVerticalPadding(for layout: ContinuumDeviceLayout) -> CGFloat {
        layout.scaled(contentVerticalPadding, phone: 24)
    }

    /// Returns card inner padding for the active device layout.
    static func cardInnerPadding(for layout: ContinuumDeviceLayout) -> CGFloat {
        layout.scaled(cardInnerPadding, phone: 18)
    }

    /// Background gradient for a practice activity screen.
    static func background(for activity: PracticeActivity) -> LinearGradient {
        switch activity {
        case .sandbox:
            return LinearGradient(
                colors: [ContinuumTheme.beachCoral, ContinuumTheme.beachSunYellow, ContinuumTheme.shellCream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .flash:
            return LinearGradient(
                colors: [
                    ContinuumTheme.homeLavender,
                    ContinuumTheme.sandboxMintSoft,
                    ContinuumTheme.homeMint.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .tryDemo:
            return LinearGradient(
                colors: [
                    ContinuumTheme.tryBlueSoft,
                    ContinuumTheme.stormSky,
                    ContinuumTheme.homeLavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .test:
            return LinearGradient(
                colors: [
                    ContinuumTheme.homePink,
                    ContinuumTheme.testPinkSoft,
                    ContinuumTheme.homeLavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// Header card shown at the top of each practice activity.
struct PracticeActivityHeader: View {
    var title: String? = nil
    let subtitle: String
    let detail: String
    var subtitleFont: Font? = nil
    var borderColor: Color = ContinuumTheme.tabPurple.opacity(0.2)

    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        VStack(spacing: 8) {
            if let title {
                Text(title)
                    .font(ContinuumTheme.kidSectionHeaderFont(for: layout))
                    .foregroundStyle(ContinuumTheme.tabPurple)
            }

            Text(subtitle)
                .font(subtitleFont ?? ContinuumTheme.kidSubheadFont(for: layout))
                .foregroundStyle(ContinuumTheme.pencilLead)

            Text(detail)
                .font(ContinuumTheme.kidBodyFont(for: layout))
                .foregroundStyle(ContinuumTheme.subtitleGray)
                .multilineTextAlignment(.center)
        }
        .padding(PracticeActivityChrome.cardInnerPadding(for: layout))
        .frame(maxWidth: .infinity)
        .practiceActivityCardStyle(borderColor: borderColor)
    }
}

/// Scroll container that vertically centers content and applies generous page padding.
struct PracticeActivityScrollLayout<Content: View>: View {
    var spacing: CGFloat = PracticeActivityChrome.contentSpacing
    @ViewBuilder var content: () -> Content

    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: PracticeActivityChrome.contentVerticalPadding(for: layout))

                    VStack(spacing: spacing) {
                        content()
                    }
                    .padding(.horizontal, PracticeActivityChrome.contentHorizontalPadding(for: layout))
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: PracticeActivityChrome.contentVerticalPadding(for: layout))
                }
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

/// Primary filled action button for practice activities.
struct PracticePrimaryButton: View {
    let title: String
    let systemImage: String
    var accent: Color = ContinuumTheme.tabPurple
    let action: () -> Void

    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(ContinuumTheme.kidButtonFont(for: layout))
                .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight(for: layout))
                .foregroundStyle(.white)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: accent.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// Outlined secondary action button for practice activities.
struct PracticeSecondaryButton: View {
    let title: String
    let systemImage: String
    var accent: Color = ContinuumTheme.tabPurple
    let action: () -> Void

    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(ContinuumTheme.kidButtonFont(for: layout))
                .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight(for: layout))
                .foregroundStyle(accent)
                .background(Color.white.opacity(0.97))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accent.opacity(0.35), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// Shared white card styling for practice activity content blocks.
    func practiceActivityCardStyle(borderColor: Color = ContinuumTheme.tabPurple.opacity(0.2)) -> some View {
        background(Color.white.opacity(0.97))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
            )
            .shadow(color: ContinuumTheme.navBarShadow, radius: 8, y: 4)
    }
}
