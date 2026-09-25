import SwiftUI

private typealias M = TrailerMath

// MARK: - 0–5 s · Hook: dots swarm into a counting "461"

struct TrailerHookScene: View {
    let t: Double

    var body: some View {
        let numberExit = M.easeIn(M.progress(t, 4.85, 0.75))
        let subtitleExit = M.easeIn(M.progress(t, 4.75, 0.6))
        ZStack {
            HookSwarm(t: t)
            HookShockwave(t: t)
                .position(x: 195, y: HookLayout.numberY)
            HookNumber(t: t)
                .trailerDepth(numberExit, scale: -0.9, blur: 18)
                .position(x: 195, y: HookLayout.numberY)
            Text(verbatim: TrailerCopy.current.hook.subtitle)
                .font(.system(size: TrailerCanvas.pick(30, 34), weight: .heavy))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 2.75, 0.8)))
                .frame(width: 360)
                .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 4)
                .trailerDepth(subtitleExit, scale: -0.35, blur: 14)
                .position(x: 195, y: TrailerCanvas.pick(284, 364))
            HookStats(t: t)
                .position(x: 195, y: TrailerCanvas.pick(340, 432))
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }
}

/// Where the hook's number sits, per aspect.
private enum HookLayout {
    static let numberY: CGFloat = TrailerCanvas.pick(184, 250)
    static let numberSize: CGFloat = TrailerCanvas.pick(124, 140)
    /// Half-extent of the cloud the dots are absorbed into.
    static let targetSpread = CGSize(width: TrailerCanvas.pick(210, 236), height: TrailerCanvas.pick(84, 96))
}

/// ~150 ember dots scattered through the frame; one after another they curve into the number and
/// are absorbed, each one feeding the counter.
private struct HookSwarm: View {
    let t: Double

    static let count = 150
    static let firstLaunch: Double = 0.45
    static let launchSpread: Double = 1.8
    static let travel: Double = 0.55
    static var lastArrival: Double { firstLaunch + launchSpread + travel }

    /// Fraction of dots already absorbed (closed form of the launch schedule below).
    static func arrivedFraction(_ t: Double) -> Double {
        let x = M.clamp((t - firstLaunch - travel) / launchSpread)
        guard x > 0 else { return 0 }
        return M.clamp(pow(x, 1 / 0.85))
    }

    private static func launch(_ index: Int) -> Double {
        firstLaunch + launchSpread * pow(Double(index) / Double(count - 1), 0.85)
    }

    private static let colors: [Color] = [
        Palette.ember, Palette.emberHot, Color(hex: 0xFFB36B), Color(hex: 0xFFE2C4),
    ]

