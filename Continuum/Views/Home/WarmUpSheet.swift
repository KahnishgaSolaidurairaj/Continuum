import SwiftUI

/// Two-slide warm-up sheet opened from the Home motivation card.
struct WarmUpSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var slideIndex = 0

    private var currentExercise: WarmUpExercise {
        WarmUpExercise.slides[slideIndex]
    }

    var body: some View {
        ZStack {
            ContinuumTheme.homeLavender
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Warm Up!")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .foregroundStyle(ContinuumTheme.tabPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                WarmUpSlideCard(exercise: currentExercise)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                completedButton
                    .padding(.bottom, 8)
            }
            .continuumSheetInset()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var completedButton: some View {
        Button(action: advanceSlide) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26, weight: .bold))

                Text("Completed")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .foregroundStyle(ContinuumTheme.pencilLead)
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 32)
            .padding(.vertical, 4)
            .background(ContinuumTheme.homePink)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(ContinuumTheme.tabPurple.opacity(0.25), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Completed")
    }

    /// Advances to the next warm-up slide or dismisses after the final slide.
    private func advanceSlide() {
        if slideIndex < WarmUpExercise.slides.count - 1 {
            slideIndex += 1
        } else {
            dismiss()
        }
    }
}

/// Single warm-up slide styled like the Blow lightly mockup.
private struct WarmUpSlideCard: View {
    let exercise: WarmUpExercise

    var body: some View {
        VStack(spacing: 28) {
            WarmUpIllustration(exercise: exercise)

            VStack(alignment: .leading, spacing: 16) {
                Text(exercise.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DottedDivider()

                Text(exercise.instructions)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 12)

            WarmUpTipBar(tip: exercise.tip)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(ContinuumTheme.tabPurple.opacity(0.2), lineWidth: 2)
        )
    }
}

/// Circular illustration for a warm-up exercise.
private struct WarmUpIllustration: View {
    let exercise: WarmUpExercise

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 148, height: 148)
                .overlay(
                    Circle()
                        .stroke(ContinuumTheme.tabPurple.opacity(0.25), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)

            if exercise.id == "blow_lightly" {
                ZStack {
                    Image(systemName: exercise.iconSystemName)
                        .font(.system(size: 52))
                        .foregroundStyle(exercise.iconAccentColor)
                        .offset(x: -8, y: 6)

                    Image(systemName: "wind")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(ContinuumTheme.stormBlue.opacity(0.8))
                        .offset(x: 28, y: -16)
                }
            } else {
                Image(systemName: exercise.iconSystemName)
                    .font(.system(size: 54))
                    .foregroundStyle(exercise.iconAccentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .accessibilityHidden(true)
    }
}

/// Pale purple tip bar shown below the warm-up card.
private struct WarmUpTipBar: View {
    let tip: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(ContinuumTheme.tabPurple)
                    .frame(width: 36, height: 36)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Tip: \(tip)")
                .font(ContinuumTheme.kidBodyFont)
                .foregroundStyle(ContinuumTheme.tabPurple)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ContinuumTheme.tabPurple.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ContinuumTheme.tabPurple.opacity(0.2), lineWidth: 1.5)
        )
    }
}

/// Dotted horizontal rule between the title and instructions.
private struct DottedDivider: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .foregroundStyle(Color.gray.opacity(0.35))
        }
        .frame(height: 2)
    }
}
