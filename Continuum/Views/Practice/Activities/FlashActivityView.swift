import SwiftUI

/// Flash activity: spelling plus tap-to-hear pronunciation.
struct FlashActivityView: View {
    let target: PracticeTarget

    private let speechService = SpeechSynthesisService()

    var body: some View {
        VStack(spacing: 28) {
            Text("Flashcard")
                .font(ContinuumTheme.kidSectionHeaderFont)

            VStack(spacing: 16) {
                Text(target.spelling)
                    .font(.system(size: 72, weight: .bold, design: .rounded))

                Text(target.exampleWord)
                    .font(ContinuumTheme.kidBodyFont)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            .background(.white.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ContinuumTheme.cardBorder, lineWidth: 2)
            )

            Button {
                speechService.speak(target)
            } label: {
                Label("Hear it", systemImage: "speaker.wave.2.fill")
                    .font(ContinuumTheme.kidButtonFont)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                    .background(ContinuumTheme.tabPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ContinuumTheme.practiceCream)
    }
}
