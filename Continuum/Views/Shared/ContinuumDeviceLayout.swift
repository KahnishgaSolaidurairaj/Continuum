import SwiftUI

/// Device layout profile used to keep iPad visuals unchanged while adapting iPhone.
enum ContinuumDeviceLayout {
    case phone
    case pad

    /// Whether the current layout targets iPhone.
    var isPhone: Bool {
        self == .phone
    }

    /// Returns the phone value on iPhone and the pad value on iPad.
    /// - Parameters:
    ///   - pad: Value used on iPad.
    ///   - phone: Value used on iPhone.
    /// - Returns: The value for the active layout profile.
    func scaled(_ pad: CGFloat, phone: CGFloat) -> CGFloat {
        isPhone ? phone : pad
    }

    /// Builds a rounded system font sized for the active layout profile.
    /// - Parameters:
    ///   - padSize: Font size used on iPad.
    ///   - phoneSize: Font size used on iPhone.
    ///   - weight: Font weight shared by both profiles.
    /// - Returns: A rounded system font for the active device.
    func font(_ padSize: CGFloat, phoneSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: scaled(padSize, phone: phoneSize), weight: weight, design: .rounded)
    }
}

private struct ContinuumDeviceLayoutKey: EnvironmentKey {
    static let defaultValue: ContinuumDeviceLayout = .pad
}

extension EnvironmentValues {
    /// Active Continuum layout profile derived from the current device idiom.
    var continuumDeviceLayout: ContinuumDeviceLayout {
        get { self[ContinuumDeviceLayoutKey.self] }
        set { self[ContinuumDeviceLayoutKey.self] = newValue }
    }
}

private struct PhoneAdaptiveTypographyModifier: ViewModifier {
    @Environment(\.continuumDeviceLayout) private var layout
    let lineLimit: Int

    func body(content: Content) -> some View {
        if layout.isPhone {
            content
                .lineLimit(lineLimit)
                .minimumScaleFactor(0.85)
        } else {
            content
        }
    }
}

extension View {
    /// Applies tighter heading scaling on iPhone to prevent text collisions.
    /// - Parameter lineLimit: Maximum number of lines before scaling.
    /// - Returns: A view with phone-only typography safeguards.
    func phoneAdaptiveTypography(lineLimit: Int = 2) -> some View {
        modifier(PhoneAdaptiveTypographyModifier(lineLimit: lineLimit))
    }
}
