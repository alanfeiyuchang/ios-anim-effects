import SwiftUI

// MARK: - Per-glyph blur reveal

/// A title whose glyphs come into focus one after another (blur + fade + small lift) when
/// `revealed` turns true. Shown fully and statically with Reduce Motion.
struct GlyphRevealTitle: View {
    let text: String
    let revealed: Bool
    var font: Font = .largeTitle.weight(.bold)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let progress: Double = (revealed || reduceMotion) ? 1 : 0
        Text(verbatim: text)
            .font(font)
            .textRenderer(GlyphBlurRenderer(progress: progress))
            .animation(reduceMotion ? nil : Animation.easeOut(duration: 0.85), value: revealed)
    }
}

/// Draws each glyph with its own staggered opacity / blur / offset window of `progress`.
struct GlyphBlurRenderer: TextRenderer {
    var progress: Double
    var blur: Double = 9
    /// Fraction of the whole timeline each glyph takes to resolve.
    var window: Double = 0.45

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var slices: [Text.Layout.RunSlice] = []
        for line in layout {
            for run in line {
                for slice in run {
                    slices.append(slice)
                }
            }
        }
        let count = slices.count
        let w = min(max(window, 0.05), 1)
        for (index, slice) in slices.enumerated() {
            let start: Double = count > 1 ? Double(index) / Double(count - 1) * (1 - w) : 0
            let local = min(max((progress - start) / w, 0), 1)
            let eased = 1 - pow(1 - local, 3)
            var copy = context
            copy.opacity = eased
            if eased < 1 && blur > 0 {
                copy.addFilter(.blur(radius: CGFloat((1 - eased) * blur)))
            }
            copy.translateBy(x: 0, y: CGFloat((1 - eased) * 8))
            copy.draw(slice)
        }
    }
}

// MARK: - Living mesh hero

/// Slowly drifting 3×3 mesh gradient in the brand's ember hues, used behind the Browse header:
/// warm amber/peach light on the grouped page in light mode, glowing embers over near-black ink in dark.
/// Ticks at 30 fps and freezes completely whenever `isAnimating` is false
/// (off-screen, another tab, app inactive, Reduce Motion).
struct HeroMeshBackground: View {
    let isAnimating: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = colorScheme == .dark ? Self.darkColors : Self.lightColors
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isAnimating)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            MeshGradient(width: 3, height: 3, points: Self.points(at: t), colors: colors)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static let lightColors: [Color] = [
        Color(hex: 0xFFC79E), Color(hex: 0xFFDDBB), Color(hex: 0xFFBFA8),
        Color(hex: 0xFFE6CF), Color(hex: 0xFFF0E2), Color(hex: 0xFFD6C4),
        Color(hex: 0xF2F2F7), Color(hex: 0xF4F1F0), Color(hex: 0xF2F2F7),
    ]

    /// The bottom row matches the dark page ink (#0B0B0D), so the fade below the header is seamless.
    private static let darkColors: [Color] = [
        Color(hex: 0x6A2A08), Color(hex: 0x8C3A0C), Color(hex: 0x4E1A12),
        Color(hex: 0x2E1206), Color(hex: 0x5C260A), Color(hex: 0x24100E),
        Color(hex: 0x0B0B0D), Color(hex: 0x0D0B0C), Color(hex: 0x0B0B0D),
    ]

    /// Corners stay pinned; edge midpoints glide and the centre wanders on slow,
    /// incommensurate sine paths (periods of roughly 11–17 s), so it never visibly loops.
    private static func points(at time: Double) -> [SIMD2<Float>] {
        let t = time.truncatingRemainder(dividingBy: 10_000)
        let a = 0.11
        let topX = 0.5 + a * sin(t * 0.47)
        let leftY = 0.5 + a * cos(t * 0.39 + 1.2)
        let rightY = 0.5 + a * sin(t * 0.43 + 2.4)
        let bottomX = 0.5 + a * cos(t * 0.53 + 0.6)
        let centerX = 0.5 + a * 1.2 * sin(t * 0.57)
        let centerY = 0.48 + a * cos(t * 0.41)
        return [
            point(0, 0), point(topX, 0), point(1, 0),
            point(0, leftY), point(centerX, centerY), point(1, rightY),
            point(0, 1), point(bottomX, 1), point(1, 1),
        ]
    }

    private static func point(_ x: Double, _ y: Double) -> SIMD2<Float> {
        SIMD2<Float>(Float(x), Float(y))
    }
}

