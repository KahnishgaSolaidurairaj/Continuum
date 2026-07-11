import SwiftUI

/// Sandbox activity: trace the phoneme symbol with a guided finger path on a beach-themed canvas.
struct SandboxActivityView: View {
    let target: PracticeTarget

    @State private var tracedPoints: [CGPoint] = []
    @State private var selectedPenThickness: PenThickness = .medium

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Text("Trace with your finger")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .multilineTextAlignment(.center)

                tracingBox(availableHeight: geometry.size.height * 0.68)

                penThicknessPicker
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [ContinuumTheme.beachCoral, ContinuumTheme.beachSunYellow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    tracedPoints.removeAll()
                } label: {
                    Text("Clear")
                        .font(ContinuumTheme.kidButtonFont)
                        .foregroundStyle(ContinuumTheme.tabPurple)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.95), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear drawing")
            }
        }
    }

    /// Builds the main sand tracing canvas sized to fill most of the screen.
    private func tracingBox(availableHeight: CGFloat) -> some View {
        GeometryReader { boxGeometry in
            let borderPadding: CGFloat = 46
            let sandSize = CGSize(
                width: boxGeometry.size.width - (borderPadding * 2),
                height: boxGeometry.size.height - (borderPadding * 2)
            )

            ZStack {
                SeashellSandboxBorder()

                sandDrawingArea(size: sandSize)
                    .padding(borderPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: max(availableHeight, 380))
    }

    /// Sand canvas where touch coordinates match drawn stroke coordinates.
    private func sandDrawingArea(size: CGSize) -> some View {
        let letterSize = min(size.width, size.height) * 0.78

        return ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(ContinuumTheme.sandYellow)
                .overlay {
                    SandTextureBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            Text(target.symbol)
                .font(.system(size: letterSize, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.14))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(letterSize * 0.12)

            GrainyTracedPath(points: tracedPoints, lineWidth: selectedPenThickness.lineWidth)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    tracedPoints.append(value.location)
                }
        )
    }

    /// Kid-friendly pen thickness selector with large tap targets.
    private var penThicknessPicker: some View {
        VStack(spacing: 10) {
            Text("Pen size")
                .font(ContinuumTheme.kidSectionHeaderFont)

            HStack(spacing: 16) {
                ForEach(PenThickness.allCases) { thickness in
                    Button {
                        selectedPenThickness = thickness
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(ContinuumTheme.beachCoralPen)
                                .frame(width: thickness.displaySize, height: thickness.displaySize)

                            Text(thickness.label)
                                .font(ContinuumTheme.kidCaptionFont.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedPenThickness == thickness ? .white : .white.opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedPenThickness == thickness
                                        ? ContinuumTheme.tabPurple
                                        : ContinuumTheme.cardBorder.opacity(0.2),
                                    lineWidth: selectedPenThickness == thickness ? 3 : 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(thickness.label) pen")
                    .accessibilityAddTraits(selectedPenThickness == thickness ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - Pen Thickness

private enum PenThickness: CaseIterable, Identifiable {
    case thin
    case medium
    case thick
    case extraThick

    var id: Self { self }

    var label: String {
        switch self {
        case .thin: return "Thin"
        case .medium: return "Medium"
        case .thick: return "Thick"
        case .extraThick: return "Big"
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .thin: return 5
        case .medium: return 10
        case .thick: return 18
        case .extraThick: return 28
        }
    }

    var displaySize: CGFloat {
        switch self {
        case .thin: return 10
        case .medium: return 16
        case .thick: return 24
        case .extraThick: return 34
        }
    }
}

// MARK: - Sand Texture

/// Renders a lightly grainy sand surface for the tracing box.
private struct SandTextureBackground: View {
    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / 5)
            let rows = Int(size.height / 5)

            for row in 0..<rows {
                for column in 0..<columns {
                    let seed = (row * 997) + (column * 131)
                    guard seed % 100 > 28 else { continue }

                    let offsetX = CGFloat(seed % 5)
                    let offsetY = CGFloat((seed * 3) % 5)
                    let grainSize = CGFloat(1 + seed % 3)
                    let opacity = 0.1 + Double(seed % 10) / 100.0
                    let tint = seed % 2 == 0 ? ContinuumTheme.sandGrain : Color.orange.opacity(0.45)

                    let rect = CGRect(
                        x: CGFloat(column) * 5 + offsetX,
                        y: CGFloat(row) * 5 + offsetY,
                        width: grainSize,
                        height: grainSize
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Grainy Pencil Stroke

/// Draws traced paths with layered, speckled strokes that resemble pencil on sand.
private struct GrainyTracedPath: View {
    let points: [CGPoint]
    let lineWidth: CGFloat

    var body: some View {
        Canvas { context, _ in
            guard !points.isEmpty else { return }

            if points.count == 1, let point = points.first {
                let dotRect = CGRect(
                    x: point.x - lineWidth / 2,
                    y: point.y - lineWidth / 2,
                    width: lineWidth,
                    height: lineWidth
                )
                context.fill(Path(ellipseIn: dotRect), with: .color(ContinuumTheme.beachCoralPen))
                return
            }

            var path = Path()
            path.addLines(points)

            let offsets: [(CGFloat, CGFloat, Double)] = [
                (0, 0, 0.95),
                (-1.1, 0.7, 0.35),
                (0.9, -0.6, 0.3),
                (-0.5, -0.9, 0.25),
                (0.6, 0.8, 0.22)
            ]

            for (offsetX, offsetY, opacity) in offsets {
                var strokeContext = context
                strokeContext.translateBy(x: offsetX, y: offsetY)
                strokeContext.stroke(
                    path,
                    with: .color(ContinuumTheme.beachCoralPen.opacity(opacity)),
                    style: StrokeStyle(
                        lineWidth: lineWidth * (offsetX == 0 ? 1 : 0.45),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }

            for (index, point) in points.enumerated() where index % 3 == 0 {
                let speckleSeed = (index * 17) % 11
                let speckleSize = CGFloat(1 + speckleSeed % 2)
                let rect = CGRect(
                    x: point.x - speckleSize,
                    y: point.y - speckleSize,
                    width: speckleSize * 2,
                    height: speckleSize * 2
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(ContinuumTheme.beachCoralPen.opacity(0.18 + Double(speckleSeed) / 30.0))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Seashell Sandbox Border

/// Rings the tracing sandbox with seashells to form a beach-themed border.
private struct SeashellSandboxBorder: View {
    private let spacing: CGFloat = 64

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(shellPlacements(in: geometry.size).enumerated()), id: \.offset) { _, placement in
                shellView(size: placement.size, rotation: placement.rotation)
                    .position(placement.point)
            }
        }
        .allowsHitTesting(false)
    }

    /// Describes one seashell's position and styling along the sandbox edge.
    private struct ShellPlacement {
        let point: CGPoint
        let size: CGFloat
        let rotation: Double
    }

    /// Calculates evenly spaced shell positions around the sandbox perimeter.
    private func shellPlacements(in size: CGSize) -> [ShellPlacement] {
        var placements: [ShellPlacement] = []
        let edgeInset: CGFloat = 22

        var horizontalPosition = edgeInset
        while horizontalPosition <= size.width - edgeInset {
            placements.append(
                ShellPlacement(
                    point: CGPoint(x: horizontalPosition, y: edgeInset),
                    size: shellSize(for: placements.count),
                    rotation: -18 + Double(placements.count % 4) * 10
                )
            )
            horizontalPosition += spacing
        }

        horizontalPosition = edgeInset
        while horizontalPosition <= size.width - edgeInset {
            placements.append(
                ShellPlacement(
                    point: CGPoint(x: horizontalPosition, y: size.height - edgeInset),
                    size: shellSize(for: placements.count),
                    rotation: 168 + Double(placements.count % 4) * 10
                )
            )
            horizontalPosition += spacing
        }

        var verticalPosition = edgeInset + spacing * 0.75
        while verticalPosition <= size.height - edgeInset - spacing * 0.75 {
            placements.append(
                ShellPlacement(
                    point: CGPoint(x: edgeInset, y: verticalPosition),
                    size: shellSize(for: placements.count) * 0.9,
                    rotation: -82 + Double(placements.count % 3) * 14
                )
            )
            placements.append(
                ShellPlacement(
                    point: CGPoint(x: size.width - edgeInset, y: verticalPosition),
                    size: shellSize(for: placements.count) * 0.9,
                    rotation: 82 + Double(placements.count % 3) * 14
                )
            )
            verticalPosition += spacing
        }

        return placements
    }

    private func shellSize(for index: Int) -> CGFloat {
        34 + CGFloat(index % 4) * 6
    }

    /// Renders a single decorative seashell.
    private func shellView(size: CGFloat, rotation: Double) -> some View {
        SeashellShape()
            .fill(
                LinearGradient(
                    colors: [ContinuumTheme.shellCream, ContinuumTheme.shellPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                SeashellShape()
                    .stroke(ContinuumTheme.sandGrain.opacity(0.45), lineWidth: 1.5)
            }
            .frame(width: size, height: size * 0.82)
            .rotationEffect(.degrees(rotation))
            .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
    }
}

/// Simple fan-shaped seashell used as beach decoration.
private struct SeashellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY * 0.92)

        path.move(to: center)
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.35),
            control: CGPoint(x: rect.minX, y: rect.maxY * 0.45)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.35),
            control: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY)
        )
        path.addQuadCurve(
            to: center,
            control: CGPoint(x: rect.maxX, y: rect.maxY * 0.45)
        )
        path.closeSubpath()

        let ridgeCount = 5
        for ridgeIndex in 1..<ridgeCount {
            let progress = CGFloat(ridgeIndex) / CGFloat(ridgeCount)
            path.move(to: center)
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + rect.width * (0.12 + progress * 0.12), y: rect.minY + rect.height * (0.2 + progress * 0.2)),
                control: CGPoint(x: rect.minX + rect.width * progress * 0.2, y: rect.maxY * (0.55 - progress * 0.1))
            )
        }

        return path
    }
}
