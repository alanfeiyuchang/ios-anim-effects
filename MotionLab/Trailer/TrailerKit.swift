import SwiftUI

// MARK: - Canvas

/// Output aspect of the trailer, chosen with `-ML_trailerAspect 9x16|3x4` (default 9:16).
enum TrailerAspect: String {
    /// 390 × 693⅓ pt → 1080 × 1920 (Xiaohongshu full-screen video; recommended).
    case portrait = "9x16"
    /// 390 × 520 pt → 1080 × 1440 (Xiaohongshu feed 3:4).
    case classic = "3x4"

    static let current: TrailerAspect = TrailerAspect(rawValue: CatalogTools.trailerAspect) ?? .portrait
}

/// The trailer's fixed design canvas, 390 pt wide and 9:16 or 3:4 tall, scaled to the screen width by
/// `TrailerView`. Everything is placed in these coordinates with `.position`.
enum TrailerCanvas {
    static let aspect: TrailerAspect = TrailerAspect.current
    static let isTall: Bool = aspect == .portrait
    static let width: CGFloat = 390
    /// 9:16 → 693.33 pt (exactly 16/9 of the width, so the crop maps 1:1 onto 1080 × 1920); 3:4 → 520 pt.
    static let height: CGFloat = isTall ? width * 16 / 9 : width * 4 / 3
    /// Bottom 18 % kept free of text and UI: subtitles are added in post (125 pt / 94 pt).
    static let captionBand: CGFloat = (height * 0.18).rounded()
    /// Lowest y any text or UI may reach (568 pt in 9:16, 426 pt in 3:4).
    static let contentBottom: CGFloat = height - captionBand
    /// In 9:16, the central 3:4 window (what the Xiaohongshu feed cover shows): y 86.7 … 606.7.
    static let coverTop: CGFloat = (height - width * 4 / 3) / 2

    /// A layout value per aspect: `tall` in 9:16, `classic` in 3:4.
    static func pick(_ classic: CGFloat, _ tall: CGFloat) -> CGFloat { isTall ? tall : classic }

    /// A point per aspect (x is shared).
    static func point(_ x: CGFloat, _ classicY: CGFloat, _ tallY: CGFloat) -> CGPoint {
        CGPoint(x: x, y: isTall ? tallY : classicY)
    }
    /// Page ink of the dark app shell; also the letterbox around the canvas.
    static let ink = Color(hex: 0x0B0B0D)
    /// Length of the cut (the last frame holds after it).
    static let duration: Double = 60
    /// A white slate fills the screen for this long before t = 0. `scripts/record-trailer.sh`
    /// detects where the white ends and trims the recording there, so the cut starts exactly at t = 0.
    static let leadIn: Double = 2.5
}

// MARK: - Math

