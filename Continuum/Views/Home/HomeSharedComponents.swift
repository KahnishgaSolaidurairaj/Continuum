import SwiftUI

/// Shared motivation quote row used on parent and child home screens.
struct HomeMotivationRow: View {
    let motivationMessage: String
    let brocaPoseName: String
    let confettiTrigger: Int
    let onRefresh: () -> Void

    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        Group {
            if layout.isPhone {
                phoneLayout
            } else {
                padLayout
            }
        }
        .padding(layout.scaled(22, phone: 16))
        .background(
            LinearGradient(
                colors: [ContinuumTheme.homeLavender.opacity(0.7), ContinuumTheme.homePink.opacity(0.45)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            ConfettiBurstView(trigger: confettiTrigger)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }

    private var padLayout: some View {
        HStack(alignment: .center, spacing: 16) {
            brocaImage(size: 104)
            quoteBlock(fontSize: 28, quoteMarkSize: 48)
            motivationButton
        }
    }

    private var phoneLayout: some View {
        VStack(spacing: 14) {
            brocaImage(size: 72)
            quoteBlock(fontSize: 20, quoteMarkSize: 32)
            motivationButton
                .frame(maxWidth: .infinity)
        }
    }

    private func brocaImage(size: CGFloat) -> some View {
        Image(brocaPoseName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            .accessibilityLabel("Broca the Bear")
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: brocaPoseName)
    }

    private func quoteBlock(fontSize: CGFloat, quoteMarkSize: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("“")
                .font(.system(size: quoteMarkSize, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.tabPurple.opacity(0.7))
                .offset(y: layout.isPhone ? -6 : -10)

            Text(motivationMessage)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var motivationButton: some View {
        Button(action: onRefresh) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: layout.scaled(20, phone: 16), weight: .bold))
                Text("Motivation!")
            }
            .font(layout.font(22, phoneSize: 18, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, layout.scaled(24, phone: 18))
            .padding(.vertical, layout.scaled(14, phone: 12))
            .frame(minHeight: ContinuumTheme.kidMinTapHeight(for: layout))
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
        .buttonStyle(.plain)
    }
}

/// Shared daily streak row used on parent and child home screens.
struct HomeStreakRow: View {
    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        Group {
            if layout.isPhone {
                phoneLayout
            } else {
                padLayout
            }
        }
        .padding(.horizontal, layout.scaled(22, phone: 16))
        .padding(.vertical, layout.scaled(24, phone: 18))
        .frame(maxWidth: .infinity, minHeight: layout.scaled(120, phone: 100))
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ContinuumTheme.sandboxMintSoft.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(ContinuumTheme.homeMint.opacity(0.85), lineWidth: 2.5)
        )
        .shadow(color: ContinuumTheme.homeMintText.opacity(0.14), radius: 8, y: 4)
    }

    private var padLayout: some View {
        HStack(spacing: 20) {
            streakFlameCircle(size: 78, iconSize: 34)
            streakTextBlock(titleSize: 30, subtitleSize: 20)
            Spacer(minLength: 12)
            dayIndicators(circleSize: 38, spacing: 12)
        }
    }

    private var phoneLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                streakFlameCircle(size: 60, iconSize: 28)
                streakTextBlock(titleSize: 24, subtitleSize: 17)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                dayIndicators(circleSize: 30, spacing: 10)
            }
        }
    }

    private func streakFlameCircle(size: CGFloat, iconSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.78, green: 0.96, blue: 0.82), ContinuumTheme.homeMint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Image(systemName: "flame.fill")
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(ContinuumTheme.homeMintText)
        }
    }

    private func streakTextBlock(titleSize: CGFloat, subtitleSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(PracticeProgressStore.currentStreak) day streak")
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.pencilLead)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("Keep it up! You're doing great.")
                .font(.system(size: subtitleSize, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private func dayIndicators(circleSize: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(streakDayIndicators.indices, id: \.self) { index in
                let practiced = streakDayIndicators[index]
                ZStack {
                    Circle()
                        .fill(practiced ? ContinuumTheme.homeMint : Color.white)
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(
                                    practiced ? ContinuumTheme.homeMintText.opacity(0.5) : Color.gray.opacity(0.25),
                                    lineWidth: 2
                                )
                        )
                    if practiced {
                        Image(systemName: "checkmark")
                            .font(.system(size: layout.scaled(16, phone: 13), weight: .bold))
                            .foregroundStyle(ContinuumTheme.homeMintText)
                    }
                }
            }
        }
    }

    private var streakDayIndicators: [Bool] {
        let filledCount = min(PracticeProgressStore.currentStreak, 5)
        return (0..<5).map { index in
            index < filledCount
        }
    }
}

/// One suggestion tile in the home grid.
struct HomeSuggestionCard: View {
    enum Tint {
        case purple
        case green
        case blue
    }

    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let tint: Tint
    let action: () -> Void

    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.22))
                        .frame(
                            width: layout.scaled(54, phone: 44),
                            height: layout.scaled(54, phone: 44)
                        )
                    Image(systemName: icon)
                        .font(.system(size: layout.scaled(24, phone: 20), weight: .bold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(layout.font(26, phoneSize: 22, weight: .bold))
                        .foregroundStyle(ContinuumTheme.pencilLead)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(description)
                        .font(layout.font(20, phoneSize: 17, weight: .semibold))
                        .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.75))
                        .lineLimit(4)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Button(action: action) {
                Text(buttonTitle)
                    .font(layout.font(21, phoneSize: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: layout.scaled(48, phone: 44))
                    .padding(.horizontal, 16)
                    .padding(.vertical, layout.scaled(13, phone: 10))
                    .background(accentColor)
                    .clipShape(Capsule())
                    .fullCapsuleHitTarget()
            }
            .buttonStyle(.plain)
        }
        .padding(layout.scaled(18, phone: 14))
        .frame(
            maxWidth: .infinity,
            minHeight: layout.scaled(180, phone: 140),
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            LinearGradient(
                colors: [accentColor.opacity(0.16), accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.28), lineWidth: 2)
        )
        .shadow(color: accentColor.opacity(0.14), radius: 6, y: 3)
    }

    private var accentColor: Color {
        switch tint {
        case .green:
            ContinuumTheme.homeMintText
        case .purple:
            ContinuumTheme.tabPurple
        case .blue:
            ContinuumTheme.stormBlue
        }
    }
}
