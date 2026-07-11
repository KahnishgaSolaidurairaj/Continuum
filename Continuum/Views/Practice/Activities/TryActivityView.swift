import SwiftUI

/// Try activity: example of someone saying the target sound/word.
struct TryActivityView: View {
    let target: PracticeTarget

    var body: some View {
        VStack(spacing: 20) {
            Text("See an example")
                .font(ContinuumTheme.kidSectionHeaderFont)

            demoFrame

            Text("Watch how to say \(target.displayLabel)")
                .font(ContinuumTheme.kidSubheadFont)

            HighlightedWordText(
                word: target.exampleWord,
                highlights: target.englishSound.highlights(for: target.exampleWord),
                font: ContinuumTheme.kidSectionHeaderFont,
                baseColor: .primary,
                highlightColor: ContinuumTheme.tabPurple
            )

            Text(target.linkedPhoneme.instruction)
                .font(ContinuumTheme.kidBodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ContinuumTheme.practiceCream)
    }

    private var demoFrame: some View {
        ZStack {
            AsyncImage(url: PronunciationDemoPlaceholder.portraitURL(for: target)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    SpeakingDemoFallbackView(target: target)
                default:
                    SpeakingDemoFallbackView(target: target)
                        .overlay { ProgressView().tint(.white) }
                }
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                speechBubble
                    .padding(.bottom, 20)
            }

            VStack {
                HStack {
                    demoBadge
                    Spacer()
                }
                Spacer()
            }
            .padding(12)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .padding(16)
                }
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ContinuumTheme.cardBorder, lineWidth: 2)
        )
    }

    private var speechBubble: some View {
        Text(target.exampleWord)
            .font(.title.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(radius: 4)
    }

    private var demoBadge: some View {
        Text("Demo")
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.45))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

/// Offline fallback that reads like a person saying one word.
struct SpeakingDemoFallbackView: View {
    let target: PracticeTarget

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.55, blue: 0.85), Color(red: 0.35, green: 0.42, blue: 0.72)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.96, green: 0.87, blue: 0.78))
                        .frame(width: 120, height: 120)

                    Ellipse()
                        .fill(.white)
                        .frame(width: 36, height: 22)
                        .offset(y: 18)

                    HStack(spacing: 18) {
                        Circle().fill(.black.opacity(0.75)).frame(width: 8, height: 8)
                        Circle().fill(.black.opacity(0.75)).frame(width: 8, height: 8)
                    }
                    .offset(y: -8)
                }

                Text("“\(target.exampleWord)”")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
    }
}