// MARK: - Like burst

private struct BurstFrame {
    var progress: Double = 0
    var opacity: Double = 0
}

/// A ring plus a spray of dots that fires every time `trigger` changes.
struct BurstParticles: View {
    let trigger: Int
    var radius: CGFloat = 20
    var colors: [Color] = [Palette.pink, Palette.amber, Palette.ember]

    var body: some View {
        KeyframeAnimator(initialValue: BurstFrame(), trigger: trigger) { frame in
            BurstLayer(progress: frame.progress, radius: radius, colors: colors)
                .opacity(frame.opacity)
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                MoveKeyframe(0)
                CubicKeyframe(1, duration: 0.55)
            }
            KeyframeTrack(\.opacity) {
                MoveKeyframe(1)
                LinearKeyframe(1, duration: 0.3)
                LinearKeyframe(0, duration: 0.25)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct BurstLayer: View {
    let progress: Double
    let radius: CGFloat
    let colors: [Color]
    private let count = 8

    var body: some View {
        let p = CGFloat(progress)
        let ringSize: CGFloat = 8 + radius * 2 * p
        let ringWidth: CGFloat = max(0.5, 3 * (1 - p))
        ZStack {
            Circle()
                .strokeBorder(colors.first ?? Palette.pink, lineWidth: ringWidth)
                .frame(width: ringSize, height: ringSize)
                .opacity(Double(1 - p))
            ForEach(0..<count, id: \.self) { index in
                particle(index, p: p)
            }
        }
    }

    private func particle(_ index: Int, p: CGFloat) -> some View {
        let angle = Double(index) / Double(count) * 2 * Double.pi - Double.pi / 2
        let reach: CGFloat = radius * (0.55 + 0.45 * p) * p
        let x = CGFloat(cos(angle)) * reach
        let y = CGFloat(sin(angle)) * reach
        let size: CGFloat = 1.5 + 3.5 * (1 - p)
        let color = colors.isEmpty ? Palette.pink : colors[index % colors.count]
        return Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: x, y: y)
    }
}

/// Toolbar heart: replace-morphs between outline and fill, bounces and bursts when favorited.
struct HeartBurstIcon: View {
    let isFavorite: Bool
    /// Increment when the effect becomes a favorite.
    let burst: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
            .foregroundStyle(isFavorite ? Palette.pink : Palette.accent)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.bounce, value: burst)
            .background {
                if !reduceMotion {
                    BurstParticles(trigger: burst, radius: 17)
                }
            }
    }
}

// MARK: - Shimmer CTA

/// Primary capsule call-to-action with a soft light sweep every couple of seconds.
struct ShimmerCapsuleButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(verbatim: title)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.bold))
                        .accessibilityHidden(true)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(Palette.accentFill, in: Capsule())
            .overlay {
                if !reduceMotion {
                    ShimmerSweep()
                        .clipShape(Capsule())
                }
            }
            .shadow(color: Palette.accentGlow, radius: 10, y: 5)
            .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
    }
}

/// A diagonal band of light that sweeps across its container, pauses, and repeats.
struct ShimmerSweep: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let band = max(width * 0.45, 40)
            LinearGradient(
                colors: [Color.white.opacity(0), Color.white.opacity(0.42), Color.white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: band)
            .keyframeAnimator(initialValue: CGFloat(0), repeating: true) { content, x in
                content.offset(x: -band + (width + band) * x)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(CGFloat(0), duration: 1.4)
                    CubicKeyframe(CGFloat(1), duration: 0.9)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