    var body: some View {
        Canvas { context, _ in
            for index in 0..<Self.count {
                let u = M.progress(t, Self.launch(index), Self.travel)
                guard u < 1 else { continue }
                let depth = M.hash(index, 3)
                let fadeIn = M.progress(t, M.hash(index, 4) * 0.4, 0.5)
                let alpha = (0.35 + 0.6 * depth) * fadeIn * (1 - M.progress(u, 0.82, 0.18))
                guard alpha > 0.01 else { continue }
                let size: Double = 1.2 + 2.8 * depth
                let shrink: Double = 1 - 0.55 * u * u
                let radius = CGFloat(size * shrink)
                let head = Self.position(index, t: t)
                let tail = Self.position(index, t: t - 0.04)
                let color = Self.colors[index % Self.colors.count]
                context.opacity = alpha
                var trail = Path()
                trail.move(to: tail)
                trail.addLine(to: head)
                context.stroke(trail, with: .color(color), style: StrokeStyle(lineWidth: radius * 2, lineCap: .round))
                context.fill(Path(ellipseIn: CGRect(x: head.x - radius, y: head.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
            }
        }
        .frame(width: TrailerCanvas.width, height: TrailerCanvas.height)
    }

    private static func position(_ index: Int, t: Double) -> CGPoint {
        let depth = M.hash(index, 3)
        let homeX = 18 + M.hash(index, 1) * 354 + sin(t * 0.9 + Double(index)) * 6 * (0.5 + depth)
        let spreadY: Double = Double(TrailerCanvas.contentBottom) - 26
        let homeY: Double = 16 + M.hash(index, 2) * spreadY + cos(t * 0.7 + Double(index) * 1.3) * 6
        let targetX: Double = 195 + (M.hash(index, 5) - 0.5) * Double(HookLayout.targetSpread.width)
        let targetY: Double = Double(HookLayout.numberY) + (M.hash(index, 6) - 0.5) * Double(HookLayout.targetSpread.height)
        let u = M.progress(t, launch(index), travel)
        let e = pow(u, 2.2)
        // Curved path: the control point is pushed sideways so the swarm swirls in.
        let midX = (homeX + targetX) / 2
        let midY = (homeY + targetY) / 2
        let dx = targetX - homeX
        let dy = targetY - homeY
        let swirl = (M.hash(index, 10) - 0.5) * 1.1
        let controlX = midX - dy * swirl
        let controlY = midY + dx * swirl
        let a = (1 - e) * (1 - e)
        let b = 2 * (1 - e) * e
        let c = e * e
        return CGPoint(
            x: a * homeX + b * controlX + c * targetX,
            y: a * homeY + b * controlY + c * targetY
        )
    }
}

/// The counter: `numericText` rolls up as dots are absorbed, then the number pops and a glint sweeps it.
private struct HookNumber: View {
    let t: Double

    var body: some View {
        let fraction = HookSwarm.arrivedFraction(t)
        let steps: Double = 28
        let quantized = (fraction * steps).rounded(.down) / steps
        let value = Int((Double(TrailerData.effectCount) * quantized).rounded())
        let appear = M.easeOut(M.progress(t, 0.7, 0.5))
        let landing = t - HookSwarm.lastArrival
        let pop: Double = landing > 0 ? 0.1 * sin(landing * 13) * exp(-landing * 5) : 0
        let scale = 0.82 + 0.18 * fraction + pop
        Text(verbatim: "\(value)")
            .font(.system(size: HookLayout.numberSize, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(TrailerStyle.emberText)
            .contentTransition(.numericText(value: Double(value)))
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: value)
            .trailerGlint(M.progress(t, 3.05, 0.75), strength: 0.75)
            .shadow(color: Palette.ember.opacity(0.3 + 0.35 * fraction), radius: CGFloat(14 + 18 * fraction), x: 0, y: 0)
            .scaleEffect(CGFloat(scale))
            .opacity(appear)
    }
}

/// A ring of light when the count lands.
private struct HookShockwave: View {
    let t: Double

    var body: some View {
        let p = M.progress(t, HookSwarm.lastArrival, 0.8)
        let reach: Double = TrailerCanvas.isTall ? 340 : 300
        let size = CGFloat(120 + reach * M.easeOut(p))
        Circle()
            .strokeBorder(TrailerStyle.emberRing, lineWidth: CGFloat(3 * (1 - p) + 0.5))
            .frame(width: size, height: size)
            .opacity(p > 0 && p < 1 ? (1 - p) * 0.7 : 0)
    }
}

/// "15 大分类 · 85 个动效家族" chips springing up under the headline.
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
        let pop = M.spring(t, at: 3.3 + Double(index) * 0.16, response: 0.5, damping: 0.62)
        let exit = M.easeIn(M.progress(t, 4.7 + Double(index) * 0.06, 0.5))
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

// MARK: - 5–11 s · Pain: "想要的动效，说不出名字？"

struct TrailerPainScene: View {
    let t: Double

    private struct Word {
        let text: String
        let x: CGFloat
        let y: CGFloat
        /// 0 = far (small, blurred), 1 = near.
        let depth: Double
    }

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

    /// Delay between words popping in: 0.28 s, tighter when there are many so all land before the collapse.
    private static let stagger: Double = {
        let count: Int = max(TrailerPainScene.words.count - 1, 1)
        let fit: Double = 2.3 / Double(count)
        return min(0.28, fit)
    }()

    var body: some View {
        let exit = M.easeIn(M.progress(t, 9.65, 0.6))
        let enter = M.easeOut(M.progress(t, 5.0, 1.0))
        ZStack {
            Text(verbatim: TrailerCopy.current.pain.backdropMark)
                .font(.system(size: TrailerCanvas.pick(300, 360), weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: TrailerCanvas.width)
                .foregroundStyle(Color.white.opacity(0.04))
                .rotationEffect(.degrees(-8 + 4 * sin(t * 0.5)))
                .scaleEffect(CGFloat(0.9 + 0.1 * enter))
                .opacity(enter * (1 - exit))
                .position(x: 205, y: TrailerLayout.painCollapse.y)
            ForEach(Self.words.indices, id: \.self) { index in
                wordView(index)
            }
            VStack(spacing: 6) {
                Text(verbatim: TrailerCopy.current.pain.titleLine1)
                    .foregroundStyle(Color.white)
                    .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 5.3, 0.8)))
                Text(verbatim: TrailerCopy.current.pain.titleLine2)
                    .foregroundStyle(TrailerStyle.emberText)
                    .textRenderer(GlyphBlurRenderer(progress: M.progress(t, 5.75, 0.8)))
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
        let appear = M.spring(t, at: 6.3 + seed * Self.stagger, response: 0.6, damping: 0.7)
        let collapse = M.easeIn(M.progress(t, 9.5 + seed * 0.04, 0.55))
        let driftX = CGFloat(7 * sin(t * 0.7 + seed * 1.9))
        let driftY = CGFloat(5 * cos(t * 0.9 + seed * 2.3)) + CGFloat(1 - M.clamp(appear)) * 18
        let breathe = 0.5 + 0.5 * sin(t * 1.4 + seed * 2)
        let blur = CGFloat((1 - word.depth) * 5 + 2.2 * breathe * (1 - word.depth * 0.6) + 4 * collapse)
        let scale = CGFloat((0.78 + 0.3 * word.depth) * (0.6 + 0.4 * appear) * (1 - 0.75 * collapse))
        let home = CGPoint(x: word.x + driftX, y: word.y + driftY)
        let point = M.mix(home, TrailerLayout.painCollapse, collapse)
        return Text(verbatim: word.text)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.88))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: 200)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(TrailerGlass(shape: Capsule(), frosted: true, shadowOpacity: 0.25))
            .scaleEffect(scale)
            .blur(radius: blur)
            .opacity(M.clamp(appear * 2) * (0.5 + 0.5 * word.depth) * (1 - collapse))
            .position(point)
    }
}
