import SwiftUI

extension Effect {
    static let showcaseBestLine = Effect(
        id: "showcase.best-line",
        category: .showcase,
        interaction: .tap,
        name: L("Best Line Trail", "最佳路线轨迹"),
        summary: L("A glowing trail carves down the mountain, racing a ghost of your best run; scrub to replay any point.", "发光轨迹沿山坡滑下，与个人最佳的幽灵同线竞速；拖动可回看任意位置。"),
        prompt: L(
            "A dark BEST LINE card shows a faint ridge, a dotted ghost of the descent route and a slim elevation profile beneath. On appear an orange-to-red gradient trail carves the S-curve from summit to valley over ~2.4 s (ease-in-out), glowing with an 8 pt orange shadow; a white haloed marker rides its tip, its tag counting elevation down from 2,256 m to 860 m, while a hollow “PB” ghost marker races the same line 15% slower. The profile fills orange up to a cursor in step and the distance ticks to 1.4 km. Dragging scrubs: the marker chases the finger along the route on a spring (response 0.3 s, damping 0.75) and the ghost trails on a looser one (0.6 s). Tapping replays, with a success haptic at the finish. Cinematic and competitive.",
            "深色“最佳路线”卡片：淡淡的山脊、虚线下滑路线，下方是细长海拔剖面。出现时，橙到红的渐变轨迹约 2.4 秒（缓入缓出）沿 S 形曲线从山顶滑到谷底，带 8pt 橙色辉光；白色光晕标记贴在前端，标签海拔从 2,256 米递减到 860 米；空心“PB”幽灵标记慢 15% 同线竞速。剖面随游标填橙，距离增至 1.4 公里。拖动时标记点以弹簧（响应 0.3 秒、阻尼 0.75）沿路线追随手指，幽灵以更松的弹簧（0.6 秒）落后跟随。点击重播，终点触发成功触觉，竞技感十足。"
        ),
        implementation: L(
            "An Animatable view gets the interpolated (run, ghost) progress pair each frame, trims the route with trimmedPath(from:to:) and reads currentPoint to place both markers and derive elevation and distance; the profile is a pre-sampled area Path masked to the progress. Scrubbing springs both values toward the sampled fraction nearest the finger.",
            "自定义 Animatable 视图逐帧获得插值后的（本次、幽灵）进度对，用 trimmedPath(from:to:) 截取路线，读取 currentPoint 放置两个标记点并换算海拔与距离；海拔剖面是预采样的面积 Path，按进度遮罩。拖动时两个进度以弹簧奔向手指下方最近的采样比例。"
        ),
        apis: ["Animatable", "AnimatablePair", "Path.trimmedPath(from:to:)", "Path.currentPoint", "spring(response:dampingFraction:)"],
        tags: ["path animation", "route", "ghost", "elevation", "路径动画", "路线", "幽灵对比", "海拔"],
        params: [
            .slider("duration", L("Run duration", "滑行时长"), 1.0...5.0, default: 2.4, unit: "s"),
            .slider("width", L("Trail width", "轨迹粗细"), 2...8, default: 4, decimals: 1, unit: "pt"),
            .slider("ghost", L("Ghost pace", "幽灵节奏"), 1.0...1.5, default: 1.15, unit: "×"),
            .toggle("elevation", L("Elevation tag", "海拔标签"), default: true),
        ]
    ) { ctx in
        SportBestLineDemo(ctx: ctx)
    }
}

private enum BestLineRoute {
    static let size = CGSize(width: 252, height: 132)
    static let top = 2256.0
    static let bottom = 860.0
    static let distance = 1.4

