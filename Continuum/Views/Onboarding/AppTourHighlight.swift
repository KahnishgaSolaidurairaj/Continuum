import SwiftUI

/// UI regions the first-launch app tour can outline and highlight.
enum AppTourAnchor: Hashable {
    case tabHome
    case tabPractice
    case tabDashboard
    case homeWarmUp
    case homePracticeSounds
    case homeParentLock
    case practicePrioritySection
    case practiceManageButton
    case practiceActivities

    /// Accent color for the pulsing outline on this anchor.
    var pulseAccent: Color {
        switch self {
        case .homeWarmUp, .homePracticeSounds, .practiceManageButton, .homeParentLock:
            return ContinuumTheme.testMagenta
        default:
            return ContinuumTheme.tabPurple
        }
    }

    /// Outline style used when spotlighting this anchor.
    var outlineStyle: AppTourOutlineStyle {
        switch self {
        case .homeWarmUp, .homePracticeSounds, .practiceManageButton:
            return .capsule
        case .tabHome, .tabPractice, .tabDashboard:
            return .rounded(16)
        case .practicePrioritySection, .practiceActivities, .homeParentLock:
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
                Color.black.opacity(0.66)
                    .mask {
                        Rectangle()
                            .fill(Color.white)
                            .overlay {
                                ForEach(localItems, id: \.anchor) { item in
                                    spotlightCutout(for: item)
                                        .blendMode(.destinationOut)
                                }
                            }
                            .compositingGroup()
                    }

                ForEach(localItems, id: \.anchor) { item in
                    PulsingSpotlightRing(
                        rect: item.rect,
                        style: item.anchor.outlineStyle,
                        accent: item.anchor.pulseAccent
                    )
                    .id(item.anchor)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private let ringPadding: CGFloat = 6

    /// Builds one cutout hole for the dimmed overlay mask.
    @ViewBuilder
    private func spotlightCutout(for item: (anchor: AppTourAnchor, rect: CGRect)) -> some View {
        let expanded = item.rect.insetBy(dx: -ringPadding, dy: -ringPadding)

        switch item.anchor.outlineStyle {
        case .capsule:
            Capsule()
                .frame(width: expanded.width, height: expanded.height)
                .position(x: expanded.midX, y: expanded.midY)
        case .rounded(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .frame(width: expanded.width, height: expanded.height)
                .position(x: expanded.midX, y: expanded.midY)
        }
    }
}

/// Animated outline that grows and settles, matching the priority-sounds emphasis.
private struct PulsingSpotlightRing: View {
    let rect: CGRect
    let style: AppTourOutlineStyle
    let accent: Color

    @State private var pulseScale: CGFloat = 1
    @State private var pulseRingOpacity = 0.0
    @State private var pulseShadowOpacity = 0.0

    private let ringPadding: CGFloat = 6

    private var paddedRect: CGRect {
        rect.insetBy(dx: -ringPadding, dy: -ringPadding)
    }

    var body: some View {
        let padded = paddedRect
        let cornerRadius = style.cornerRadius(for: padded)

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.98), lineWidth: 3.5)
                .frame(width: padded.width, height: padded.height)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(accent, lineWidth: 4)
                .frame(width: padded.width, height: padded.height)
                .shadow(color: accent.opacity(0.85), radius: 16)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(accent.opacity(pulseRingOpacity), lineWidth: 4)
                .frame(width: padded.width, height: padded.height)
                .shadow(
                    color: accent.opacity(pulseShadowOpacity),
                    radius: 18,
                    y: 0
                )

            Image(systemName: "hand.tap.fill")
                .font(.system(size: tapIconSize(for: padded), weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 8)
                .padding(.trailing, 8)
                .opacity(showTapHint ? 1 : 0)
        }
        .frame(width: padded.width, height: padded.height)
        .scaleEffect(pulseScale)
        .position(x: padded.midX, y: padded.midY)
        .onAppear {
            runOutlinePulseAnimation()
        }
    }

    private var showTapHint: Bool {
        paddedRect.width > 90 && paddedRect.height > 44
    }

    private func tapIconSize(for rect: CGRect) -> CGFloat {
        min(24, max(16, rect.height * 0.28))
    }

    /// Repeats a subtle grow-and-settle outline pulse on the spotlight target.
    private func runOutlinePulseAnimation() {
        Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.55)) {
                    pulseScale = 1.025
                    pulseRingOpacity = 0.85
                    pulseShadowOpacity = 0.35
                }
                try? await Task.sleep(for: .milliseconds(550))
                withAnimation(.easeInOut(duration: 0.55)) {
                    pulseScale = 1.0
                    pulseRingOpacity = 0
                    pulseShadowOpacity = 0
                }
                try? await Task.sleep(for: .milliseconds(550))
            }
        }
    }
}

