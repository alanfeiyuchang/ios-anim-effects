import SwiftUI
import UIKit

// MARK: - Tokens

/// Motion tokens for the app shell. Everything is spring-based and settles within ~0.6 s,
/// so the chrome feels like part of the catalog without ever slowing the user down.
enum ShellMotion {
    /// Finger-down on a card or chip: quick and firm.
    static let pressDown = Animation.spring(response: 0.22, dampingFraction: 0.82)
    /// Release: a touch of overshoot so the card "lands".
    static let pressUp = Animation.spring(response: 0.42, dampingFraction: 0.62)
    /// Selection indicators (chip pill, segmented choices).
    static let selection = Animation.snappy(duration: 0.34, extraBounce: 0.06)
    /// Elements rising into place on first appearance.
    static let entrance = Animation.spring(response: 0.55, dampingFraction: 0.84)
    /// Scroll-driven reveals (sections, cards crossing into the viewport).
    static let reveal = Animation.smooth(duration: 0.42)
    /// Small celebratory pops (badges, hearts).
    static let pop = Animation.spring(response: 0.34, dampingFraction: 0.55)
    /// Rolling numbers.
    static let count = Animation.smooth(duration: 0.8)

    /// Stagger delay for the `index`-th element of a group, capped so long lists never lag.
    static func stagger(_ index: Int, step: Double = 0.045, cap: Int = 10) -> Double {
        Double(min(max(index, 0), cap)) * step
    }
}

/// Once-per-process flags so first-appearance choreography plays a single time per session.
enum SessionFlags {
    /// The Browse header (title, counters, sections) has played its reveal.
    nonisolated(unsafe) static var browseRevealed = false
}

// MARK: - Environment

private struct CardPressedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct LaunchIntroActiveKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// `true` while the enclosing `PressableCardStyle` button is held down, so a label can react
    /// (e.g. a category icon bounces on touch-down).
    var isCardPressed: Bool {
        get { self[CardPressedKey.self] }
        set { self[CardPressedKey.self] = newValue }
    }

    /// `true` while the launch intro still covers the UI; first-appearance reveals wait for it.
    var launchIntroActive: Bool {
        get { self[LaunchIntroActiveKey.self] }
        set { self[LaunchIntroActiveKey.self] = newValue }
    }
}

// MARK: - Entrance

/// Hidden → rises into place (opacity, blur, scale, offset) whenever `shown` flips to true.
/// With Reduce Motion only the opacity changes.
private struct EntranceModifier: ViewModifier {
    let shown: Bool
    let delay: Double
    let distance: CGFloat
    let scale: CGFloat
    let blur: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let hidden = !shown
        let moves = hidden && !reduceMotion
        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : ShellMotion.entrance.delay(delay)
        return content
            .opacity(hidden ? 0 : 1)
            .blur(radius: moves ? blur : 0)
            .scaleEffect(moves ? scale : 1)
            .offset(y: moves ? distance : 0)
            .animation(animation, value: shown)
    }
}

/// Plays `EntranceModifier` once, when the view first appears.
private struct AppearEntranceModifier: ViewModifier {
    let delay: Double
    let distance: CGFloat
    let scale: CGFloat
    let blur: CGFloat
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .modifier(EntranceModifier(shown: shown, delay: delay, distance: distance, scale: scale, blur: blur))
            .onAppear {
                if !shown { shown = true }
            }
    }
}

// MARK: - Scroll reveal