/// Pure timing helpers: every scene is a function of the trailer clock `t` (seconds).
enum TrailerMath {
    static func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }

    /// 0 → 1 while `t` runs through `start ... start + duration`.
    static func progress(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        guard duration > 0 else { return t >= start ? 1 : 0 }
        return clamp((t - start) / duration)
    }

    static func mix(_ a: Double, _ b: Double, _ p: Double) -> Double { a + (b - a) * p }

    static func mix(_ a: CGFloat, _ b: CGFloat, _ p: Double) -> CGFloat { a + (b - a) * CGFloat(p) }

    static func mix(_ a: CGPoint, _ b: CGPoint, _ p: Double) -> CGPoint {
        CGPoint(x: mix(a.x, b.x, p), y: mix(a.y, b.y, p))
    }

    static func easeOut(_ p: Double) -> Double {
        let q = 1 - clamp(p)
        return 1 - q * q * q
    }

    static func easeIn(_ p: Double) -> Double {
        let q = clamp(p)
        return q * q * q
    }

    static func easeInOut(_ p: Double) -> Double {
        let q = clamp(p)
        if q < 0.5 { return 4 * q * q * q }
        let r = -2 * q + 2
        return 1 - r * r * r / 2
    }

    /// Step response of a damped spring (0 → 1, may overshoot) `elapsed` seconds after it starts.
    /// `response` is the undamped period, `damping` the damping ratio (like `.spring(response:dampingFraction:)`).
    static func spring(_ elapsed: Double, response: Double = 0.55, damping: Double = 0.75) -> Double {
        guard elapsed > 0 else { return 0 }
        let omega: Double = 2 * Double.pi / max(response, 0.05)
        let zeta: Double = min(max(damping, 0.05), 0.995)
        let damped: Double = omega * (1 - zeta * zeta).squareRoot()
        let decay: Double = exp(-zeta * omega * elapsed)
        let wave: Double = cos(damped * elapsed) + (zeta * omega / damped) * sin(damped * elapsed)
        return 1 - decay * wave
    }

    /// A spring that starts at `start` on the trailer clock.
    static func spring(_ t: Double, at start: Double, response: Double = 0.55, damping: Double = 0.75) -> Double {
        spring(t - start, response: response, damping: damping)
    }

    /// Deterministic pseudo-random number in 0 ..< 1.
    static func hash(_ index: Int, _ salt: Int = 0) -> Double {
        let x: Double = sin(Double(index) * 12.9898 + Double(salt) * 78.233) * 43_758.5453
        return x - x.rounded(.down)
    }

    /// A short decaying shake (-1 ... 1), used to "buzz" the phone on every haptic tap.
    static func buzz(_ elapsed: Double) -> Double {
        guard elapsed > 0, elapsed < 0.35 else { return 0 }
        return sin(elapsed * 95) * exp(-elapsed * 13)
    }
}

// MARK: - Style

