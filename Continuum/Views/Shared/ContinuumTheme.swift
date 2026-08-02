import SwiftUI

/// Shared colors and styling aligned to the Continuum wireframes.
enum ContinuumTheme {
    static let homePink = Color(red: 0.98, green: 0.86, blue: 0.89)
    static let homeLavender = Color(red: 0.88, green: 0.84, blue: 0.95)
    static let homePracticePurple = Color(red: 0.38, green: 0.28, blue: 0.62)
    static let homePracticePurpleDeep = Color(red: 0.30, green: 0.22, blue: 0.52)
    static let tabPurple = Color(red: 0.58, green: 0.48, blue: 0.78)
    static let dashboardPurple = Color(red: 0.78, green: 0.73, blue: 0.92)
    static let practiceCream = Color(red: 0.98, green: 0.96, blue: 0.88)
    static let homeOffWhite = Color(red: 0.97, green: 0.96, blue: 0.98)
    static let homeMint = Color(red: 0.82, green: 0.94, blue: 0.86)
    static let homeMintText = Color(red: 0.18, green: 0.48, blue: 0.34)
    static let cardBorder = Color.black.opacity(0.85)

    // Beach sandbox palette
    static let sandYellow = Color(red: 0.95, green: 0.88, blue: 0.58)
    static let sandGrain = Color(red: 0.86, green: 0.74, blue: 0.42)
    static let shellPink = Color(red: 0.96, green: 0.82, blue: 0.78)
    static let shellCream = Color(red: 0.99, green: 0.94, blue: 0.86)
    static let beachCoralPen = Color(red: 0.82, green: 0.36, blue: 0.42)
    static let beachCoral = Color(red: 1.0, green: 0.58, blue: 0.42)
    static let beachSunYellow = Color(red: 1.0, green: 0.93, blue: 0.52)
    static let pencilLead = Color(red: 0.22, green: 0.32, blue: 0.52)

    // Lightning flash palette
    static let lightningYellow = Color(red: 1.0, green: 0.93, blue: 0.45)
    static let lightningGlow = Color(red: 1.0, green: 0.98, blue: 0.65)
    static let stormBlue = Color(red: 0.35, green: 0.58, blue: 0.88)
    static let stormBlueDeep = Color(red: 0.18, green: 0.38, blue: 0.72)
    static let stormSky = Color(red: 0.78, green: 0.88, blue: 0.98)

    // Practice hub palette
    static let practicePageLavender = Color(red: 0.93, green: 0.90, blue: 0.98)
    static let practicePageCream = Color(red: 0.99, green: 0.98, blue: 0.94)
    static let navInactive = Color(red: 0.62, green: 0.64, blue: 0.70)
    static let navBarShadow = Color.black.opacity(0.08)

    static let sandboxMint = Color(red: 0.25, green: 0.65, blue: 0.45)
    static let sandboxMintSoft = Color(red: 0.92, green: 0.97, blue: 0.93)
    static let flashLavenderSoft = Color(red: 0.94, green: 0.91, blue: 0.98)
    static let tryBlueSoft = Color(red: 0.90, green: 0.94, blue: 0.99)
    static let testMagenta = Color(red: 0.62, green: 0.28, blue: 0.58)
    static let testPinkSoft = Color(red: 0.98, green: 0.91, blue: 0.94)
    static let subtitleGray = Color(red: 0.45, green: 0.47, blue: 0.52)

    /// Shared left/right inset for main tab scroll content.
    static let pageHorizontalPadding: CGFloat = 28

    /// Large rounded title for kid-readable navigation and section headers.
    static let kidNavigationTitleFont: Font = .system(size: 34, weight: .bold, design: .rounded)
    static let kidSectionHeaderFont: Font = .system(size: 30, weight: .bold, design: .rounded)
    static let kidBodyFont: Font = .system(size: 22, weight: .medium, design: .rounded)
    static let kidSubheadFont: Font = .system(size: 20, weight: .semibold, design: .rounded)
    static let kidButtonFont: Font = .system(size: 22, weight: .bold, design: .rounded)
    static let kidCaptionFont: Font = .system(size: 18, weight: .medium, design: .rounded)
    static let kidMinTapHeight: CGFloat = 56

    /// Returns page horizontal padding for the active device layout.
    static func pageHorizontalPadding(for layout: ContinuumDeviceLayout) -> CGFloat {
        layout.scaled(pageHorizontalPadding, phone: 16)
    }

    /// Returns the kid navigation title font for the active device layout.
    static func kidNavigationTitleFont(for layout: ContinuumDeviceLayout) -> Font {
        layout.font(34, phoneSize: 28, weight: .bold)
    }

    /// Returns the kid section header font for the active device layout.
    static func kidSectionHeaderFont(for layout: ContinuumDeviceLayout) -> Font {
        layout.font(30, phoneSize: 24, weight: .bold)
    }

    /// Returns the kid body font for the active device layout.
    static func kidBodyFont(for layout: ContinuumDeviceLayout) -> Font {
        layout.font(22, phoneSize: 18, weight: .medium)
    }