    static func path(in size: CGSize) -> Path {
        let w = size.width
        let h = size.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.04, y: h * 0.1))
        p.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.42), control1: CGPoint(x: w * 0.22, y: h * 0.04), control2: CGPoint(x: w * 0.1, y: h * 0.4))
        p.addCurve(to: CGPoint(x: w * 0.62, y: h * 0.6), control1: CGPoint(x: w * 0.58, y: h * 0.44), control2: CGPoint(x: w * 0.42, y: h * 0.68))
        p.addCurve(to: CGPoint(x: w * 0.96, y: h * 0.92), control1: CGPoint(x: w * 0.82, y: h * 0.52), control2: CGPoint(x: w * 0.72, y: h * 0.9))
        return p
    }

    /// (fraction, x) samples along the route, used to scrub by horizontal position.
    static let samples: [(fraction: CGFloat, x: CGFloat)] = {
        let full = BestLineRoute.path(in: BestLineRoute.size)
        let count = 160
        return (0...count).map { i in
            let f = CGFloat(i) / CGFloat(count)
            let x = full.trimmedPath(from: 0, to: max(f, 0.001)).currentPoint?.x ?? 0
            return (f, x)
        }
    }()

    /// The path fraction whose point lies closest to `x` horizontally — so the marker sits under the finger.
    static func fraction(nearestX x: CGFloat) -> CGFloat {
        var best: (fraction: CGFloat, distance: CGFloat) = (0, .greatestFiniteMagnitude)
        for sample in samples {
            let d = abs(sample.x - x)
            if d < best.distance { best = (sample.fraction, d) }
        }
        return best.fraction
    }

    /// Normalised drop (0 = summit, 1 = valley) at evenly spaced path fractions, for the profile strip.
    static let profile: [CGFloat] = {
        let full = BestLineRoute.path(in: BestLineRoute.size)
        let count = 60
        return (0...count).map { i in
            let f = CGFloat(i) / CGFloat(count)
            let y = full.trimmedPath(from: 0, to: max(f, 0.001)).currentPoint?.y ?? 0
            let fall = (y / BestLineRoute.size.height - 0.1) / 0.82
            return fall.clamped(to: 0...1)
        }
    }()
}

private struct SportBestLineDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    /// Last season's best run, racing the same line a little slower.
    @State private var ghost: CGFloat = 0
    @State private var runID = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run `task`, so they show the finished trail.
        _progress = State(initialValue: ctx.isStill ? 1 : 0)
        _ghost = State(initialValue: ctx.isStill ? 1 : 0)
    }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                BestLineCard(
                    progress: progress,
                    ghost: ghost,
                    lineWidth: ctx.cg("width"),
                    showElevation: ctx.bool("elevation"),
                    language: ctx.language
                )
                .padding(20)
                .frame(width: 292)
                .signatureCard()
                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .onTapGesture { runID += 1 }
                .gesture(scrubGesture)
                Spacer()
                DemoHint(text: L("Tap to replay, drag to scrub", "点击重播，拖动查看"), ctx: ctx)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) { await play() }
        // The trail already draws on appear, so the detail stage skips its one-shot intro replay.
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.8, delay: ctx["duration"] + 1.8, intro: false) { runID += 1 }
    }

    private var scrubGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Card content is inset 20 pt; map the finger's x to the route point directly beneath it.
                let x = (value.location.x - 20).clamped(to: 0...BestLineRoute.size.width)
                let target = BestLineRoute.fraction(nearestX: x)
                // Spring-loaded: the marker chases the finger along the route, the ghost trails on a looser spring.
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { progress = target }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { ghost = target }
            }
    }

    private func play() async {
        let silent = ctx.isPreview || runID == 0
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            progress = 0
            ghost = 0
        }
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        let duration = ctx["duration"]
        let ghostDuration = duration * max(ctx["ghost"], 1)
        withAnimation(.easeInOut(duration: duration)) { progress = 1 }
        withAnimation(.easeInOut(duration: ghostDuration)) { ghost = 1 }
        try? await Task.sleep(for: .seconds(ctx["duration"]))
        guard !Task.isCancelled else { return }
        if !silent { Haptics.success() }
    }
}

