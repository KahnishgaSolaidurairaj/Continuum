import SwiftUI

/// Flash activity: phoneme and word practice with three lightning-themed levels.
struct FlashActivityView: View {
    let target: PracticeTarget

    @Environment(\.continuumDeviceLayout) private var layout

    @State private var selectedLevel: FlashLevel = .sound
    @State private var wordIndex = 0

    private let speechService = SpeechSynthesisService()
    private let referencePlayback = ReferenceAudioPlaybackService()

    private var levelWords: [String] {
        FlashWordBank.words(for: target, level: selectedLevel)
    }

    private var currentWord: String {
        levelWords[wordIndex % max(levelWords.count, 1)]
    }

    private var hasWordsForSelectedLevel: Bool {
        !levelWords.isEmpty
    }

    var body: some View {
        PracticeActivityScrollLayout {
            flashInstructions

            levelPicker
                .padding(.horizontal, layout.scaled(28, phone: 16))
                .padding(.vertical, layout.scaled(28, phone: 18))
                .practiceActivityCardStyle()

            flashcard
                .frame(maxWidth: .infinity)
                .frame(minHeight: layout.scaled(360, phone: 260))

            if selectedLevel != .sound && levelWords.count > 1 {
                PracticeSecondaryButton(title: "Next word", systemImage: "arrow.right.circle.fill") {
                    wordIndex = (wordIndex + 1) % levelWords.count
                }
            }

            if !hasWordsForSelectedLevel && selectedLevel != .sound {
                Text("More words coming soon for this level.")
                    .font(ContinuumTheme.kidCaptionFont)
                    .foregroundStyle(ContinuumTheme.subtitleGray)
                    .multilineTextAlignment(.center)
            }

            hearItButton
                .disabled(!hasWordsForSelectedLevel && selectedLevel != .sound)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PracticeActivityChrome.background(for: .flash))
        .onChange(of: selectedLevel) { _, _ in
            wordIndex = 0
        }
        .onDisappear {
            referencePlayback.stop()
        }
    }

