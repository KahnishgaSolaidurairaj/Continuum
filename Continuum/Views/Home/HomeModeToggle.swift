import SwiftUI

/// Switches between the parent and child home experiences.
struct HomeModeToggle: View {
    let isChildMode: Bool
    let onSelectParent: () -> Void
    let onSelectChild: () -> Void
    var usesCompactLayout = false
    var usesVerticalLayout = false

    var body: some View {
        Group {
            if usesVerticalLayout {
                VStack(spacing: 0) {
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
        .padding(usesVerticalLayout ? 4 : (usesCompactLayout ? 3 : 4))
        .frame(width: usesVerticalLayout ? nil : (usesCompactLayout ? 196 : nil))
        .frame(maxWidth: usesVerticalLayout ? .infinity : nil)
        .background(Color.white.opacity(0.92))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(ContinuumTheme.testMagenta.opacity(0.25), lineWidth: 2)
        )
        .shadow(color: ContinuumTheme.testMagenta.opacity(0.12), radius: usesCompactLayout ? 4 : 8, y: usesCompactLayout ? 2 : 4)
        .accessibilityLabel(isChildMode ? "Child mode selected" : "Parent mode selected")
    }

    private func modeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(
                    size: usesVerticalLayout ? 15 : (usesCompactLayout ? 14 : 17),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(isSelected ? .white : ContinuumTheme.testMagenta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, usesVerticalLayout ? 10 : (usesCompactLayout ? 7 : 10))
                .padding(.horizontal, usesVerticalLayout ? 8 : 0)
                .background(isSelected ? ContinuumTheme.testMagenta : Color.clear)
                .clipShape(Capsule())
                .fullCapsuleHitTarget()
        }
        .buttonStyle(.plain)
    }
}
