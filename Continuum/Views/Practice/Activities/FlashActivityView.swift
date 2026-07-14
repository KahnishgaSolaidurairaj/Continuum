import SwiftUI

/// Flash activity: phoneme and word practice with three lightning-themed levels.
struct FlashActivityView: View {
    let target: PracticeTarget

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
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Text("Flashcards ⚡")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .foregroundStyle(ContinuumTheme.stormBlueDeep)

                levelPicker

                flashcard(cardHeight: geometry.size.height * 0.52)

                if selectedLevel != .sound && levelWords.count > 1 {
                    nextWordButton
                }

                if !hasWordsForSelectedLevel && selectedLevel != .sound {
                    Text("More words coming soon for this level.")
                        .font(ContinuumTheme.kidCaptionFont)
                        .foregroundStyle(ContinuumTheme.stormBlue)
                        .multilineTextAlignment(.center)
                }

                hearItButton
                    .disabled(!hasWordsForSelectedLevel && selectedLevel != .sound)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [ContinuumTheme.stormSky, ContinuumTheme.lightningGlow.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onChange(of: selectedLevel) { _, _ in
            wordIndex = 0
        }
        .onDisappear {
            referencePlayback.stop()
        }
    }

    /// Three large level buttons for sound, short words, and long words.
    private var levelPicker: some View {
        HStack(spacing: 12) {
            ForEach(FlashLevel.allCases) { level in
                Button {
                    selectedLevel = level
                } label: {
                    VStack(spacing: 6) {
                        Text(level.label)
                            .font(ContinuumTheme.kidButtonFont)
                        Text(level.subtitle)
                            .font(ContinuumTheme.kidCaptionFont)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(
                        selectedLevel == level ? ContinuumTheme.stormBlueDeep : ContinuumTheme.stormBlue
                    )
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .padding(.vertical, 8)
                    .background(
                        selectedLevel == level
                            ? ContinuumTheme.lightningYellow
                            : ContinuumTheme.lightningGlow.opacity(0.85)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selectedLevel == level
                                    ? ContinuumTheme.stormBlueDeep
                                    : ContinuumTheme.stormBlue.opacity(0.45),
                                lineWidth: selectedLevel == level ? 3 : 2
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(level.label), \(level.subtitle)")
            }
        }
    }

    /// Large lightning-themed card showing the phoneme or word for the active level.
    private func flashcard(cardHeight: CGFloat) -> some View {
        let resolvedHeight = max(cardHeight, 320)

        return ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [ContinuumTheme.lightningGlow, ContinuumTheme.lightningYellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(ContinuumTheme.stormBlueDeep, lineWidth: 3)
                )
                .shadow(color: ContinuumTheme.stormBlue.opacity(0.25), radius: 10, y: 6)

            LightningCornerDecoration()

            VStack(spacing: 18) {
                if selectedLevel != .sound {
                    practiceBadge
                }

                if selectedLevel == .sound {
                    Text(target.displayLabel)
                        .font(.system(size: resolvedHeight * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(ContinuumTheme.stormBlueDeep)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else if hasWordsForSelectedLevel {
                    highlightedWordView(
                        word: currentWord,
                        font: .system(size: wordFontSize(for: currentWord, cardHeight: resolvedHeight), weight: .bold, design: .rounded)
                    )
                    .minimumScaleFactor(0.45)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                } else {
                    Text("No words yet")
                        .font(ContinuumTheme.kidSectionHeaderFont)
                        .foregroundStyle(ContinuumTheme.stormBlue)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: resolvedHeight)
    }

    /// Shows which sound the child is practicing on word levels.
    private var practiceBadge: some View {
        Text("Practice: \(target.displayLabel)")
            .font(ContinuumTheme.kidSubheadFont.weight(.bold))
            .foregroundStyle(ContinuumTheme.stormBlueDeep)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ContinuumTheme.stormSky.opacity(0.85))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(ContinuumTheme.stormBlue.opacity(0.5), lineWidth: 1.5)
            )
    }

    /// Cycles to the next word within the current level.
    private var nextWordButton: some View {
        Button {
            wordIndex = (wordIndex + 1) % levelWords.count
        } label: {
            Label("Next word", systemImage: "arrow.right.circle.fill")
                .font(ContinuumTheme.kidButtonFont)
                .foregroundStyle(ContinuumTheme.stormBlueDeep)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                .background(ContinuumTheme.lightningGlow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ContinuumTheme.stormBlue, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    /// Plays audio for the phoneme example or the active word.
    private var hearItButton: some View {
        Button {
            if selectedLevel == .sound {
                referencePlayback.playReference(for: target.id)
            } else {
                speechService.speakWord(currentWord)
            }
        } label: {
            Label("Hear it", systemImage: "speaker.wave.2.fill")
                .font(ContinuumTheme.kidButtonFont)
                .padding()
                .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                .background(ContinuumTheme.stormBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ContinuumTheme.stormBlueDeep, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    /// Scales word text down slightly for longer words so it stays readable.
    private func wordFontSize(for word: String, cardHeight: CGFloat) -> CGFloat {
        let baseSize = cardHeight * 0.2
        switch word.count {
        case ...4: return baseSize
        case 5...6: return baseSize * 0.82
        case 7...8: return baseSize * 0.68
        default: return baseSize * 0.56
        }
    }

    /// Renders a flash word with the target sound letters emphasized.
    private func highlightedWordView(word: String, font: Font) -> some View {
        HighlightedWordText(
            word: word,
            highlights: FlashWordBank.highlights(for: target, word: word),
            font: font,
            baseColor: ContinuumTheme.stormBlueDeep,
            highlightColor: ContinuumTheme.stormBlue
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
            .fill(ContinuumTheme.stormBlue.opacity(0.55))
            .frame(width: size, height: size * 1.2)
            .rotationEffect(.degrees(rotation))
            .shadow(color: ContinuumTheme.lightningYellow.opacity(0.8), radius: 2)
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
