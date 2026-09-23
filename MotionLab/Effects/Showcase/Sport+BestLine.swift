import SwiftUI

extension Effect {
    static let showcaseBestLine = Effect(
        id: "showcase.best-line",
        category: .showcase,
        interaction: .tap,
        name: L("Best Line Trail", "最佳路线轨迹"),
        summary: L("A glowing gradient trail carves down the mountain with a marker and live elevation readout.", "发光渐变轨迹沿山坡滑下，标记点与实时海拔读数随之移动。"),
        prompt: L(
            "A dark BEST LINE card shows a faint ridge silhouette and a dotted ghost of the descent route. On appear, an orange-to-red gradient trail carves along the S-shaped curve from summit to valley over ~2.4 s (ease-in-out), glowing with an 8 pt orange shadow; a white marker with a translucent halo sits exactly on the trail's leading tip and carries a small capsule tag whose elevation counts down from 2,256 m to 860 m as it descends. The footer distance ticks up from 0.0 to 1.4 km in sync. Tap replays the run; dragging horizontally scrubs the marker to the point of the line directly under the finger. Smooth, cinematic and satisfying, like replaying your best run.",
            "深色“最佳路线”卡片上有一道若隐若现的山脊剪影和虚线描出的下滑路线。出现时，橙到红的渐变轨迹沿 S 形曲线从山顶滑向谷底，用时约 2.4 秒（ease-in-out），并带 8pt 橙色辉光；白色标记点连同半透明光晕精确贴在轨迹最前端，头顶的小胶囊标签显示海拔，从 2,256 米随下降递减到 860 米；底部距离同步从 0.0 增长到 1.4 公里。点击重播，横向拖动时，标记点会落在手指正下方的路线位置上。顺滑、有电影感，就像回放自己最漂亮的一趟滑行。"
        ),
        implementation: L(
            "An Animatable view gets the interpolated progress each frame, trims the route path with trimmedPath(from:to:) and reads its currentPoint to place the marker and derive elevation and distance; scrubbing looks up the sampled path fraction whose x is nearest the finger.",
            "自定义 Animatable 视图逐帧获得插值后的进度，用 trimmedPath(from:to:) 截取路线，并读取其 currentPoint 来放置标记点、换算海拔与距离；拖动时在预采样表中查找 x 最接近手指的路径比例。"
        ),
        apis: ["Animatable", "Path.trimmedPath(from:to:)", "Path.currentPoint", "StrokeStyle", "task(id:)"],
        tags: ["path animation", "route", "trail", "elevation", "路径动画", "路线", "轨迹", "海拔"],
        params: [
            .slider("duration", L("Run duration", "滑行时长"), 1.0...5.0, default: 2.4, unit: "s"),
            .slider("width", L("Trail width", "轨迹粗细"), 2...8, default: 4, decimals: 1, unit: "pt"),
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
}

private struct SportBestLineDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var runID = 0

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                BestLineCard(
                    progress: progress,
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
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.8, delay: ctx["duration"] + 1.8) { runID += 1 }
    }

    private var scrubGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Card content is inset 20 pt; map the finger's x to the route point directly beneath it.
                let x = (value.location.x - 20).clamped(to: 0...BestLineRoute.size.width)
                var immediate = Transaction()
                immediate.disablesAnimations = true
                withTransaction(immediate) { progress = BestLineRoute.fraction(nearestX: x) }
            }
    }

    private func play() async {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { progress = 0 }
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: ctx["duration"])) { progress = 1 }
        try? await Task.sleep(for: .seconds(ctx["duration"]))
        guard !Task.isCancelled else { return }
        if !ctx.isPreview { Haptics.success() }
    }
}

/// Animatable so that every intermediate progress re-evaluates the trimmed path, marker and readouts.
private struct BestLineCard: View, Animatable {
    var progress: CGFloat
    let lineWidth: CGFloat
    let showElevation: Bool
    let language: AppLanguage

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let clamped = progress.clamped(to: 0...1)
        let size = BestLineRoute.size
        let full = BestLineRoute.path(in: size)
        let head = full.trimmedPath(from: 0, to: max(clamped, 0.001)).currentPoint ?? CGPoint(x: size.width * 0.04, y: size.height * 0.1)
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
                BestLineMarker()
                    .position(head)
                if showElevation {
                    BestLineTag(elevation: elevation)
                        .position(x: head.x.clamped(to: 34...(size.width - 34)), y: max(head.y - 24, 10))
                }
            }
            .frame(width: size.width, height: size.height)
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
