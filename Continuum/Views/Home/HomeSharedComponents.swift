import SwiftUI

/// Shared motivation quote row used on parent and child home screens.
struct HomeMotivationRow: View {
    let motivationMessage: String
    let brocaPoseName: String
    let confettiTrigger: Int
    let onRefresh: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(brocaPoseName)
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .accessibilityLabel("Broca the Bear")
                .animation(.spring(response: 0.35, dampingFraction: 0.72), value: brocaPoseName)

            HStack(alignment: .top, spacing: 8) {
                Text("“")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.tabPurple.opacity(0.7))
                    .offset(y: -10)

                Text(motivationMessage)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Button(action: onRefresh) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                    Text("Motivation!")
                }
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(minHeight: ContinuumTheme.kidMinTapHeight)
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
        .padding(22)
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
}

/// Shared daily streak row used on parent and child home screens.
struct HomeStreakRow: View {
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.78, green: 0.96, blue: 0.82), ContinuumTheme.homeMint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                Image(systemName: "flame.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(ContinuumTheme.homeMintText)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("\(PracticeProgressStore.currentStreak) day streak")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(ContinuumTheme.pencilLead)
                Text("Keep it up! You're doing great.")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 12) {
                ForEach(streakDayIndicators.indices, id: \.self) { index in
                    let practiced = streakDayIndicators[index]
                    ZStack {
                        Circle()
                            .fill(practiced ? ContinuumTheme.homeMint : Color.white)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(
                                        practiced ? ContinuumTheme.homeMintText.opacity(0.5) : Color.gray.opacity(0.25),
                                        lineWidth: 2
                                    )
                            )
                        if practiced {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(ContinuumTheme.homeMintText)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 120)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.22))
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.pencilLead)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(description)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.75))
                        .lineLimit(4)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(accentColor)
                    .clipShape(Capsule())
                    .fullCapsuleHitTarget()
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: .infinity, alignment: .topLeading)
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
