import SwiftUI

/// Switches between the parent and child home experiences.
struct HomeModeToggle: View {
    let isChildMode: Bool
    let onSelectParent: () -> Void
    let onSelectChild: () -> Void
    var usesCompactLayout = false
    var usesVerticalLayout = false
    var fillsAvailableHeight = false

    var body: some View {
        Group {
            if usesVerticalLayout {
                VStack(spacing: fillsAvailableHeight ? 8 : 0) {
                    modeButton(title: "Parent", isSelected: !isChildMode, action: onSelectParent)
                    modeButton(title: "Child", isSelected: isChildMode, action: onSelectChild)
                }
            } else {
                HStack(spacing: 0) {
                    modeButton(title: "Parent", isSelected: !isChildMode, action: onSelectParent)
                    modeButton(title: "Child", isSelected: isChildMode, action: onSelectChild)
                }
            }
        }
        .padding(fillsAvailableHeight ? 6 : (usesVerticalLayout ? 4 : (usesCompactLayout ? 3 : 4)))
        .frame(width: usesVerticalLayout && !fillsAvailableHeight ? nil : (usesCompactLayout ? 196 : nil))
        .frame(maxWidth: usesVerticalLayout ? .infinity : nil, maxHeight: fillsAvailableHeight ? .infinity : nil)
        .background(Color.white.opacity(0.92))
        .clipShape(toggleShape)
        .overlay(toggleShape.stroke(ContinuumTheme.testMagenta.opacity(0.25), lineWidth: 2))
        .shadow(color: ContinuumTheme.testMagenta.opacity(0.12), radius: usesCompactLayout ? 4 : 8, y: usesCompactLayout ? 2 : 4)
        .accessibilityLabel(isChildMode ? "Child mode selected" : "Parent mode selected")
    }

    private var toggleShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: fillsAvailableHeight ? 22 : 999,
            style: .continuous
        )
    }

    private func modeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let cornerRadius: CGFloat = fillsAvailableHeight ? 17 : 999

        return Button(action: action) {
            Text(title)
                .font(.system(
                    size: fillsAvailableHeight ? 17 : (usesVerticalLayout ? 15 : (usesCompactLayout ? 14 : 17)),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(isSelected ? .white : ContinuumTheme.testMagenta)
                .frame(maxWidth: .infinity, maxHeight: fillsAvailableHeight ? .infinity : nil)
                .padding(.vertical, fillsAvailableHeight ? 0 : (usesVerticalLayout ? 10 : (usesCompactLayout ? 7 : 10)))
                .padding(.horizontal, usesVerticalLayout ? 8 : 0)
                .background(isSelected ? ContinuumTheme.testMagenta : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .fullRoundedHitTarget(cornerRadius: cornerRadius)
        }
        .buttonStyle(.plain)
    }
}
