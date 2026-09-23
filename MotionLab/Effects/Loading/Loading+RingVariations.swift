import SwiftUI

// MARK: - Helpers

/// Fake network progress in irregular chunks. `onStep` fires after every chunk.
@MainActor
private func ringVarSimulate(
    speed: Double,
    animation: Animation = .smooth(duration: 0.45),
    set: @escaping (Double) -> Void,
    current: @escaping () -> Double,
    onStep: @escaping () -> Void = {}
) async -> Bool {
    withAnimation(.smooth(duration: 0.35)) { set(0) }
    try? await Task.sleep(for: .seconds(0.7))
    while current() < 1 {
        if Task.isCancelled { return false }
        let step: Double = Double.random(in: 0.05...0.15) * speed
        withAnimation(animation) { set(min(1, current() + step)) }
        onStep()
        try? await Task.sleep(for: .seconds(Double.random(in: 0.3...0.5)))
    }
    return !Task.isCancelled
}

private struct RingCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.37, y: rect.maxY - rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.minY + rect.height * 0.06))
        return path
    }
}

// MARK: - Tick ring

extension Effect {
    static let loadingTickRing = Effect(
        id: "loading.tick-ring",
        category: .loading,
        interaction: .state,
        name: L("Charging Tick Ring", "充电刻度环"),
        summary: L("Sixty radial ticks light and stretch one by one as the charge climbs.", "六十根放射刻度随电量爬升逐根点亮、伸长。"),
        prompt: L(
            "Sixty radial ticks (2.5 pt wide) form a 190 pt dial around a bolt glyph and a large rounded percentage. Charge climbs linearly at about 1% every 60 ms; as the level passes a tick it lengthens from 8 pt to 16 pt on a bouncy spring (response 0.35 s, damping 0.55), swapping 12% gray for a green → mint → sky gradient that wraps the dial. The newest tick glows and the bolt breathes 0.92 → 1.08 every 1.2 s. At 100% every tick flicks outward 4 pt in a clockwise ripple staggered 8 ms apart, and a success haptic plays. Energetic, precise, hardware-like.",
            "六十根放射状刻度（宽 2.5 pt）组成一个 190 pt 的表盘，中心是闪电图标与大号圆体百分比。电量线性攀升，约每 60 毫秒 1%；电量越过某根刻度时，它以弹跳弹簧（响应 0.35 秒、阻尼 0.55）从 8 pt 伸长到 16 pt，颜色从 12% 灰变为环绕表盘的绿 → 薄荷绿 → 天蓝渐变。最新点亮的刻度带柔光，闪电每 1.2 秒在 0.92 → 1.08 间呼吸。到达 100% 时所有刻度按顺时针以 8 毫秒间隔依次向外弹出 4 pt，形成一圈涟漪，并伴随成功触感。充满能量、精准、有硬件质感。"
        ),
        implementation: L(
            "Capsules pinned to the top of a square are rotated into a dial; each tick's lit flag animates its length and color with a spring, and the finale uses per-tick delayed springs.",
            "胶囊固定在正方形顶部再旋转排成表盘；每根刻度的点亮标志以弹簧驱动长度与颜色，收尾涟漪使用按序号延迟的弹簧。"
        ),
        apis: ["rotationEffect", "spring(response:dampingFraction:).delay", "phaseAnimator", "contentTransition(.numericText)"],
        tags: ["ticks", "charging", "dial", "battery", "刻度", "充电", "表盘", "电量"],
        params: [
            .slider("count", L("Ticks", "刻度数"), 24...90, default: 60, step: 1, decimals: 0),
            .slider("rate", L("Charge speed", "充电速度"), 0.5...3.0, default: 1.0),
            .slider("damping", L("Tick damping", "刻度阻尼"), 0.3...1.0, default: 0.55),
        ]
    ) { ctx in
        TickRingDemo(ctx: ctx)
    }
}