    /// Top instructions shown directly on the page background.
    private var flashInstructions: some View {
        VStack(spacing: 8) {
            Text("Listen to the sound")
                .font(ContinuumTheme.kidSectionHeaderFont(for: layout))
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)

            Text("Practice \(target.displayLabel)")
                .font(ContinuumTheme.kidBodyFont(for: layout))
                .foregroundStyle(ContinuumTheme.subtitleGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    /// Three large level buttons for sound, short words, and long words.
    private var levelPicker: some View {
        VStack(spacing: 16) {
            Text("Level")
                .font(ContinuumTheme.kidSectionHeaderFont(for: layout))
                .foregroundStyle(ContinuumTheme.tabPurple)

            Group {
                if layout.isPhone {
                    VStack(spacing: 10) {
                        levelButtons
                    }
                } else {
                    HStack(spacing: 12) {
                        levelButtons
                    }
                }
            }
        }
    }

    private var levelButtons: some View {
        ForEach(FlashLevel.allCases) { level in
            Button {
                selectedLevel = level
            } label: {
                VStack(spacing: 6) {
                    Text(level.label)
                        .font(ContinuumTheme.kidButtonFont(for: layout))
                    Text(level.subtitle)
                        .font(ContinuumTheme.kidCaptionFont(for: layout))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(
                    selectedLevel == level ? .white : ContinuumTheme.sandboxMint
                )
                .frame(maxWidth: .infinity, minHeight: layout.scaled(72, phone: 56))
                .padding(.horizontal, 6)
                .padding(.vertical, layout.scaled(10, phone: 8))
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            selectedLevel == level
                                ? ContinuumTheme.tabPurple
                                : ContinuumTheme.sandboxMintSoft
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            selectedLevel == level
                                ? ContinuumTheme.tabPurple
                                : ContinuumTheme.sandboxMint.opacity(0.45),
                            lineWidth: 1.5
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(level.label), \(level.subtitle)")
            .accessibilityAddTraits(selectedLevel == level ? .isSelected : [])
        }
    }

    /// Large card showing the phoneme or word for the active level.
    private var flashcard: some View {
        let cardHeight = layout.scaled(360, phone: 260)

        return ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.97))

            LightningCornerDecoration()

            VStack(spacing: 24) {
                if selectedLevel != .sound {
                    practiceBadge
                }

                if selectedLevel == .sound {
                    Text(target.displayLabel)
                        .font(.system(size: layout.scaled(96, phone: 64), weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.tabPurple)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else if hasWordsForSelectedLevel {
                    highlightedWordView(
                        word: currentWord,
                        font: .system(size: wordFontSize(for: currentWord, cardHeight: cardHeight), weight: .bold, design: .rounded)
                    )
                    .minimumScaleFactor(0.45)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                } else {
                    Text("No words yet")
                        .font(ContinuumTheme.kidSectionHeaderFont(for: layout))
                        .foregroundStyle(ContinuumTheme.subtitleGray)
                }
            }
            .padding(.vertical, layout.scaled(32, phone: 24))
            .padding(.horizontal, layout.scaled(24, phone: 16))
        }
        .practiceActivityCardStyle()
    }

    /// Shows which sound the child is practicing on word levels.
    private var practiceBadge: some View {
        Text("Practice: \(target.displayLabel)")
            .font(layout.font(28, phoneSize: 22, weight: .bold))
            .foregroundStyle(ContinuumTheme.sandboxMint)
            .padding(.horizontal, layout.scaled(28, phone: 18))
            .padding(.vertical, layout.scaled(16, phone: 12))
            .background(ContinuumTheme.sandboxMintSoft)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(ContinuumTheme.sandboxMint.opacity(0.45), lineWidth: 1.5)
            )
    }

    /// Plays audio for the phoneme example or the active word.
    private var hearItButton: some View {
        PracticePrimaryButton(
            title: "Hear it",
            systemImage: "speaker.wave.2.fill",
            accent: ContinuumTheme.sandboxMint
        ) {
            if selectedLevel == .sound {
                referencePlayback.playReference(for: target.id)
            } else {
                speechService.speakWord(currentWord)
            }
        }
    }

    /// Scales word text down slightly for longer words so it stays readable.
    private func wordFontSize(for word: String, cardHeight: CGFloat) -> CGFloat {
        let baseSize = cardHeight * 0.28
        switch word.count {
        case ...4: return baseSize
        case 5...6: return baseSize * 0.88
        case 7...8: return baseSize * 0.78
        default: return baseSize * 0.64
        }
    }

    /// Renders a flash word with the target sound letters emphasized.
    private func highlightedWordView(word: String, font: Font) -> some View {
        HighlightedWordText(
            word: word,
            highlights: FlashWordBank.highlights(for: target, word: word),
            font: font,
            baseColor: ContinuumTheme.pencilLead,
            highlightColor: ContinuumTheme.sandboxMint
        )
    }
}

// MARK: - Lightning Decorations

/// Places small lightning bolts in the card corners.
private struct LightningCornerDecoration: View {
    var body: some View {
        GeometryReader { geometry in
            lightningBolt(size: 34, rotation: -25)
                .position(x: 28, y: 24)
            lightningBolt(size: 28, rotation: 155)
                .position(x: geometry.size.width - 24, y: geometry.size.height - 22)
        }
        .allowsHitTesting(false)
    }

    private func lightningBolt(size: CGFloat, rotation: Double) -> some View {
        LightningBoltShape()
            .fill(ContinuumTheme.sandboxMint.opacity(0.4))
            .frame(width: size, height: size * 1.2)
            .rotationEffect(.degrees(rotation))
            .shadow(color: ContinuumTheme.tabPurple.opacity(0.2), radius: 2)
    }
}

/// Simple zig-zag bolt shape for flash decorations.
private struct LightningBoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.62, y: rect.height * 0.42))
        path.addLine(to: CGPoint(x: rect.width * 0.48, y: rect.height * 0.42))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.58))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.58))
        path.closeSubpath()
        return path
    }
}
