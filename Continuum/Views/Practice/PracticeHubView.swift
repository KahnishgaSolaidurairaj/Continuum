import SwiftUI

/// Practice tab entry: pick a target, browse activities, launch one full-screen.
struct PracticeHubView: View {
    let initialTarget: PracticeTarget?

    @State private var selectedTarget: PracticeTarget?
    @State private var activeActivity: PracticeActivity?

    var body: some View {
        NavigationStack {
            Group {
                if let target = selectedTarget {
                    ActivityCarouselView(
                        target: target,
                        onSelectActivity: { activity in
                            activeActivity = activity
                        },
                        onBack: {
                            selectedTarget = nil
                        }
                    )
                } else {
                    PhonemeSelectionView { target in
                        selectedTarget = target
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ContinuumTheme.practiceCream)
            .navigationDestination(item: $activeActivity) { activity in
                if let target = selectedTarget {
                    ActivityDetailView(target: target, activity: activity)
                }
            }
        }
        .onAppear {
            if selectedTarget == nil {
                selectedTarget = initialTarget
            }
        }
        .onChange(of: initialTarget?.id) { _, _ in
            if let initialTarget {
                selectedTarget = initialTarget
            }
        }
    }
}

/// Wireframe step 1: choose alphabet letter or sound.
struct PhonemeSelectionView: View {
    enum PickerMode: String, CaseIterable {
        case alphabet = "Which Alphabet?"
        case sounds = "Which Sound?"
    }

    let onSelect: (PracticeTarget) -> Void

    @State private var mode: PickerMode = .sounds

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Mode", selection: $mode) {
                    ForEach(PickerMode.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Text(mode.rawValue)
                    .font(ContinuumTheme.kidSectionHeaderFont)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: mode == .alphabet ? 7 : 4), spacing: 12) {
                    ForEach(currentTargets) { target in
                        Button {
                            onSelect(target)
                        } label: {
                            Text(target.symbol)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(ContinuumTheme.cardBorder, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    private var currentTargets: [PracticeTarget] {
        mode == .alphabet ? PracticeTarget.alphabet : PracticeTarget.sounds
    }
}

/// Wireframe step 2: horizontal carousel of the selected target.
struct ActivityCarouselView: View {
    let target: PracticeTarget
    let onSelectActivity: (PracticeActivity) -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .font(ContinuumTheme.kidButtonFont)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.85))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal)

            Text("Practice “\(target.symbol)”")
                .font(ContinuumTheme.kidSectionHeaderFont)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.45))
                    .frame(height: 220)

                Text(target.symbol.uppercased())
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.25))
            }
            .padding(.horizontal)

            Text("Choose an activity")
                .font(ContinuumTheme.kidSubheadFont)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(PracticeActivity.allCases) { activity in
                        Button {
                            onSelectActivity(activity)
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: activity.systemImage)
                                    .font(.system(size: 44))
                                Text(activity.subtitle)
                                    .font(ContinuumTheme.kidSubheadFont)
                                Text(activity.title)
                                    .font(ContinuumTheme.kidCaptionFont)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 180, height: 180)
                            .background(.white.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(ContinuumTheme.cardBorder, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
    }
}

/// Routes to the selected practice activity screen.
struct ActivityDetailView: View {
    let target: PracticeTarget
    let activity: PracticeActivity

    var body: some View {
        Group {
            switch activity {
            case .sandbox:
                SandboxActivityView(target: target)
            case .flash:
                FlashActivityView(target: target)
            case .tryDemo:
                TryActivityView(target: target)
            case .test:
                TestActivityView(target: target)
            }
        }
        .kidFriendlyNavigationTitle(activity.subtitle)
    }
}

extension PracticeActivity: Hashable {}
