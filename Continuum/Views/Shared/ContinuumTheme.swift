import SwiftUI

/// Shared colors and styling aligned to the Continuum wireframes.
enum ContinuumTheme {
    static let homePink = Color(red: 0.98, green: 0.86, blue: 0.89)
    static let homeLavender = Color(red: 0.88, green: 0.84, blue: 0.95)
    static let tabPurple = Color(red: 0.58, green: 0.48, blue: 0.78)
    static let dashboardPurple = Color(red: 0.78, green: 0.73, blue: 0.92)
    static let practiceCream = Color(red: 0.98, green: 0.96, blue: 0.88)
    static let cardBorder = Color.black.opacity(0.85)

    // Beach sandbox palette
    static let sandYellow = Color(red: 0.95, green: 0.88, blue: 0.58)
    static let sandGrain = Color(red: 0.86, green: 0.74, blue: 0.42)
    static let shellPink = Color(red: 0.96, green: 0.82, blue: 0.78)
    static let shellCream = Color(red: 0.99, green: 0.94, blue: 0.86)
    static let pencilLead = Color(red: 0.22, green: 0.32, blue: 0.52)

    /// Large rounded title for kid-readable navigation and section headers.
    static let kidNavigationTitleFont: Font = .system(size: 34, weight: .bold, design: .rounded)
    static let kidSectionHeaderFont: Font = .system(size: 30, weight: .bold, design: .rounded)
}

extension View {
    /// Applies a large, centered navigation title that is easy for kids to read.
    func kidFriendlyNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(ContinuumTheme.kidNavigationTitleFont)
                }
            }
    }
}
