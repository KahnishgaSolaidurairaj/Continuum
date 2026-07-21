import SwiftUI

/// A single confetti piece emitted during a celebration burst.
private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let origin: CGPoint
    let horizontalDrift: CGFloat
    let fallDistance: CGFloat
    let rotationAmount: Double
    let size: CGSize
    let delay: Double
}

/// Short confetti burst overlay for kid-friendly celebrations.
struct ConfettiBurstView: View {
    let trigger: Int

    @State private var pieces: [ConfettiPiece] = []

    private let confettiColors: [Color] = [
        ContinuumTheme.tabPurple,
        ContinuumTheme.homeMint,
        ContinuumTheme.homePink,
        Color.orange,
        Color.yellow,
        Color.cyan
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: trigger) { _, _ in
                launchConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    /// Creates a new burst of confetti pieces inside the given bounds.
    /// - Parameter size: The area available for the animation.
    private func launchConfetti(in size: CGSize) {
        pieces = (0..<52).map { _ in
            ConfettiPiece(
                color: confettiColors.randomElement() ?? ContinuumTheme.tabPurple,
                origin: CGPoint(
                    x: CGFloat.random(in: size.width * 0.15 ... size.width * 0.85),
                    y: CGFloat.random(in: size.height * 0.05 ... size.height * 0.35)
                ),
                horizontalDrift: CGFloat.random(in: -90 ... 90),
                fallDistance: CGFloat.random(in: 140 ... 280),
                rotationAmount: Double.random(in: 220 ... 760),
                size: CGSize(
                    width: CGFloat.random(in: 7 ... 13),
                    height: CGFloat.random(in: 11 ... 20)
                ),
                delay: Double.random(in: 0 ... 0.28)
            )
        }
    }
}

/// Animates one confetti piece from burst to fade-out.
private struct ConfettiPieceView: View {
    let piece: ConfettiPiece

    @State private var progress: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(piece.color)
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(piece.rotationAmount * Double(progress)))
            .position(
                x: piece.origin.x + piece.horizontalDrift * progress,
                y: piece.origin.y + piece.fallDistance * progress
            )
            .opacity(Double(1 - progress))
            .onAppear {
                withAnimation(.easeOut(duration: 1.45).delay(piece.delay)) {
                    progress = 1
                }
            }
    }
}
