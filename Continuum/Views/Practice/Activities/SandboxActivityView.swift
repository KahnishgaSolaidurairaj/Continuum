import SwiftUI

/// Sandbox activity: trace the spelling with a guided finger path.
struct SandboxActivityView: View {
    let target: PracticeTarget

    @State private var tracedPoints: [CGPoint] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Trace with your finger")
                .font(.title2.weight(.bold))

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ContinuumTheme.cardBorder, lineWidth: 2)
                    )

                Text(target.spelling.uppercased())
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.15))

                Circle()
                    .fill(.yellow.opacity(0.9))
                    .frame(width: 24, height: 24)
                    .offset(x: -80, y: -60)

                Canvas { context, size in
                    guard tracedPoints.count > 1 else { return }
                    var path = Path()
                    path.addLines(tracedPoints)
                    context.stroke(path, with: .color(.blue), lineWidth: 4)
                }
            }
            .frame(height: 320)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        tracedPoints.append(value.location)
                    }
            )

            Text("Follow the glowing light along the letter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Clear") {
                tracedPoints.removeAll()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ContinuumTheme.practiceCream)
    }
}
