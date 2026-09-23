import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    /// `Color(hex: 0x6E7BFF)`
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// Shared palette so every demo feels like part of one family.
enum Palette {
    static let indigo = Color(hex: 0x6E7BFF)
    static let violet = Color(hex: 0xA46BFF)
    static let pink = Color(hex: 0xFF5FA2)
    static let coral = Color(hex: 0xFF7A5C)
    static let amber = Color(hex: 0xFFC247)
    static let mint = Color(hex: 0x21D4A8)
    static let sky = Color(hex: 0x3AC4FF)
    static let blue = Color(hex: 0x4F7CFF)
    static let green = Color(hex: 0x34C77B)
    static let red = Color(hex: 0xFF4D5E)

    /// Primary brand gradient (indigo → violet).
    static let primary = LinearGradient(colors: [indigo, violet], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let sunset = LinearGradient(colors: [amber, coral, pink], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let ocean = LinearGradient(colors: [sky, blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let aurora = LinearGradient(colors: [mint, sky, violet], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let spectrum: [Color] = [indigo, violet, pink, coral, amber, mint, sky]

    /// Surface colours that adapt to light/dark.
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let elevated = Color(uiColor: .tertiarySystemBackground)
    static let stroke = Color.primary.opacity(0.08)
}

// MARK: - Autoplay

private struct DemoAutoplayKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Master switch for `.autoplay`. The app shell turns it off for grid thumbnails when
    /// Reduce Motion is on, when "Animate previews" is disabled, or when a card scrolls away.
    var demoAutoplayEnabled: Bool {
        get { self[DemoAutoplayKey.self] }
        set { self[DemoAutoplayKey.self] = newValue }
    }
}

private struct AutoplayModifier: ViewModifier {
    let active: Bool
    let interval: Double
    let initialDelay: Double
    let action: () -> Void
    @Environment(\.demoAutoplayEnabled) private var enabled

    private struct Key: Hashable {
        let active: Bool
        let interval: Double
    }

    func body(content: Content) -> some View {
        // Keyed on the interval too, so interval sliders take effect immediately.
        content.task(id: Key(active: active && enabled, interval: interval)) {
            guard active && enabled else { return }
            try? await Task.sleep(for: .seconds(initialDelay))
            while !Task.isCancelled {
                // Autoplay only runs in previews: never buzz the user for simulated taps.
                Haptics.isMuted = true
                action()
                Haptics.isMuted = false
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
}

extension View {
    /// Repeatedly calls `action` every `interval` seconds while `active` is true.
    /// Use it so tap-driven demos animate on their own inside grid previews:
    /// `.autoplay(ctx.isPreview, every: 1.6) { toggle() }`
    func autoplay(_ active: Bool, every interval: Double = 1.8, delay: Double = 0.6, _ action: @escaping () -> Void) -> some View {
        modifier(AutoplayModifier(active: active, interval: interval, initialDelay: delay, action: action))
    }

    /// Standard floating card look used by many demos.
    func demoCard(cornerRadius: CGFloat = 22) -> some View {
        self
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}

// MARK: - Haptics

enum Haptics {
    /// Set while an autoplay (preview) action runs so simulated interactions stay silent.
    nonisolated(unsafe) static var isMuted = false

    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard !isMuted else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        guard !isMuted else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard !isMuted else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        guard !isMuted else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Small reusable pieces

/// A caption hint shown at the bottom of a demo stage, hidden in previews.
struct DemoHint: View {
    let text: LocalizedText
    let ctx: DemoContext

    var body: some View {
        if !ctx.isPreview {
            Text(text, ctx.language)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

/// Placeholder "content lines" used in skeletons, cards and lists.
struct PlaceholderLines: View {
    var count: Int = 3
    var color: Color = .primary.opacity(0.12)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(height: 10)
                    .frame(maxWidth: index == count - 1 ? 120 : .infinity, alignment: .leading)
            }
        }
    }
}

/// Clamp helper.
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

/// Rubber-band resistance like UIScrollView's overscroll.
func rubberBand(_ offset: CGFloat, limit: CGFloat, coefficient: CGFloat = 0.55) -> CGFloat {
    guard offset != 0 else { return 0 }
    let sign: CGFloat = offset < 0 ? -1 : 1
    let x = abs(offset)
    return sign * (1 - (1 / ((x * coefficient / limit) + 1))) * limit
}