    /// Returns the kid subhead font for the active device layout.
    static func kidSubheadFont(for layout: ContinuumDeviceLayout) -> Font {
        layout.font(20, phoneSize: 17, weight: .semibold)
    }

    /// Returns the kid button font for the active device layout.
    static func kidButtonFont(for layout: ContinuumDeviceLayout) -> Font {
        layout.font(22, phoneSize: 18, weight: .bold)
    }

    /// Returns the kid caption font for the active device layout.
    static func kidCaptionFont(for layout: ContinuumDeviceLayout) -> Font {
        layout.font(18, phoneSize: 15, weight: .medium)
    }

    /// Returns the minimum tap height for the active device layout.
    static func kidMinTapHeight(for layout: ContinuumDeviceLayout) -> CGFloat {
        layout.scaled(kidMinTapHeight, phone: 48)
    }
}

private struct HomePracticeCapsuleStyleModifier: ViewModifier {
    @Environment(\.continuumDeviceLayout) private var layout

    func body(content: Content) -> some View {
        content
            .font(layout.font(24, phoneSize: 20, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: layout.scaled(64, phone: 52))
            .background(
                LinearGradient(
                    colors: [ContinuumTheme.tabPurple, Color(red: 0.68, green: 0.52, blue: 0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: ContinuumTheme.tabPurple.opacity(0.28), radius: 8, y: 4)
            .fullCapsuleHitTarget()
    }
}

private struct KidPrimaryButtonStyleModifier: ViewModifier {
    @Environment(\.continuumDeviceLayout) private var layout
    let background: Color
    let foreground: Color

    func body(content: Content) -> some View {
        content
            .font(ContinuumTheme.kidButtonFont(for: layout))
            .foregroundStyle(foreground)
            .padding(.horizontal, layout.scaled(24, phone: 18))
            .padding(.vertical, layout.scaled(16, phone: 12))
            .frame(minHeight: ContinuumTheme.kidMinTapHeight(for: layout))
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct KidSecondaryButtonStyleModifier: ViewModifier {
    @Environment(\.continuumDeviceLayout) private var layout

    func body(content: Content) -> some View {
        content
            .font(ContinuumTheme.kidButtonFont(for: layout))
            .foregroundStyle(ContinuumTheme.tabPurple)
            .padding(.horizontal, layout.scaled(24, phone: 18))
            .padding(.vertical, layout.scaled(16, phone: 12))
            .frame(minHeight: ContinuumTheme.kidMinTapHeight(for: layout))
            .background(.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ContinuumTheme.cardBorder.opacity(0.25), lineWidth: 2)
            )
    }
}

private struct ContinuumSheetInsetModifier: ViewModifier {
    @Environment(\.continuumDeviceLayout) private var layout

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, layout.scaled(28, phone: 16))
            .padding(.vertical, layout.scaled(28, phone: 16))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: layout.scaled(36, phone: 28))
                    .strokeBorder(ContinuumTheme.tabPurple.opacity(0.5), lineWidth: 5)
            }
            .padding(.horizontal, layout.scaled(20, phone: 12))
            .padding(.vertical, layout.scaled(20, phone: 12))
    }
}

extension View {
    /// Applies the theme purple capsule styling used for home practice buttons.
    func homePracticeCapsuleStyle() -> some View {
        modifier(HomePracticeCapsuleStyleModifier())
    }

    /// Applies a large, centered navigation title that is easy for kids to read.
    func kidFriendlyNavigationTitle(_ title: String) -> some View {
        modifier(KidFriendlyNavigationTitleModifier(title: title))
    }

    /// Applies kid-friendly primary button styling with a large tap target.
    func kidPrimaryButtonStyle(
        background: Color = ContinuumTheme.tabPurple,
        foreground: Color = .white
    ) -> some View {
        modifier(KidPrimaryButtonStyleModifier(background: background, foreground: foreground))
    }

    /// Applies kid-friendly secondary button styling with a large tap target.
    func kidSecondaryButtonStyle() -> some View {
        modifier(KidSecondaryButtonStyleModifier())
    }

    /// Applies warm-up-style outer inset and purple border for full-screen kid sheets.
    func continuumSheetInset() -> some View {
        modifier(ContinuumSheetInsetModifier())
    }

    /// Applies styling for selectable list rows in sheets.
    func kidChoiceButtonStyle(isSelected: Bool) -> some View {
        self
            .background(.white.opacity(isSelected ? 1 : 0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? ContinuumTheme.tabPurple : ContinuumTheme.cardBorder.opacity(0.15),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Ensures taps register across an entire capsule-shaped button label.
    func fullCapsuleHitTarget() -> some View {
        contentShape(Capsule())
    }

    /// Ensures taps register across an entire rounded-rectangle button label.
    func fullRoundedHitTarget(cornerRadius: CGFloat) -> some View {
        contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct KidFriendlyNavigationTitleModifier: ViewModifier {
    @Environment(\.continuumDeviceLayout) private var layout
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(ContinuumTheme.kidNavigationTitleFont(for: layout))
                }
            }
    }
}
