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

    // MARK: App-shell tokens (demos keep using the colours above)

    /// Brand accent for small tinted text, icons and buttons. Darker than `indigo` in light mode
    /// (#4B57E0, 5.6:1 on white) and lighter in dark mode (#8A94FF), from the AccentColor asset.
    static let accent = Color("AccentColor")
    /// White text on this gradient stays above 4.5:1 (selected chips, primary buttons).
    static let primaryStrong = LinearGradient(
        colors: [Color(hex: 0x4B57E0), Color(hex: 0x7A45D6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Green that carries white text (e.g. the "Copied" state).
    static let successStrong = Color(hex: 0x17803F)
    /// Violet for small text such as the "iOS 26" badge.
    static let violetText = Color.adaptive(light: 0x7A45D6, dark: 0xC4A0FF)

    /// Grouped page background (behind cards).
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    /// Cards and sections sitting on the page.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    /// Chips and pills placed directly on the page background.
    static let chipOnPage = Color(uiColor: .secondarySystemGroupedBackground)
    /// Chips and tags placed inside a card (`cardBackground`).
    static let chipOnCard = Color(uiColor: .tertiarySystemGroupedBackground)
    /// Demo stage fill: a slightly recessed well in light mode so it separates from both the
    /// grouped page and white cards; the regular secondary surface in dark mode.
    static let stage = Color.adaptive(light: 0xEBEBF1, dark: 0x1C1C1E)
}

/// Corner radii shared by the app shell.
enum CornerRadius {
    static let chip: CGFloat = 14
    static let thumbnail: CGFloat = 18
    static let compactThumbnail: CGFloat = 16
    static let section: CGFloat = 22
    static let card: CGFloat = 24
    static let featuredThumbnail: CGFloat = 22
    static let featuredCard: CGFloat = 28
    static let stage: CGFloat = 30
}

extension Color {
    /// A colour that resolves to `light` or `dark` with the current appearance.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

// MARK: - Frame rate

/// Frame-rate budget for continuously animating demos (backgrounds, shaders, physics).
/// Grid previews are small and many run side by side, so they tick at 30 fps; the detail stage runs at full rate.
enum MotionFrameRate {
    static func interval(preview: Bool) -> Double? {
        preview ? 1.0 / 30.0 : nil
    }
}

// MARK: - Autoplay

private struct DemoAutoplayKey: EnvironmentKey {
    static let defaultValue = true
}

private struct DemoIntroPlayKey: EnvironmentKey {
    static let defaultValue = false
}

private struct DemoSyncEpochKey: EnvironmentKey {
    static let defaultValue: Date? = nil
}

extension EnvironmentValues {
    /// Master switch for `.autoplay`. The app shell turns it off for grid thumbnails when
    /// Reduce Motion is on, when "Animate previews" is disabled, or when a card scrolls away.
    var demoAutoplayEnabled: Bool {
        get { self[DemoAutoplayKey.self] }
        set { self[DemoAutoplayKey.self] = newValue }
    }

    /// Set by the detail stage: an inactive `.autoplay` fires its action once shortly after the
    /// demo appears, so tap-driven demos show what they do on arrival (skipped with Reduce Motion).
    var demoIntroPlay: Bool {
        get { self[DemoIntroPlayKey.self] }
        set { self[DemoIntroPlayKey.self] = newValue }
    }

    /// Shared clock for side-by-side previews (the family page's Compare mode). When set, every
    /// autoplay loop fires on the grid `epoch + delay + k × interval`, so variations that tick at the
    /// same interval play in lockstep no matter when their card was created.
    var demoSyncEpoch: Date? {
        get { self[DemoSyncEpochKey.self] }
        set { self[DemoSyncEpochKey.self] = newValue }
    }
}

private struct AutoplayModifier: ViewModifier {
    let active: Bool
    let interval: Double
    let initialDelay: Double
    /// Whether this autoplay also performs the one-shot arrival play on the detail stage.
    let intro: Bool
    let action: () -> Void
    @Environment(\.demoAutoplayEnabled) private var enabled
    @Environment(\.demoIntroPlay) private var introPlay
    @Environment(\.demoSyncEpoch) private var syncEpoch
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Mode: Hashable {
        case idle
        case intro
        case loop(interval: Double, epoch: Date?)
    }

    private var mode: Mode {
        if active { return enabled ? .loop(interval: interval, epoch: syncEpoch) : .idle }
        return intro && introPlay && !reduceMotion ? .intro : .idle
    }

    /// Wait before the first loop tick: `initialDelay`, or the time to the next shared-clock tick.
    private static func firstWait(delay: Double, interval: Double, epoch: Date?) -> Double {
        guard let epoch, interval > 0 else { return delay }
        let elapsed = Date().timeIntervalSince(epoch)
        if elapsed <= delay { return delay - elapsed }
        let phase = (elapsed - delay).truncatingRemainder(dividingBy: interval)
        return phase < 0.001 ? 0 : interval - phase
    }

    func body(content: Content) -> some View {
        // Keyed on the interval too, so interval sliders take effect immediately.
        content.task(id: mode) {
            switch mode {
            case .idle:
                return
            case .intro:
                // Detail stage: play once on arrival. The stage is rebuilt on Reset, which replays it.
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { return }
                Self.silently(action)
            case .loop(let interval, let epoch):
                let wait = Self.firstWait(delay: initialDelay, interval: interval, epoch: epoch)
                if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                while !Task.isCancelled {
                    Self.silently(action)
                    try? await Task.sleep(for: .seconds(interval))
                }
            }
        }
    }

    /// Simulated taps never buzz the user.
    private static func silently(_ action: () -> Void) {
        Haptics.isMuted = true
        action()
        Haptics.isMuted = false
    }
}

extension View {
    /// Repeatedly calls `action` every `interval` seconds while `active` is true.
    /// Use it so tap-driven demos animate on their own inside grid previews:
    /// `.autoplay(ctx.isPreview, every: 1.6) { toggle() }`
    ///
    /// On the detail stage an inactive autoplay plays `action` once, 0.9 s after arrival (see
    /// `demoIntroPlay`). Pass `intro: false` when the demo already plays itself in `onAppear`,
    /// otherwise that entrance is interrupted by a second play.
    func autoplay(
        _ active: Bool,
        every interval: Double = 1.8,
        delay: Double = 0.6,
        intro: Bool = true,
        _ action: @escaping () -> Void
    ) -> some View {
        modifier(AutoplayModifier(active: active, interval: interval, initialDelay: delay, intro: intro, action: action))
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
    /// While a detail page plays its arrival (intro play and demos that start themselves), feedback
    /// stays silent: haptics should answer a finger, never an animation nobody touched.
    nonisolated(unsafe) static var quietUntil = Date.distantPast

    /// Silences feedback for `seconds` from now (the detail page calls this on arrival and on Reset).
    static func quiet(for seconds: TimeInterval) {
        quietUntil = Date().addingTimeInterval(seconds)
    }

    private static var isSilent: Bool { isMuted || Date() < quietUntil }

    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard !isSilent else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        guard !isSilent else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard !isSilent else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        guard !isSilent else { return }
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
