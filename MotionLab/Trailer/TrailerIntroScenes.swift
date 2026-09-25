import SwiftUI

private typealias M = TrailerMath

// MARK: - 0–6 s · Hook: the effect count tumbles in on the app's own prism digits

/// The catalog's effect count ("461") built from `TumblingPrismDigit`, the prism of the "Tumbling Prism
/// Digits" effect (`text.slot-reel`): every digit whirls face by face (the right-hand digits spin extra full
/// cycles), then the digits land left to right, each overshooting by the same ~0.3 face and rocking back.
struct TrailerHookScene: View {
    let t: Double

    var body: some View {
        let numberExit: Double = M.easeIn(M.progress(t, 5.3, 0.7))
        let subtitleExit: Double = M.easeIn(M.progress(t, 5.2, 0.6))
        ZStack {
            HookShockwave(t: t)
                .position(x: 195, y: HookLayout.numberY)
            HookPrismNumber(t: t)
                .trailerDepth(numberExit, scale: -0.9, blur: 18)
                .position(x: 195, y: HookLayout.numberY)
            Text(verbatim: TrailerCopy.current.hook.subtitle)
                .font(.system(size: TrailerCanvas.pick(30, 34), weight: .heavy))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 2.3, 0.8)))
                .frame(width: 360)
                .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 4)
                .trailerDepth(subtitleExit, scale: -0.35, blur: 14)
                .position(x: 195, y: HookLayout.subtitleY)
            HookStats(t: t)
                .position(x: 195, y: HookLayout.statsY)
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

/// Where the hook's pieces sit, per aspect, and the prism schedule.
private enum HookLayout {
    static let numberY: CGFloat = TrailerCanvas.pick(170, 236)
    static let subtitleY: CGFloat = TrailerCanvas.pick(290, 374)
    static let statsY: CGFloat = TrailerCanvas.pick(344, 440)

    /// One prism face of the real effect (52 × 68 pt); the whole number is scaled up uniformly.
    static let face = CGSize(width: 52, height: 68)
    static let spacing: CGFloat = 8

    /// The digits of the live effect count, most significant first.
    static let digits: [Int] = {
        let text: String = String(max(TrailerData.effectCount, 0))
        return text.compactMap { $0.wholeNumberValue }
    }()

    /// 2.05× in 9:16 (1.8× in 3:4), smaller when the count has more digits so it always fits 340 pt.
    static let scale: CGFloat = {
        let count: CGFloat = CGFloat(max(digits.count, 1))
        let natural: CGFloat = count * face.width + (count - 1) * spacing
        let fit: CGFloat = 340 / max(natural, 1)
        return min(TrailerCanvas.pick(1.8, 2.05), fit)
    }()

    /// Every prism starts together…
    static let rollStart: Double = 0.45
    /// …and the first one lands here, the rest `landingStagger` apart, left to right.
    static let firstLanding: Double = 1.55
    static let landingStagger: Double = 0.16
    /// Every prism overshoots its digit by this many faces, like the effect's default "settle".
    static let settle: Double = 0.3

    static var lastLanding: Double {
        firstLanding + Double(max(digits.count - 1, 0)) * landingStagger
    }

    /// Quarter turns column `index` travels: its digit plus one extra full cycle per column (the right-hand
    /// prisms whirl longest, like the effect's tens and units).
    static func travel(_ index: Int) -> Double {
        let digit: Int = index < digits.count ? digits[index] : 0
        let cycles: Int = 10 * (index + 1)
        return Double(digit + cycles)
    }

    /// Damping ratio solved from the travel, so the overshoot is always `settle` faces (as in the effect):
    /// p = e^(−πζ/√(1−ζ²)) ⇒ ζ = L/√(1+L²), L = −ln p / π.
    static func damping(_ index: Int) -> Double {
        let fraction: Double = min(settle / max(travel(index), 1), 0.3)
        let l: Double = -log(fraction) / Double.pi
        let zeta: Double = l / (1 + l * l).squareRoot()
        return min(max(zeta, 0.2), 0.99)
    }

    /// Response (undamped period) that makes the first crossing of the target fall on the column's landing:
    /// ω_d·t = π − atan(√(1−ζ²)/ζ) with ω = 2π / response.
    static func response(_ index: Int) -> Double {
        let zeta: Double = damping(index)
        let root: Double = (1 - zeta * zeta).squareRoot()
        let crossing: Double = (Double.pi - atan(root / zeta)) / (2 * Double.pi * root)
        let landing: Double = firstLanding + Double(index) * landingStagger - rollStart
        return landing / max(crossing, 0.05)
    }