/// Fades, lifts and un-blurs a view as it crosses into the scroll viewport (and back out).
/// Uses an animated (not per-frame) scroll transition, so even big cards stay cheap.
private struct ScrollRevealModifier: ViewModifier {
    let delay: Double
    let distance: CGFloat
    let scale: CGFloat
    let blur: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let motion = !reduceMotion
        let distance = self.distance
        let scale = self.scale
        let blur = self.blur
        let animation: Animation = motion ? ShellMotion.reveal.delay(delay) : .easeOut(duration: 0.2)
        // Considered "in" once 15 % is visible, so sections taller than the screen still resolve.
        let configuration = ScrollTransitionConfiguration.animated(animation).threshold(.visible(0.15))
        return content.scrollTransition(configuration, axis: .vertical) { effect, phase in
            let hidden = !phase.isIdentity
            let moves = hidden && motion
            let lift: CGFloat = moves ? CGFloat(phase.value) * distance : 0
            return effect
                .opacity(hidden ? 0 : 1)
                .scaleEffect(moves ? scale : 1)
                .offset(y: lift)
                .blur(radius: moves ? blur : 0)
        }
    }
}

extension View {
    /// Rises into place when `shown` becomes true (after `delay`).
    func entrance(
        _ shown: Bool,
        delay: Double = 0,
        distance: CGFloat = 16,
        scale: CGFloat = 0.97,
        blur: CGFloat = 6
    ) -> some View {
        modifier(EntranceModifier(shown: shown, delay: delay, distance: distance, scale: scale, blur: blur))
    }

    /// Rises into place once on first appearance; `index` staggers siblings.
    func appearEntrance(
        index: Int = 0,
        delay: Double = 0,
        distance: CGFloat = 14,
        scale: CGFloat = 0.97,
        blur: CGFloat = 5
    ) -> some View {
        let total = delay + ShellMotion.stagger(index)
        return modifier(AppearEntranceModifier(delay: total, distance: distance, scale: scale, blur: blur))
    }

    /// Reveals the view as it scrolls into the viewport (vertical scroll views).
    func scrollReveal(delay: Double = 0, distance: CGFloat = 24, scale: CGFloat = 0.96, blur: CGFloat = 4) -> some View {
        modifier(ScrollRevealModifier(delay: delay, distance: distance, scale: scale, blur: blur))
    }
}

// MARK: - Insert / remove

/// Cards joining or leaving a grid (search results, favorites): scale + blur + fade.
struct CardSwapTransition: Transition {
    var reduceMotion: Bool

    func body(content: Content, phase: TransitionPhase) -> some View {
        let hidden = !phase.isIdentity
        let moves = hidden && !reduceMotion
        return content
            .opacity(hidden ? 0 : 1)
            .scaleEffect(moves ? 0.88 : 1)
            .blur(radius: moves ? 8 : 0)
    }
}

// MARK: - Ambient float

/// A gentle, endless vertical float. Inactive (static) when `active` is false.
struct FloatingModifier: ViewModifier {
    let active: Bool
    var amplitude: CGFloat = 5
    var duration: Double = 2.4

    @ViewBuilder
    func body(content: Content) -> some View {
        if active {
            let amplitude = self.amplitude
            let duration = self.duration
            content.phaseAnimator([false, true]) { view, up in
                view.offset(y: up ? -amplitude : amplitude)
            } animation: { _ in
                Animation.easeInOut(duration: duration)
            }
        } else {
            content
        }
    }
}

// MARK: - Whole-window crossfade

/// Crossfades the entire window across a change SwiftUI cannot animate itself
/// (colour-scheme switches, UI language): a snapshot of the old UI fades out over the new one.
/// Called from UI event handlers only (main thread), like `Haptics`.
enum WindowCrossfade {
    static func perform(duration: Double = 0.38, _ change: () -> Void) {
        guard let window = keyWindow, let snapshot = window.snapshotView(afterScreenUpdates: false) else {
            change()
            return
        }
        snapshot.frame = window.bounds
        snapshot.isUserInteractionEnabled = false
        window.addSubview(snapshot)
        change()
        UIView.animate(withDuration: duration, delay: 0.04, options: [.curveEaseInOut, .allowUserInteraction]) {
            snapshot.alpha = 0
        } completion: { _ in
            snapshot.removeFromSuperview()
        }
    }

    private static var keyWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        return windows.first { $0.isKeyWindow } ?? windows.first
    }
}
