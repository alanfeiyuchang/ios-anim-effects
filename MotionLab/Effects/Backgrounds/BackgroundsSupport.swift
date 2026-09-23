import SwiftUI

// Shared helpers for the Backgrounds category. Names are prefixed to stay unique across the app.

/// Deterministic pseudo-random helpers: every particle derives its look and motion from its index,
/// so demos need no per-particle state and stay perfectly stable across frames.
enum BackgroundMath {
    /// Fractional part, always in 0..<1 (also for negative inputs).
    static func fract(_ x: Double) -> Double {
        x - x.rounded(.down)
    }

    /// Stable pseudo-random value in 0..<1 for an index and a salt.
    static func rand(_ index: Int, _ salt: Int = 0) -> Double {
        let seed = sin(Double(index) * 12.9898 + Double(salt) * 78.233 + 0.5) * 43758.5453
        return fract(seed)
    }

    /// Same as `rand`, as a CGFloat.
    static func unit(_ index: Int, _ salt: Int = 0) -> CGFloat {
        CGFloat(rand(index, salt))
    }

    static let tau: Double = .pi * 2
}

/// Frame-rate budget for continuously animating demos (backgrounds, shaders, physics).
/// Grid previews are small and many run side by side, so they tick at 30 fps; the detail stage runs at full rate.
enum MotionFrameRate {
    static func interval(preview: Bool) -> Double? {
        preview ? 1.0 / 30.0 : nil
    }
}

/// Accumulates speed-scaled time, so changing a speed parameter (or easing it) never makes a loop jump.
final class BackgroundClock {
    private var last: Double?
    private(set) var phase: Double
    /// Real seconds elapsed during the last `advance` call (clamped).
    private(set) var delta: Double = 0

    init(start: Double = 100) {
        phase = start
    }

    @discardableResult
    func advance(to now: Double, speed: Double) -> Double {
        if let last = last {
            delta = min(max(now - last, 0), 1.0 / 20.0)
        } else {
            delta = 0
        }
        last = now
        phase += delta * speed
        return phase
    }

    /// Frame-rate independent exponential smoothing factor for the last frame.
    func follow(rate: Double) -> Double {
        1 - exp(-delta * rate)
    }
}

/// A small sample headline laid over a background so it reads in context.
struct BackgroundSampleTitle: View {
    let title: LocalizedText
    let subtitle: LocalizedText
    let language: AppLanguage
    var color: Color = .white
    var size: CGFloat = 30

    var body: some View {
        VStack(spacing: 6) {
            Text(title, language)
                .font(.system(size: size, weight: .bold, design: .rounded))
            Text(subtitle, language)
                .font(.subheadline.weight(.medium))
                .opacity(0.78)
        }
        .foregroundStyle(color)
        .multilineTextAlignment(.center)
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
    }
}

extension View {
    /// Bottom hint that stays legible on the (mostly dark) background demos. Hidden in previews.
    func backgroundsHint(_ text: LocalizedText, _ ctx: DemoContext) -> some View {
        overlay(alignment: .bottom) {
            DemoHint(text: text, ctx: ctx)
                .padding(.bottom, 14)
                .environment(\.colorScheme, .dark)
                .allowsHitTesting(false)
        }
    }
}