    /// The prism's quarter-turn count at time `t` (0 = the "0" face).
    static func roll(_ index: Int, t: Double) -> Double {
        let value: Double = M.spring(t - rollStart, response: response(index), damping: damping(index))
        return travel(index) * value
    }
}

/// The prisms, a glow behind them and a glint once they have all landed.
private struct HookPrismNumber: View {
    let t: Double

    var body: some View {
        let appear: Double = M.easeOut(M.progress(t, 0.1, 0.45))
        let landed: Double = t - HookLayout.lastLanding
        let pop: Double = landed > 0 ? 0.06 * sin(landed * 13) * exp(-landed * 5) : 0
        let settledGlow: Double = M.progress(t, HookLayout.firstLanding - 0.3, 0.8)
        let scale: CGFloat = HookLayout.scale * CGFloat((0.9 + 0.1 * appear) * (1 + pop))
        HStack(spacing: HookLayout.spacing) {
            ForEach(HookLayout.digits.indices, id: \.self) { index in
                TumblingPrismDigit(roll: HookLayout.roll(index, t: t), face: HookLayout.face)
            }
        }
        .trailerGlint(M.progress(t, HookLayout.lastLanding + 0.35, 0.75), strength: 0.55)
        .shadow(color: Palette.ember.opacity(0.18 + 0.3 * settledGlow), radius: CGFloat(10 + 12 * settledGlow), x: 0, y: 0)
        .scaleEffect(scale)
        .opacity(appear)
    }
}

/// A ring of light when the last digit lands.
private struct HookShockwave: View {
    let t: Double

    var body: some View {
        let p: Double = M.progress(t, HookLayout.lastLanding, 0.8)
        let reach: Double = TrailerCanvas.isTall ? 360 : 320
        let size = CGFloat(140 + reach * M.easeOut(p))
        Circle()
            .strokeBorder(TrailerStyle.emberRing, lineWidth: CGFloat(3 * (1 - p) + 0.5))
            .frame(width: size, height: size)
            .opacity(p > 0 && p < 1 ? (1 - p) * 0.7 : 0)
    }
}

/// "15 大分类 · 85 个动效家族" chips springing up under the subtitle.
private struct HookStats: View {
    let t: Double

    var body: some View {
        let copy = TrailerCopy.current.hook
        HStack(spacing: 10) {
            chip(number: TrailerData.categoryCount, label: copy.categoriesLabel, index: 0)
            chip(number: TrailerData.familyCount, label: copy.familiesLabel, index: 1)
        }
        .frame(maxWidth: 370)
    }