private struct TickRingDemo: View {
    let ctx: DemoContext
    @State private var level: Double = 0
    @State private var ripple = false
    @State private var run = 0

    var body: some View {
        let count: Int = max(ctx.int("count"), 8)
        let zh = ctx.language == .zh
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    TickView(index: index, count: count, level: level, damping: ctx["damping"], ripple: ripple)
                }
                center
            }
            .frame(width: 190, height: 190)
            Text(level >= 1 ? (zh ? "已充满" : "Fully charged") : (zh ? "正在充电" : "Charging"))
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: level >= 1)
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private var center: some View {
        VStack(spacing: 2) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Palette.green)
                .phaseAnimator([false, true]) { content, big in
                    content.scaleEffect(big ? 1.08 : 0.92)
                } animation: { _ in
                    .easeInOut(duration: 0.6)
                }
            Text("\(Int((level * 100).rounded()))%")
                .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: level))
                .animation(.snappy(duration: 0.2), value: level)
        }
    }

    private func play() async {
        ripple = false
        level = 0
        try? await Task.sleep(for: .seconds(0.5))
        let rate: Double = max(ctx["rate"], 0.1)
        while level < 1 {
            if Task.isCancelled { return }
            level = min(1, level + 0.01)
            try? await Task.sleep(for: .seconds(0.06 / rate))
        }
        ripple = true
        if !ctx.isPreview { Haptics.success() }
        try? await Task.sleep(for: .seconds(1.2))
        ripple = false
        try? await Task.sleep(for: .seconds(1.0))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct TickView: View {
    let index: Int
    let count: Int
    let level: Double
    let damping: Double
    let ripple: Bool

    var body: some View {
        let f: Double = Double(index) / Double(count)
        let on: Bool = level > f
        let head: Bool = on && level < f + 1 / Double(count) + 0.001
        let color: Color = f < 0.33 ? Palette.green : (f < 0.66 ? Palette.mint : Palette.sky)
        let delay: Double = ripple ? Double(index) * 0.008 : 0
        Capsule()
            .fill(on ? color : Color.primary.opacity(0.12))
            .frame(width: 2.5, height: on ? 16 : 8)
            .shadow(color: color.opacity(head ? 0.9 : 0), radius: 4)
            .offset(y: ripple ? -4 : 0)
            .animation(.spring(response: 0.35, dampingFraction: damping), value: on)
            .animation(.spring(response: 0.3, dampingFraction: 0.5).delay(delay), value: ripple)
            .frame(width: 190, height: 190, alignment: .top)
            .rotationEffect(.degrees(f * 360))
    }
}

// MARK: - App install pie

extension Effect {
    static let loadingInstallPie = Effect(
        id: "loading.install-pie",
        category: .loading,
        interaction: .state,
        name: L("App Install Pie", "应用安装饼图"),
        summary: L("A dimmed home-screen icon clears pie-wedge by wedge, then irises open.", "变暗的主屏图标以扇形逐步揭开，最后光圈式全开。"),
        prompt: L(
            "A 3 × 2 home-screen grid of 64 pt gradient app icons with labels; one icon is covered by a 55% black scrim with a thin white ring (radius 20 pt) at its center. As the download arrives in chunks, a clockwise pie wedge inside the ring is cut out of the scrim, each chunk sweeping over 0.45 s so the real icon shows through. At 100% the ring fades and the hole irises open — its radius springs from 17 pt to 52 pt (response 0.45 s) until the scrim is gone — then the icon bounces 1.0 → 1.1 → 1.0 and its label cross-fades from 'Installing…' to 'Motion'. Faithful to iOS, quietly delightful.",
            "主屏上排着 3 × 2 个 64 pt 的渐变应用图标及名称；其中一个图标被 55% 的黑色遮罩覆盖，中心有一圈细白环（半径 20 pt）。下载分段到达，环内的顺时针扇形从遮罩中被切除，每段以 0.45 秒扫过，真实图标随之透出。到达 100% 时白环淡出，孔洞像光圈一样打开——半径以弹簧（响应 0.45 秒）从 17 pt 扩到 52 pt，直到遮罩消失——随后图标在 1.0 → 1.1 → 1.0 间弹跳一下，名称从“正在安装…”交叉淡换为“Motion”。忠实还原 iOS，含蓄而惊喜。"
        ),
        implementation: L(
            "An Animatable Shape draws the scrim rectangle plus a pie sector (or full circle) and fills it with the even-odd rule, so the sector becomes a hole; progress and hole radius animate together via AnimatablePair.",
            "Animatable Shape 绘制遮罩矩形加扇形（或整圆），并用奇偶填充规则使扇形成为孔洞；进度与孔洞半径通过 AnimatablePair 一起动画。"
        ),
        apis: ["Shape", "AnimatablePair", "FillStyle(eoFill:)", "keyframeAnimator", "contentTransition(.opacity)"],
        tags: ["app install", "pie", "home screen", "download", "安装", "饼图", "主屏幕", "下载"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
            .slider("scrim", L("Scrim opacity", "遮罩浓度"), 0.3...0.8, default: 0.55),
            .slider("response", L("Iris response", "光圈响应"), 0.2...0.9, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        InstallPieDemo(ctx: ctx)
    }
}

private struct InstallApp {
    let symbol: String
    let colors: [Color]
    let name: LocalizedText
}

private struct InstallPieDemo: View {
    let ctx: DemoContext
    @State private var progress: Double = 0
    @State private var holeRadius: CGFloat = 17
    @State private var installed = false
    @State private var bounce = 0
    @State private var run = 0

    private let apps: [InstallApp] = [
        InstallApp(symbol: "message.fill", colors: [Palette.green, Palette.mint], name: L("Messages", "信息")),
        InstallApp(symbol: "camera.fill", colors: [Color.gray, Color(white: 0.4)], name: L("Camera", "相机")),
        InstallApp(symbol: "music.note", colors: [Palette.pink, Palette.red], name: L("Music", "音乐")),
        InstallApp(symbol: "map.fill", colors: [Palette.sky, Palette.mint], name: L("Maps", "地图")),
        InstallApp(symbol: "sparkles", colors: [Palette.indigo, Palette.violet], name: L("Motion", "Motion")),
        InstallApp(symbol: "cloud.sun.fill", colors: [Palette.blue, Palette.sky], name: L("Weather", "天气")),
    ]

    var body: some View {
        VStack(spacing: 20) {
            Grid(horizontalSpacing: 24, verticalSpacing: 18) {
                GridRow {
                    icon(0)
                    icon(1)
                    icon(2)
                }
                GridRow {
                    icon(3)
                    icon(4)
                    icon(5)
                }
            }
            DemoHint(text: L("Tap to reinstall", "点击重新安装"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private func icon(_ index: Int) -> some View {
        let app = apps[index]
        let target = index == 4
        return VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LinearGradient(colors: app.colors, startPoint: .top, endPoint: .bottom))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: app.symbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .overlay {
                    if target { scrim }
                }
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .keyframeAnimator(initialValue: CGFloat(1), trigger: target ? bounce : 0) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(1.1, duration: 0.14)
                        SpringKeyframe(1.0, duration: 0.45, spring: .bouncy)
                    }
                }
            Text(target && !installed ? (ctx.language == .zh ? "正在安装…" : "Installing…") : app.name(ctx.language))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: installed)
        }
        .frame(width: 72)
    }

    private var scrim: some View {
        ZStack {
            PieScrimShape(progress: progress, holeRadius: holeRadius)
                .fill(Color.black.opacity(ctx["scrim"]), style: FillStyle(eoFill: true))
            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                .frame(width: 40, height: 40)
                .opacity(holeRadius > 18 ? 0 : 1)
        }
    }

    private func play() async {
        installed = false
        holeRadius = 17
        let done = await ringVarSimulate(speed: ctx["speed"], set: { progress = $0 }, current: { progress })
        guard done else { return }
        try? await Task.sleep(for: .seconds(0.2))
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) { holeRadius = 52 }
        try? await Task.sleep(for: .seconds(0.3))
        installed = true
        bounce += 1
        if !ctx.isPreview { Haptics.success() }
        try? await Task.sleep(for: .seconds(2.0))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct PieScrimShape: Shape {
    var progress: Double
    var holeRadius: CGFloat

    var animatableData: AnimatablePair<Double, CGFloat> {
        get { AnimatablePair(progress, holeRadius) }
        set {
            progress = newValue.first
            holeRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let clamped: Double = min(max(progress, 0), 1)
        if holeRadius > 17.5 || clamped >= 0.999 {
            path.addEllipse(in: CGRect(x: center.x - holeRadius, y: center.y - holeRadius, width: holeRadius * 2, height: holeRadius * 2))
        } else if clamped > 0.001 {
            path.move(to: center)
            path.addArc(center: center, radius: holeRadius, startAngle: .degrees(-90), endAngle: .degrees(-90 + clamped * 360), clockwise: false)
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Elastic ring

extension Effect {
    static let loadingElasticRing = Effect(
        id: "loading.elastic-ring",
        category: .loading,
        interaction: .state,
        name: L("Elastic Ring", "弹性进度环"),
        summary: L("Each chunk overshoots and springs back, with a head bead that swells on impact.", "每段进度都冲过头再弹回，前端珠子受力时鼓起。"),
        prompt: L(
            "A 170 pt ring with a 12 pt pink → coral → amber stroke and round caps sits above '12 of 24 photos'. Every progress chunk springs forward on an under-damped spring (response 0.55 s, damping 0.55), visibly overshooting past the target and recoiling before it rests, while a 20 pt white head bead swells to 150% over 0.1 s and relaxes on a bouncy spring, and the whole ring squashes to 97% and rebounds. The photo count and big rounded percentage roll digit by digit. At 100% the bead dissolves and a success haptic plays. Rubbery, energetic, hand-made.",
            "直径 170 pt 的圆环，12 pt 粉 → 珊瑚 → 琥珀渐变描边、圆头，下方写着“12 / 24 张照片”。每段进度都以欠阻尼弹簧（响应 0.55 秒、阻尼 0.55）向前弹出，明显冲过目标再回缩落定；同时 20 pt 的白色前端珠子在 0.1 秒内鼓到 150%，再以弹跳弹簧恢复，整个圆环也被压到 97% 后回弹。照片计数与大号圆体百分比逐位滚动。到达 100% 时珠子消散并伴随成功触感。橡胶般有弹性、充满活力、带手作感。"
        ),
        implementation: L(
            "An Animatable view interpolates the spring-driven progress so the trim and the bead's rotation stay locked together; a keyframeAnimator keyed on the chunk count swells the bead and squashes the ring.",
            "Animatable 视图插值弹簧驱动的进度，让 trim 与珠子的旋转严格同步；以分段计数为触发器的 keyframeAnimator 让珠子鼓起、圆环挤压。"
        ),
        apis: ["Animatable", "trim(from:to:)", "keyframeAnimator(initialValue:trigger:)", "spring(response:dampingFraction:)"],
        tags: ["elastic", "spring", "overshoot", "upload", "弹性", "弹簧", "过冲", "上传"],
        params: [
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.55),
            .slider("response", L("Response", "响应"), 0.2...1.0, default: 0.55, unit: "s"),
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
        ]
    ) { ctx in
        ElasticRingDemo(ctx: ctx)
    }
}

private struct ElasticRingDemo: View {
    let ctx: DemoContext
    @State private var progress: Double = 0
    @State private var steps = 0
    @State private var run = 0

    var body: some View {
        let zh = ctx.language == .zh
        let photos: Int = Int((progress * 24).rounded(.down))
        VStack(spacing: 18) {
            ZStack {
                ElasticRingView(progress: progress, beadVisible: progress < 1, pulse: steps)
                    .keyframeAnimator(initialValue: CGFloat(1), trigger: steps) { content, squash in
                        content.scaleEffect(squash)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            CubicKeyframe(0.97, duration: 0.1)
                            SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                        }
                    }
                Text("\(Int((min(max(progress, 0), 1) * 100).rounded()))%")
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(value: progress))
            }
            .frame(width: 170, height: 170)
            Text(zh ? "已上传 \(photos) / 24 张照片" : "\(photos) of 24 photos")
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(photos)))
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private func play() async {
        steps = 0
        let spring = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
        let done = await ringVarSimulate(speed: ctx["speed"], animation: spring, set: { progress = $0 }, current: { progress }, onStep: { steps += 1 })
        guard done else { return }
        if !ctx.isPreview { Haptics.success() }
        try? await Task.sleep(for: .seconds(1.8))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct ElasticRingView: View, Animatable {
    var progress: Double
    let beadVisible: Bool
    let pulse: Int

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        // The spring may overshoot above 1; clamp only the drawing, not the motion.
        let shown: Double = min(max(progress, 0), 1)
        let gradient = AngularGradient(colors: [Palette.pink, Palette.coral, Palette.amber, Palette.pink], center: .center)
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 12)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(gradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
                .shadow(color: Palette.coral.opacity(0.5), radius: 5)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: pulse) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(1.5, duration: 0.1)
                        SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                    }
                }
                .offset(y: -85)
                .rotationEffect(.degrees(shown * 360))
                .opacity(beadVisible && progress > 0.005 ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: beadVisible)
        }
        .frame(width: 170, height: 170)
    }
}

// MARK: - Ring to check

extension Effect {
    static let loadingRingToCheck = Effect(
        id: "loading.ring-to-check",
        category: .loading,
        interaction: .state,
        name: L("Ring to Check Badge", "进度环变对勾徽章"),
        summary: L("A finished ring floods green, writes a check, then docks as a badge in a file row.", "完成的进度环灌满绿色、写出对勾，再收缩停靠为文件行里的徽章。"),
        prompt: L(
            "A 140 pt sky ring with a 10 pt stroke uploads in chunks. At 100% the choreography runs in three beats: a green disc floods outward from the center on a spring (response 0.4 s, damping 0.7); 150 ms later a 4 pt white check is written in over 0.35 s ease-out; after 0.7 s the badge shrinks to 23% and glides left on a smooth 0.55 s curve into the leading slot of a 'Report.pdf · Uploaded' row that slides in from 20 pt below and fades up. A success haptic accompanies the check. Everything reverses on replay. Tidy, conclusive, spatially continuous.",
            "一枚 140 pt、10 pt 线宽的天蓝进度环分段上传。到达 100% 后分三拍演出：绿色圆盘以弹簧（响应 0.4 秒、阻尼 0.7）从中心向外灌满；150 毫秒后用 0.35 秒缓出写出 4 pt 白色对勾；0.7 秒后徽章缩小到 23%，以 0.55 秒平滑曲线向左滑入一行“Report.pdf · 已上传”的首位，这一行同时从下方 20 pt 处滑入并淡入。对勾出现时伴随成功触感。重播时全部反向。利落、有结论感、空间上连贯。"
        ),
        implementation: L(
            "A phase enum drives the trim, a scaling disc, a trimmed check path and a final scale + offset that docks the badge next to a row inserted with a move-and-fade transition.",
            "阶段枚举依次驱动 trim、缩放圆盘、裁剪对勾路径，最后以缩放 + 位移把徽章停靠到一行以移动淡入转场插入的文件条目旁。"
        ),
        apis: ["trim(from:to:)", "scaleEffect", "offset", "transition(.move(edge:).combined(with:))", "spring(response:dampingFraction:)"],
        tags: ["checkmark", "upload", "badge", "choreography", "对勾", "上传", "徽章", "编排"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
            .slider("hold", L("Check hold", "对勾停留"), 0.3...2.0, default: 0.7, decimals: 1, unit: "s"),
            .toggle("dock", L("Dock into row", "停靠到列表"), default: true),
        ]
    ) { ctx in
        RingToCheckDemo(ctx: ctx)
    }
}

private enum RingCheckPhase: Int {
    case uploading
    case filled
    case checked
    case docked
}

private struct RingToCheckDemo: View {
    let ctx: DemoContext
    @State private var progress: Double = 0
    @State private var phase: RingCheckPhase = .uploading
    @State private var run = 0

    var body: some View {
        let docked = phase == .docked
        VStack(spacing: 18) {
            ZStack {
                if docked { row.transition(.move(edge: .bottom).combined(with: .opacity)) }
                badge
                    .scaleEffect(docked ? 0.23 : 1)
                    .offset(x: docked ? -108 : 0)
            }
            .frame(width: 290, height: 170)
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private var badge: some View {
        let filled = phase.rawValue >= RingCheckPhase.filled.rawValue
        let checked = phase.rawValue >= RingCheckPhase.checked.rawValue
        return ZStack {
            Circle().stroke(Color.primary.opacity(0.08), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Palette.sky, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Palette.green)
                .scaleEffect(filled ? 1.08 : 0.01)
                .opacity(filled ? 1 : 0)
            RingCheckShape()
                .trim(from: 0, to: checked ? 1 : 0)
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 52, height: 40)
            if !filled {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(value: progress))
                    .transition(.opacity)
            }
        }
        .frame(width: 140, height: 140)
    }

    private var row: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Report.pdf")
                    .font(.subheadline.weight(.semibold))
                Text(ctx.language == .zh ? "已上传 · 2.4 MB" : "Uploaded · 2.4 MB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "doc.fill")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .frame(width: 270, height: 64)
        .demoCard(cornerRadius: 18)
    }

    private func play() async {
        withAnimation(.smooth(duration: 0.5)) { phase = .uploading }
        let done = await ringVarSimulate(speed: ctx["speed"], set: { progress = $0 }, current: { progress })
        guard done else { return }
        try? await Task.sleep(for: .seconds(0.2))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { phase = .filled }
        try? await Task.sleep(for: .seconds(0.15))
        withAnimation(.easeOut(duration: 0.35)) { phase = .checked }
        if !ctx.isPreview { Haptics.success() }
        try? await Task.sleep(for: .seconds(ctx["hold"]))
        guard !Task.isCancelled else { return }
        if ctx.bool("dock") {
            withAnimation(.smooth(duration: 0.55)) { phase = .docked }
        }
        try? await Task.sleep(for: .seconds(2.0))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

// MARK: - Marching dash ring

extension Effect {
    static let loadingDashFlowRing = Effect(
        id: "loading.dash-flow-ring",
        category: .loading,
        interaction: .state,
        name: L("Streaming Dash Ring", "流动虚线环"),
        summary: L("The filled arc is made of dashes that keep streaming, then fuse solid when done.", "已填充的弧由不断流动的虚线构成，完成时熔合为实线。"),
        prompt: L(
            "An AirDrop-style receive screen: a 64 pt gradient avatar sits inside a 160 pt ring with a faint track. The received portion is drawn as a 7 pt round-capped dashed stroke (6 pt dashes repeating every 20 pt) whose dash phase advances 26 pt per second, so data visibly streams toward the head while the arc itself grows chunk by chunk over 0.45 s. The file name and a '3.1 of 8.0 MB' readout roll below. At 100% the dashes fuse into a solid violet stroke over 0.35 s, the avatar pops 1.0 → 1.08 → 1.0, and a success haptic plays. Alive, technical, reassuring.",
            "AirDrop 风格的接收界面：64 pt 的渐变头像位于一枚 160 pt 圆环中，底部为淡色轨道。已接收的部分用 7 pt 圆头虚线描绘（实线段 6 pt、每 20 pt 重复一次），虚线相位每秒前进 26 pt，数据看起来正源源不断流向前端；同时弧线本身随分段进度以 0.45 秒增长。下方滚动显示文件名与“3.1 / 8.0 MB”读数。到达 100% 时虚线在 0.35 秒内熔合为紫罗兰实线，头像在 1.0 → 1.08 → 1.0 间弹一下，并伴随成功触感。生动、有技术感、令人安心。"
        ),
        implementation: L(
            "A TimelineView advances StrokeStyle.dashPhase on a trimmed circle; a solid trimmed copy cross-fades in on completion.",
            "TimelineView 推进裁剪圆上 StrokeStyle 的 dashPhase；完成时交叉淡入一条实线的裁剪副本。"
        ),
        apis: ["StrokeStyle(dash:dashPhase:)", "TimelineView", "trim(from:to:)", "keyframeAnimator"],
        tags: ["dashed", "airdrop", "streaming", "receive", "虚线", "隔空投送", "流动", "接收"],
        params: [
            .slider("flow", L("Flow speed", "流速"), 0...80, default: 26, decimals: 0, unit: "pt/s"),
            .slider("dash", L("Dash length", "虚线长度"), 2...16, default: 6, decimals: 0, unit: "pt"),
            .slider("speed", L("Progress speed", "进度速度"), 0.4...2.5, default: 1.0),
        ]
    ) { ctx in
        DashFlowRingDemo(ctx: ctx)
    }
}

private struct DashFlowRingDemo: View {
    let ctx: DemoContext
    @State private var progress: Double = 0
    @State private var done = false
    @State private var pops = 0
    @State private var run = 0

    var body: some View {
        let zh = ctx.language == .zh
        let mb: Double = progress * 8
        VStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 7)
                DashFlowArc(progress: progress, flow: ctx["flow"], dash: ctx.cg("dash"), paused: done)
                    .opacity(done ? 0 : 1)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Palette.violet, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(done ? 1 : 0)
                avatar
            }
            .frame(width: 160, height: 160)
            .animation(.easeInOut(duration: 0.35), value: done)
            VStack(spacing: 3) {
                Text(verbatim: "Keynote_Final.mov")
                    .font(.subheadline.weight(.semibold))
                Text(String(format: zh ? "%.1f / 8.0 MB · 来自 Mia" : "%.1f of 8.0 MB · from Mia", mb))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: mb))
            }
            DemoHint(text: L("Tap to restart", "点击重新开始"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { run += 1 }
        .task(id: run) { await play() }
    }

    private var avatar: some View {
        Text(verbatim: "MJ")
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 64, height: 64)
            .background(LinearGradient(colors: [Palette.pink, Palette.violet], startPoint: .top, endPoint: .bottom), in: Circle())
            .keyframeAnimator(initialValue: CGFloat(1), trigger: pops) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(1.08, duration: 0.15)
                    SpringKeyframe(1.0, duration: 0.45, spring: .bouncy)
                }
            }
    }

    private func play() async {
        done = false
        let finished = await ringVarSimulate(speed: ctx["speed"], set: { progress = $0 }, current: { progress })
        guard finished else { return }
        try? await Task.sleep(for: .seconds(0.3))
        done = true
        pops += 1
        if !ctx.isPreview { Haptics.success() }
        try? await Task.sleep(for: .seconds(1.8))
        if ctx.isPreview && !Task.isCancelled { run += 1 }
    }
}

private struct DashFlowArc: View {
    let progress: Double
    let flow: Double
    let dash: CGFloat
    let paused: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: paused)) { timeline in
            let t: Double = timeline.date.timeIntervalSinceReferenceDate
            let period: Double = Double(dash) + 14
            let phase: CGFloat = CGFloat(-(t * flow).truncatingRemainder(dividingBy: period))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [Palette.sky, Palette.violet], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round, dash: [dash, 14], dashPhase: phase)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
