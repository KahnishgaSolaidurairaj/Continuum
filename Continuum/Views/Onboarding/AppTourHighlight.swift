import SwiftUI

/// UI regions the first-launch app tour can outline and highlight.
enum AppTourAnchor: Hashable {
    case tabHome
    case tabPractice
    case tabDashboard
    case homeWarmUp
    case homePracticeSounds
    case practicePrioritySection
    case practiceManageButton
    case practiceActivities

    /// Outline style used when spotlighting this anchor.
    var outlineStyle: AppTourOutlineStyle {
        switch self {
        case .homeWarmUp, .homePracticeSounds, .practiceManageButton:
            return .capsule
        case .tabHome, .tabPractice, .tabDashboard:
            return .rounded(16)
        case .practicePrioritySection, .practiceActivities:
            return .rounded(22)
        }
    }
}

/// Corner style for a tour spotlight outline.
enum AppTourOutlineStyle {
    case capsule
    case rounded(CGFloat)

    func cornerRadius(for rect: CGRect) -> CGFloat {
        switch self {
        case .capsule:
            return min(rect.width, rect.height) / 2
        case .rounded(let radius):
            return radius
        }
    }
}

/// Collects global frames for tour highlight anchors.
struct AppTourHighlightFramePreferenceKey: PreferenceKey {
    static var defaultValue: [AppTourAnchor: CGRect] = [:]

    static func reduce(value: inout [AppTourAnchor: CGRect], nextValue: () -> [AppTourAnchor: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Marks a view as a highlight target for the app preview tour.
    func appTourHighlight(_ anchor: AppTourAnchor) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: AppTourHighlightFramePreferenceKey.self,
                    value: [anchor: geometry.frame(in: .global)]
                )
            }
        }
    }
}

/// Dimmed overlay with cut-out spotlight holes and pulsing glowing outlines.
struct AppTourSpotlightOverlay: View {
    let highlightFrames: [AppTourAnchor: CGRect]
    let activeAnchors: [AppTourAnchor]

    private var spotlightItems: [(anchor: AppTourAnchor, rect: CGRect)] {
        activeAnchors.compactMap { anchor in
            guard let rect = highlightFrames[anchor], rect.width > 1, rect.height > 1 else { return nil }
            return (anchor, rect)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let overlayOrigin = geometry.frame(in: .global).origin
            let localItems = spotlightItems.map { item in
                (
                    anchor: item.anchor,
                    rect: CGRect(
                        x: item.rect.minX - overlayOrigin.x,
                        y: item.rect.minY - overlayOrigin.y,
                        width: item.rect.width,
                        height: item.rect.height
                    )
                )
            }

            ZStack {
                SpotlightMaskShape(
                    screenRect: CGRect(origin: .zero, size: geometry.size),
                    spotlightItems: localItems
                )
                .fill(Color.black.opacity(0.66), style: FillStyle(eoFill: true))

                ForEach(localItems, id: \.anchor) { item in
                    PulsingSpotlightRing(
                        rect: item.rect,
                        style: item.anchor.outlineStyle
                    )
                    .id(item.anchor)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Animated purple pulse rings that draw attention to a spotlight target.
private struct PulsingSpotlightRing: View {
    let rect: CGRect
    let style: AppTourOutlineStyle

    @State private var animatePulse = false

    private let ringPadding: CGFloat = 6

    private var paddedRect: CGRect {
        rect.insetBy(dx: -ringPadding, dy: -ringPadding)
    }

    var body: some View {
        let padded = paddedRect
        let cornerRadius = style.cornerRadius(for: padded)
        let pulseScale = animatePulse ? 1.14 : 1.0
        let pulseOpacity = animatePulse ? 0.0 : 0.85

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.98), lineWidth: 3.5)
                .frame(width: padded.width, height: padded.height)
                .position(x: padded.midX, y: padded.midY)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(ContinuumTheme.tabPurple, lineWidth: 4)
                .frame(width: padded.width, height: padded.height)
                .position(x: padded.midX, y: padded.midY)
                .shadow(color: ContinuumTheme.tabPurple.opacity(0.85), radius: 16)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(ContinuumTheme.homeMint, lineWidth: 3)
                .frame(
                    width: padded.width * pulseScale,
                    height: padded.height * pulseScale
                )
                .position(x: padded.midX, y: padded.midY)
                .opacity(pulseOpacity)

            Image(systemName: "hand.tap.fill")
                .font(.system(size: tapIconSize(for: padded), weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                .position(x: padded.maxX - 14, y: padded.minY + 14)
                .opacity(showTapHint ? 1 : 0)
        }
        .onAppear {
            animatePulse = false
            withAnimation(.easeOut(duration: 1.15).repeatForever(autoreverses: false)) {
                animatePulse = true
            }
        }
    }

    private var showTapHint: Bool {
        paddedRect.width > 90 && paddedRect.height > 44
    }

    private func tapIconSize(for rect: CGRect) -> CGFloat {
        min(24, max(16, rect.height * 0.28))
    }
}

/// Full-screen mask with rounded cut-outs for spotlight regions.
private struct SpotlightMaskShape: Shape {
    let screenRect: CGRect
    let spotlightItems: [(anchor: AppTourAnchor, rect: CGRect)]

    private let ringPadding: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path(screenRect)

        for item in spotlightItems {
            let expanded = item.rect.insetBy(dx: -ringPadding, dy: -ringPadding)
            let cornerRadius = item.anchor.outlineStyle.cornerRadius(for: expanded)
            path.addPath(
                Path(
                    roundedRect: expanded,
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
        }

        return path
    }
}