    private func chip(number: Int, label: String, index: Int) -> some View {
        let pop: Double = M.spring(t, at: 2.9 + Double(index) * 0.16, response: 0.5, damping: 0.62)
        let exit: Double = M.easeIn(M.progress(t, 5.1 + Double(index) * 0.06, 0.5))
        return HStack(spacing: 4) {
            Text(verbatim: "\(number)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(TrailerStyle.emberText)
            Text(verbatim: label)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(TrailerGlass(shape: Capsule(), frosted: true, glow: 0.35, shadowOpacity: 0.3))
        .scaleEffect(CGFloat(0.4 + 0.6 * pop))
        .offset(y: CGFloat(1 - M.clamp(pop)) * 22)
        .opacity(M.clamp(pop * 2.5))
        .trailerDepth(exit, scale: 0.2, lift: 26, blur: 10)
    }
}

// MARK: - 6–16 s · Problem 1: "想要的动效，说不出来"

struct TrailerPainScene: View {
    let t: Double

    private struct Word {
        let text: String
        let x: CGFloat
        let y: CGFloat
        /// 0 = far (small, blurred), 1 = near.
        let depth: Double
    }

    static let start: Double = 6.0
    /// The words collapse into the centre, where the unknown tiles of the next scene are born.
    static let collapse: Double = 15.0

    /// Hand-placed spots (x, 3:4 y, 9:16 y, depth) for the first seven words; the 9:16 layout spreads them
    /// through the taller frame. Words beyond seven get deterministic spots of their own (`extraSpot`).
    private static let spots: [(x: CGFloat, classicY: CGFloat, tallY: CGFloat, depth: Double)] = [
        (96, 262, 334, 0.9),
        (288, 250, 318, 0.6),
        (112, 338, 424, 0.45),
        (274, 322, 406, 0.95),
        (200, 390, 494, 0.7),
        (94, 76, 128, 0.2),
        (298, 92, 152, 0.3),
    ]

    /// The words of `TrailerCopy.pain.words`, each on its spot.
    private static let words: [Word] = TrailerCopy.current.pain.words.enumerated().map { pair -> Word in
        let index: Int = pair.offset
        let text: String = pair.element
        if index < TrailerPainScene.spots.count {
            let spot = TrailerPainScene.spots[index]
            return Word(text: text, x: spot.x, y: TrailerCanvas.pick(spot.classicY, spot.tallY), depth: spot.depth)
        }
        return TrailerPainScene.extraSpot(index, text: text)
    }

    /// A spot for word 8 and later: alternating left/right columns, below the headline block.
    private static func extraSpot(_ index: Int, text: String) -> Word {
        let column: CGFloat = index % 2 == 0 ? 92 : 296
        let jitterX: CGFloat = CGFloat(M.hash(index, 21) - 0.5) * 40
        let top: CGFloat = TrailerCanvas.pick(230, 290)
        let bottom: CGFloat = TrailerCanvas.contentBottom - 30
        let fraction: CGFloat = CGFloat(M.hash(index, 22))
        let y: CGFloat = top + (bottom - top) * fraction
        let depth: Double = 0.3 + 0.5 * M.hash(index, 23)
        return Word(text: text, x: column + jitterX, y: y, depth: depth)
    }

    /// Delay between words popping in: 0.42 s, tighter when there are many so all land by ~11 s.
    private static let stagger: Double = {
        let count: Int = max(TrailerPainScene.words.count - 1, 1)
        let fit: Double = 3.6 / Double(count)
        return min(0.42, fit)
    }()

    var body: some View {
        let exit: Double = M.easeIn(M.progress(t, Self.collapse + 0.15, 0.6))
        let enter: Double = M.easeOut(M.progress(t, Self.start, 1.0))
        let markScale = CGFloat(0.9 + 0.1 * enter)
        ZStack {
            Text(verbatim: TrailerCopy.current.pain.backdropMark)
                .font(.system(size: TrailerCanvas.pick(300, 360), weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: TrailerCanvas.width)
                .foregroundStyle(Color.white.opacity(0.04))
                .rotationEffect(.degrees(-8 + 4 * sin(t * 0.5)))
                .scaleEffect(markScale)
                .opacity(enter * (1 - exit))
                .position(x: 205, y: TrailerLayout.painCollapse.y)
            ForEach(Self.words.indices, id: \.self) { index in
                wordView(index)
            }
            VStack(spacing: 6) {
                Text(verbatim: TrailerCopy.current.pain.titleLine1)
                    .foregroundStyle(Color.white)
                    .textRenderer(GlyphBlurRenderer(progress: M.progress(t, Self.start + 0.3, 0.8)))
                Text(verbatim: TrailerCopy.current.pain.titleLine2)
                    .foregroundStyle(TrailerStyle.emberText)
                    .textRenderer(GlyphBlurRenderer(progress: M.progress(t, Self.start + 0.8, 0.8)))
            }
            .font(.system(size: TrailerCanvas.pick(38, 42), weight: .heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .multilineTextAlignment(.center)
            .frame(width: 360)
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
            .scaleEffect(CGFloat(1.25 - 0.25 * enter))
            .trailerDepth(exit, scale: 0.12, lift: -36, blur: 14)
            .position(x: 195, y: TrailerCanvas.pick(172, 224))
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private func wordView(_ index: Int) -> some View {
        let word = Self.words[index]
        let seed = Double(index)
        let appear: Double = M.spring(t, at: Self.start + 1.3 + seed * Self.stagger, response: 0.6, damping: 0.7)
        let collapse: Double = M.easeIn(M.progress(t, Self.collapse + seed * 0.04, 0.55))
        let driftX = CGFloat(9 * sin(t * 0.55 + seed * 1.9))
        let rise = CGFloat(1 - M.clamp(appear)) * 18
        let driftY: CGFloat = CGFloat(6 * cos(t * 0.7 + seed * 2.3)) + rise
        let breathe: Double = 0.5 + 0.5 * sin(t * 1.2 + seed * 2)
        let blurValue: Double = (1 - word.depth) * 5 + 2.2 * breathe * (1 - word.depth * 0.6) + 4 * collapse
        let scaleValue: Double = (0.78 + 0.3 * word.depth) * (0.6 + 0.4 * appear) * (1 - 0.75 * collapse)
        let home = CGPoint(x: word.x + driftX, y: word.y + driftY)
        let point = M.mix(home, TrailerLayout.painCollapse, collapse)
        let opacity: Double = M.clamp(appear * 2) * (0.5 + 0.5 * word.depth) * (1 - collapse)
        return Text(verbatim: word.text)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.88))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: 200)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(TrailerGlass(shape: Capsule(), frosted: true, shadowOpacity: 0.25))
            .scaleEffect(CGFloat(scaleValue))
            .blur(radius: CGFloat(blurValue))
            .opacity(opacity)
            .position(point)
    }
}

// MARK: - 16–24 s · Problem 2: "iOS 能做到什么？不知道"

/// A grid of effects you can't make out: each tile holds a blurred, drifting shape and a question mark.
/// The tiles burst out of the point the words collapsed into, float, then gather into the app icon.
struct TrailerUnknownScene: View {
    let t: Double

    static let columns: Int = 3
    static let rows: Int = 3
    static let tileSide: CGFloat = TrailerCanvas.pick(92, 104)
    static let gap: CGFloat = TrailerCanvas.pick(10, 14)
    static let gridCenterY: CGFloat = TrailerCanvas.pick(262, 360)
    static let burst: Double = 15.75
    static let gather: Double = 23.1

    static func slotCenter(_ index: Int) -> CGPoint {
        let column = CGFloat(index % columns)
        let row = CGFloat(index / columns)
        let pitch: CGFloat = tileSide + gap
        let gridWidth: CGFloat = pitch * CGFloat(columns) - gap
        let gridHeight: CGFloat = pitch * CGFloat(rows) - gap
        let left: CGFloat = 195 - gridWidth / 2 + tileSide / 2
        let top: CGFloat = gridCenterY - gridHeight / 2 + tileSide / 2
        return CGPoint(x: left + column * pitch, y: top + row * pitch)
    }

    var body: some View {
        ZStack {
            TrailerHeadline(
                title: TrailerCopy.current.unknown.titleLine1,
                subtitle: TrailerCopy.optional(TrailerCopy.current.unknown.titleLine2),
                reveal: M.progress(t, 16.3, 0.9),
                exit: M.easeIn(M.progress(t, 22.9, 0.5))
            )
            .position(x: 195, y: TrailerLayout.headlineY)
            ForEach(0..<(Self.columns * Self.rows), id: \.self) { index in
                tile(index)
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private func tile(_ index: Int) -> some View {
        let seed = Double(index)
        let enter: Double = M.spring(t, at: Self.burst + seed * 0.07, response: 0.65, damping: 0.72)
        let settled: Double = M.clamp(enter)
        let gather: Double = M.easeIn(M.progress(t, Self.gather + (8 - seed) * 0.03, 0.7))
        let slot = Self.slotCenter(index)
        let floatX = CGFloat(3 * sin(t * 0.8 + seed * 1.7))
        let floatY = CGFloat(4 * cos(t * 0.65 + seed * 2.1))
        let home = CGPoint(x: slot.x + floatX, y: slot.y + floatY)
        let born: CGPoint = M.mix(TrailerLayout.painCollapse, home, enter)
        let point: CGPoint = M.mix(born, TrailerIntroScene.iconCenter, gather)
        let scaleValue: Double = (0.3 + 0.7 * enter) * (1 - 0.8 * gather)
        let tilt: Double = (1 - settled) * (index % 2 == 0 ? -14 : 14) + 2.5 * sin(t * 0.9 + seed)
        let blurValue: Double = (1 - settled) * 8 + gather * 6
        return TrailerUnknownTile(t: t, index: index, side: Self.tileSide)
            .scaleEffect(CGFloat(scaleValue))
            .rotationEffect(.degrees(tilt))
            .blur(radius: CGFloat(blurValue))
            .opacity(M.clamp(enter * 2.5) * (1 - M.progress(gather, 0.6, 0.4)))
            .position(point)
    }
}

/// One unknown effect: a dark glass tile with a heavily blurred, drifting gradient shape (tinted after a
/// real category) and a bobbing question mark.
private struct TrailerUnknownTile: View {
    let t: Double
    let index: Int
    let side: CGFloat

    var body: some View {
        let seed = Double(index)
        let categories = EffectCategory.allCases
        let category = categories[(index * 4 + 1) % max(categories.count, 1)]
        let colors = category.gradient
        let shape = RoundedRectangle(cornerRadius: side * 0.2, style: .continuous)
        let orbit: Double = t * (0.9 + 0.25 * M.hash(index, 31)) + seed * 1.3
        let blobX = CGFloat(cos(orbit)) * side * 0.18
        let blobY = CGFloat(sin(orbit * 1.3)) * side * 0.14
        let morph = CGFloat(0.5 + 0.5 * sin(t * 1.7 + seed))
        let bob = CGFloat(sin(t * 2.1 + seed * 0.8)) * side * 0.03
        let flicker: Double = 0.75 + 0.25 * sin(t * 3.3 + seed * 2.7)
        ZStack {
            TrailerGlass(shape: shape, shadowOpacity: 0.35)
            ZStack {
                RoundedRectangle(cornerRadius: side * (0.1 + 0.2 * morph), style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: side * 0.46, height: side * 0.46)
                    .rotationEffect(.degrees(t * 40 + seed * 30))
                    .offset(x: blobX, y: blobY)
                Circle()
                    .fill(colors.last ?? Palette.ember)
                    .frame(width: side * 0.26, height: side * 0.26)
                    .offset(x: -blobX * 1.4, y: -blobY * 1.2)
            }
            .blur(radius: side * 0.12)
            .opacity(0.75)
            .clipShape(shape)
            Text(verbatim: TrailerCopy.current.unknown.tileMark)
                .font(.system(size: side * 0.42, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.88 * flicker))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(width: side * 0.8)
                .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 2)
                .offset(y: bob)
            shape.strokeBorder(Color.white.opacity(0.1), lineWidth: 0.75)
        }
        .frame(width: side, height: side)
    }
}

// MARK: - 24–30 s · Intro: Motionary, the motion dictionary

struct TrailerIntroScene: View {
    let t: Double

    static let iconSide: CGFloat = TrailerCanvas.pick(100, 120)
    static let iconCenter = TrailerCanvas.point(195, 146, 212)
    static let exitStart: Double = 29.15

    private static let pillarColumns: Int = 2
    private static let pillarWidth: CGFloat = 158
    private static let pillarHeight: CGFloat = 36
    private static let pillarTop: CGFloat = TrailerCanvas.pick(346, 444)

    private static func pillarCenter(_ index: Int) -> CGPoint {
        let count: Int = TrailerCopy.current.intro.pillars.count
        let column: Int = index % pillarColumns
        let row: Int = index / pillarColumns
        let inRow: Int = min(pillarColumns, count - row * pillarColumns)
        let pitch: CGFloat = pillarWidth + 12
        let rowWidth: CGFloat = pitch * CGFloat(inRow) - 12
        let x: CGFloat = 195 - rowWidth / 2 + pillarWidth / 2 + CGFloat(column) * pitch
        let y: CGFloat = pillarTop + CGFloat(row) * (pillarHeight + 10)
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        let copy = TrailerCopy.current.intro
        let exit: Double = M.easeIn(M.progress(t, Self.exitStart, 0.6))
        let iconIn: Double = M.spring(t, at: 23.75, response: 0.6, damping: 0.62)
        let float = CGFloat(2 * sin((t - 25) * 1.3))
        ZStack {
            TrailerAppIcon(t: t, side: Self.iconSide, popAt: 24.0, glintAt: 24.9)
                .scaleEffect(CGFloat(0.3 + 0.7 * iconIn))
                .shadow(color: Palette.ember.opacity(0.45 * M.clamp(iconIn)), radius: 30, x: 0, y: 10)
                .opacity(M.clamp(iconIn * 2))
                .trailerDepth(exit, scale: 0.2, lift: -30, blur: 12)
                .position(x: Self.iconCenter.x, y: Self.iconCenter.y + float)
            Text(verbatim: copy.title)
                .font(.system(size: TrailerCanvas.pick(42, 48), weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 24.45, 0.8)))
                .frame(width: 360)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
                .trailerDepth(exit, scale: -0.06, lift: -24, blur: 12)
                .position(x: 195, y: TrailerCanvas.pick(248, 330))
            Text(verbatim: copy.subtitle)
                .font(.system(size: TrailerCanvas.pick(22, 24), weight: .bold))
                .tracking(2)
                .foregroundStyle(TrailerStyle.emberText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 24.8, 0.8)))
                .frame(width: 360)
                .trailerDepth(exit, scale: -0.06, lift: -20, blur: 12)
                .position(x: 195, y: TrailerCanvas.pick(290, 376))
            ForEach(copy.pillars.indices, id: \.self) { index in
                pillar(copy.pillars[index], index: index, exit: exit)
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private func pillar(_ text: String, index: Int, exit: Double) -> some View {
        let pop: Double = M.spring(t, at: 25.6 + Double(index) * 0.16, response: 0.5, damping: 0.64)
        // Each pillar lights up in turn, as the voice-over names the dictionary.
        let beat: Double = 26.4 + Double(index) * 0.35
        let lightUp: Double = M.progress(t, beat, 0.3)
        let fade: Double = 1 - M.progress(t, beat + 0.5, 0.5)
        let glow: Double = 0.2 + 0.5 * lightUp * fade
        let center = Self.pillarCenter(index)
        return HStack(spacing: 7) {
            Text(verbatim: "\(index + 1)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.onAccent)
                .frame(width: 18, height: 18)
                .background(Palette.accentFill, in: Circle())
            Text(verbatim: text)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 12)
        .frame(width: Self.pillarWidth, height: Self.pillarHeight)
        .background(TrailerGlass(shape: Capsule(), frosted: true, glow: glow, shadowOpacity: 0.3))
        .scaleEffect(CGFloat(0.5 + 0.5 * pop))
        .offset(y: CGFloat(1 - M.clamp(pop)) * 16)
        .opacity(M.clamp(pop * 2.5))
        .trailerDepth(exit, scale: 0.15, lift: 22, blur: 10)
        .position(center)
    }
}

// MARK: - App icon

/// The app icon, drawn live: an ember gradient that cools to near-black, and three cream motion
/// dots growing along a diagonal (they pop in one after another from `popAt`), with a glint at `glintAt`.
struct TrailerAppIcon: View {
    let t: Double
    let side: CGFloat
    var popAt: Double = 0
    var glintAt: Double = 0

    private static let dots: [(x: CGFloat, y: CGFloat, radius: CGFloat, opacity: Double)] = [
        (0.293, 0.605, 0.107, 0.5),
        (0.479, 0.498, 0.137, 0.78),
        (0.664, 0.391, 0.176, 1),
    ]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * 0.225, style: .continuous)
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(hex: 0xE2692A), Color(hex: 0x9C4216), Color(hex: 0x42190B), Color(hex: 0x130E0E)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(hex: 0xF5832E, opacity: 0.9), Color(hex: 0xF5832E, opacity: 0)],
                center: UnitPoint(x: 0.47, y: 0),
                startRadius: 0,
                endRadius: side * 0.75
            )
            RadialGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.35)],
                center: UnitPoint(x: 0.35, y: 0.35),
                startRadius: side * 0.3,
                endRadius: side * 0.95
            )
            ForEach(Self.dots.indices, id: \.self) { index in
                dot(index)
            }
        }
        .frame(width: side, height: side)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75))
        .trailerGlint(M.progress(t, glintAt, 0.75), strength: 0.55)
    }

    private func dot(_ index: Int) -> some View {
        let spec = Self.dots[index]
        let pop: Double = M.spring(t, at: popAt + Double(index) * 0.13, response: 0.45, damping: 0.6)
        let diameter: CGFloat = spec.radius * 2 * side
        let travel = CGFloat(1 - M.clamp(pop)) * side * 0.12
        let x: CGFloat = spec.x * side - diameter / 2 - travel
        let y: CGFloat = spec.y * side - diameter / 2 + travel
        return Circle()
            .fill(Color(hex: 0xFFF6EC).opacity(spec.opacity))
            .frame(width: diameter, height: diameter)
            .shadow(color: index == 2 ? Color(hex: 0xFFB36B).opacity(0.8) : Color.clear, radius: 10, x: 0, y: 0)
            .scaleEffect(CGFloat(max(pop, 0)))
            .offset(x: x, y: y)
    }
}