/// Animatable so that every intermediate progress re-evaluates the trimmed path, marker and readouts.
private struct BestLineCard: View, Animatable {
    var progress: CGFloat
    var ghost: CGFloat
    let lineWidth: CGFloat
    let showElevation: Bool
    let language: AppLanguage

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, ghost) }
        set {
            progress = newValue.first
            ghost = newValue.second
        }
    }

    private static let origin = CGPoint(x: BestLineRoute.size.width * 0.04, y: BestLineRoute.size.height * 0.1)

    private static func point(on path: Path, at fraction: CGFloat) -> CGPoint {
        let f = fraction.clamped(to: 0.001...1)
        return path.trimmedPath(from: 0, to: f).currentPoint ?? origin
    }

    var body: some View {
        let clamped = progress.clamped(to: 0...1)
        let size = BestLineRoute.size
        let full = BestLineRoute.path(in: size)
        let head = Self.point(on: full, at: clamped)
        let ghostHead = Self.point(on: full, at: ghost)
        let fall = ((Double(head.y / size.height) - 0.1) / 0.82).clamped(to: 0...1)
        let elevation = Int(BestLineRoute.top - (BestLineRoute.top - BestLineRoute.bottom) * fall)
        VStack(alignment: .leading, spacing: 12) {
            SportEyebrowRow(title: L("Best line", "最佳路线")(language), symbol: "point.topleft.down.curvedto.point.bottomright.up", trailing: "Nordkette")
            ZStack(alignment: .topLeading) {
                RidgeShape(seed: 3, baseline: 0.62, amplitude: 0.34)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                full.stroke(Color.white.opacity(0.14), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [2, 6]))
                full.trimmedPath(from: 0, to: clamped)
                    .stroke(
                        LinearGradient(colors: [Signature.accentSoft, Signature.accent, Signature.accentHot], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: Signature.accent.opacity(0.7), radius: 8)
                BestLineGhost()
                    .position(ghostHead)
                BestLineMarker()
                    .position(head)
                if showElevation {
                    BestLineTag(elevation: elevation)
                        .position(x: head.x.clamped(to: 34...(size.width - 34)), y: max(head.y - 24, 10))
                }
            }
            .frame(width: size.width, height: size.height)
            BestLineProfile(progress: clamped)
            BestLineFooter(progress: clamped, elevation: elevation, language: language)
        }
    }
}

private struct BestLineMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Signature.accent.opacity(0.3))
                .frame(width: 22, height: 22)
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .shadow(color: Signature.accent, radius: 6)
        }
    }
}

/// Hollow "PB" marker for the ghost of the best run.
private struct BestLineGhost: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                .frame(width: 14, height: 14)
            Text(verbatim: "PB")
                .font(.system(size: 7, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.7))
                .offset(y: 12)
        }
        .allowsHitTesting(false)
    }
}

/// Slim elevation profile: grey area for the whole run, orange up to the cursor.
private struct BestLineProfile: View {
    let progress: CGFloat

    private static let size = CGSize(width: BestLineRoute.size.width, height: 26)

    private static let area: Path = {
        let w = size.width
        let h = size.height
        let values = BestLineRoute.profile
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h))
        for index in values.indices {
            let x = w * CGFloat(index) / CGFloat(max(values.count - 1, 1))
            let y = h * (0.1 + 0.85 * values[index])
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }()

    var body: some View {
        let size = Self.size
        let cursorX: CGFloat = size.width * progress
        return ZStack(alignment: .topLeading) {
            Self.area.fill(Color.white.opacity(0.07))
            Self.area
                .fill(LinearGradient(colors: [Signature.accent.opacity(0.55), Signature.accent.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                .mask(alignment: .leading) {
                    Rectangle().frame(width: cursorX)
                }
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 1, height: size.height)
                .offset(x: cursorX)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

private struct BestLineTag: View {
    let elevation: Int

    var body: some View {
        Text("\(elevation.formatted()) m")
            .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(Color.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.white))
            .shadow(color: .black.opacity(0.35), radius: 5, y: 2)
    }
}

private struct BestLineFooter: View {
    let progress: CGFloat
    let elevation: Int
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(format: "%.1f", BestLineRoute.distance * Double(progress)))
                .font(Signature.number(34))
                .foregroundStyle(Color.white)
            Text(verbatim: "km")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
            Spacer(minLength: 0)
            Image(systemName: "arrow.down.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Signature.accent)
            Text("\(Int(BestLineRoute.top) - elevation) m")
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.white.opacity(0.8))
            Text(L("drop", "落差"), language)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
        }
    }
}