enum TrailerStyle {
    /// Large ember type (numbers, accent lines).
    static let emberText = LinearGradient(
        colors: [Color(hex: 0xFFB36B), Color(hex: 0xFF7A1A), Color(hex: 0xFF5E3A)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Glossy dark glass card fill (top-lit).
    static let glassFill = LinearGradient(
        colors: [Color(hex: 0x222228), Color(hex: 0x131316)],
        startPoint: .top,
        endPoint: .bottom
    )
    /// Hairline rim light, bright along the top edge.
    static let rim = LinearGradient(
        stops: [
            Gradient.Stop(color: Color.white.opacity(0.26), location: 0),
            Gradient.Stop(color: Color.white.opacity(0.08), location: 0.45),
            Gradient.Stop(color: Color.white.opacity(0.04), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let emberRing = LinearGradient(
        colors: [Color(hex: 0xFFC08A), Palette.ember, Palette.emberHot],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// Glossy dark glass surface with a hairline rim and a soft shadow; `frosted` adds a live material
/// under the tint, `glow` an ember rim.
struct TrailerGlass<S: InsettableShape>: View {
    let shape: S
    var frosted = false
    var glow: Double = 0
    var shadowOpacity: Double = 0.45

    var body: some View {
        ZStack {
            if frosted {
                shape.fill(.ultraThinMaterial)
            }
            shape
                .fill(TrailerStyle.glassFill)
                .opacity(frosted ? 0.6 : 1)
            shape.strokeBorder(TrailerStyle.rim, lineWidth: 0.75)
            shape
                .strokeBorder(Palette.accentFill, lineWidth: 1.2)
                .opacity(glow)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(shadowOpacity), radius: 18, x: 0, y: 10)
    }
}

// MARK: - Depth & light

extension View {
    /// Shared exit/entrance styling: `hidden` 0 → 1 fades, blurs, scales (`scale` < 0 grows) and lifts the view.
    func trailerDepth(_ hidden: Double, scale: CGFloat = 0.1, lift: CGFloat = 0, blur: CGFloat = 10) -> some View {
        let h = CGFloat(TrailerMath.clamp(hidden))
        return self
            .scaleEffect(1 - scale * h)
            .offset(y: lift * h)
            .blur(radius: blur * h)
            .opacity(Double(1 - h))
    }

    /// A diagonal light sweep across the view's own shape while `progress` runs 0 → 1.
    func trailerGlint(_ progress: Double, strength: Double = 0.6) -> some View {
        overlay {
            TrailerGlintBand(progress: progress, strength: strength)
                .blendMode(.plusLighter)
                .mask { self }
        }
    }
}

/// A soft white band travelling from left to right (outside the view at 0 and 1).
struct TrailerGlintBand: View {
    let progress: Double
    var strength: Double = 0.6

    var body: some View {
        let p = TrailerMath.clamp(progress)
        let x = CGFloat(-0.75 + 2.0 * p)
        LinearGradient(
            colors: [Color.white.opacity(0), Color.white.opacity(strength), Color.white.opacity(0)],
            startPoint: UnitPoint(x: x, y: 0),
            endPoint: UnitPoint(x: x + 0.5, y: 1)
        )
        .opacity(p > 0 && p < 1 ? 1 : 0)
        .allowsHitTesting(false)
    }
}

// MARK: - Kinetic headline

/// Big two-line headline: glyphs resolve from blur one after another (`GlyphBlurRenderer`), and the
/// block drifts up, grows slightly and blurs away on exit.
struct TrailerHeadline: View {
    let title: String
    var subtitle: String? = nil
    /// Which line carries the ember gradient (the other is white).
    var accentOnTitle = false
    var titleSize: CGFloat = TrailerCanvas.pick(32, 36)
    var subtitleSize: CGFloat = TrailerCanvas.pick(20, 22)
    let reveal: Double
    var exit: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: title)
                .font(.system(size: titleSize, weight: .heavy))
                .foregroundStyle(accentOnTitle ? AnyShapeStyle(TrailerStyle.emberText) : AnyShapeStyle(Color.white))
                .textRenderer(GlyphBlurRenderer(progress: TrailerMath.clamp(reveal * 1.2)))
            if let subtitle {
                Text(verbatim: subtitle)
                    .font(.system(size: subtitleSize, weight: .bold))
                    .foregroundStyle(accentOnTitle ? AnyShapeStyle(Color.white.opacity(0.9)) : AnyShapeStyle(TrailerStyle.emberText))
                    .textRenderer(GlyphBlurRenderer(progress: TrailerMath.clamp(reveal * 1.35 - 0.35)))
            }
        }
        // Authored copy (TrailerCopy) can be longer than the defaults: shrink to fit one line, never overflow.
        .lineLimit(1)
        .minimumScaleFactor(0.45)
        .multilineTextAlignment(.center)
        .frame(width: 360)
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        .trailerDepth(exit, scale: -0.08, lift: -18, blur: 12)
    }
}

/// Reveals a long paragraph line by line (fade + rise, no blur, so it stays cheap for long text).
struct TrailerLineReveal: TextRenderer {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let count = max(layout.count, 1)
        for (index, line) in layout.enumerated() {
            let start = Double(index) / Double(count) * 0.6
            let local = TrailerMath.easeOut(TrailerMath.clamp((progress - start) / 0.4))
            var copy = context
            copy.opacity = local
            copy.translateBy(x: 0, y: CGFloat((1 - local) * 10))
            copy.draw(line)
        }
    }
}

// MARK: - Backdrop

/// Near-black ink with a drifting ember mesh glow (after `HeroMeshBackground`), a focus glow that
/// follows the action, slow ember motes, and a gentle darkening over the caption band.
struct TrailerBackdrop: View {
    let t: Double

    var body: some View {
        let focus = Self.focus(t)
        let glow = Self.glow(t)
        ZStack {
            TrailerCanvas.ink
            MeshGradient(width: 3, height: 3, points: Self.points(t, focus: focus), colors: Self.colors)
            RadialGradient(
                colors: [Palette.ember.opacity(0.26 * glow), Palette.emberHot.opacity(0.08 * glow), Color.clear],
                center: UnitPoint(x: focus.x / TrailerCanvas.width, y: focus.y / TrailerCanvas.height),
                startRadius: 0,
                endRadius: TrailerCanvas.pick(250, 320)
            )
            TrailerMotes(t: t)
            LinearGradient(
                colors: [TrailerCanvas.ink.opacity(0), TrailerCanvas.ink.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: TrailerCanvas.pick(170, 230))
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
        .allowsHitTesting(false)
    }

    private static let colors: [Color] = [
        Color(hex: 0x3A1606), Color(hex: 0x6A2A08), Color(hex: 0x2A0F0A),
        Color(hex: 0x170C09), Color(hex: 0x5A2208), Color(hex: 0x120B0B),
        Color(hex: 0x0B0B0D), Color(hex: 0x140C0A), Color(hex: 0x0B0B0D),
    ]

    /// Where the light gathers: behind whatever the scene is about (3:4 y, 9:16 y).
    private static let focusKeys: [(time: Double, x: Double, y: Double)] = {
        let keys: [(Double, Double, Double)] = [
            (0, 190, 262), (5, 210, 290), (10.5, 250, 330), (12, 150, 230), (20.5, 280, 360),
            (36, 250, 350), (44, 240, 350), (52, 250, 350), (57, 190, 270), (60, 190, 270),
        ]
        return keys.map { key in (time: key.0, x: 195, y: TrailerCanvas.isTall ? key.2 : key.1) }
    }()

    static func focus(_ t: Double) -> CGPoint {
        let keys = focusKeys
        guard let first = keys.first, let last = keys.last else { return CGPoint(x: 195, y: 220) }
        if t <= first.time { return CGPoint(x: first.x, y: first.y) }
        if t >= last.time { return CGPoint(x: last.x, y: last.y) }
        for index in 1..<keys.count where t < keys[index].time {
            let a = keys[index - 1]
            let b = keys[index]
            let p = TrailerMath.easeInOut((t - a.time) / (b.time - a.time))
            return CGPoint(x: TrailerMath.mix(a.x, b.x, p), y: TrailerMath.mix(a.y, b.y, p))
        }
        return CGPoint(x: last.x, y: last.y)
    }

    /// Glow intensity: a swell as the number lands and a bloom behind the closing icon.
    private static func glow(_ t: Double) -> Double {
        let base = 0.75 + 0.25 * sin(t * 0.8)
        let hook = 0.6 * TrailerMath.progress(t, 1.2, 1.6) * (1 - TrailerMath.progress(t, 4.6, 1.0))
        let end = 0.8 * TrailerMath.easeOut(TrailerMath.progress(t, 57.2, 1.4))
        return base + hook + end
    }

    private static func points(_ t: Double, focus: CGPoint) -> [SIMD2<Float>] {
        let a = 0.09
        let fx = Double(focus.x / TrailerCanvas.width)
        let fy = Double(focus.y / TrailerCanvas.height)
        let topX = 0.5 + a * sin(t * 0.47)
        let leftY = 0.45 + a * cos(t * 0.39 + 1.2)
        let rightY = 0.45 + a * sin(t * 0.43 + 2.4)
        let bottomX = 0.5 + a * cos(t * 0.53 + 0.6)
        let centerX = min(max(fx + 0.06 * sin(t * 0.57), 0.2), 0.8)
        let centerY = min(max(fy + 0.05 * cos(t * 0.41), 0.2), 0.75)
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

/// Slowly rising ember specks for depth (one Canvas layer).
private struct TrailerMotes: View {
    let t: Double
    private let count = 34

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let depth = TrailerMath.hash(index, 7)
                let speed = 6 + 16 * depth
                let span = Double(size.height) + 40
                let rawY = TrailerMath.hash(index, 8) * span - t * speed
                let y = rawY - (rawY / span).rounded(.down) * span - 20
                let x = TrailerMath.hash(index, 9) * Double(size.width) + 10 * sin(t * 0.6 + Double(index))
                let radius = 0.6 + 1.6 * depth
                let twinkle = 0.5 + 0.5 * sin(t * (1.2 + depth) + Double(index) * 1.7)
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.opacity = (0.12 + 0.3 * depth) * twinkle
                context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xFFA05A)))
            }
        }
    }
}
