import SwiftUI

extension Effect {
    static let showcaseFinanceCard = Effect(
        id: "showcase.finance-card",
        category: .showcase,
        interaction: .tap,
        name: L("Live Balance Card", "实时余额卡片"),
        summary: L(
            "A ticking balance, a sparkline that draws itself per range, and a card that flips to its details.",
            "余额实时跳动，走势线按时间范围自行描绘，卡片翻转露出卡面信息。"
        ),
        prompt: L(
            "A dark glossy wallet widget: an eyebrow, a large rounded currency balance, a lime or coral delta chip, an orange sparkline with a soft gradient fill and a pulsing live dot at its tip, and a 1D · 1W · 1M · 1Y segmented row. Every ~2.2 s the balance ticks by a few dollars, its digits rolling with a numeric content transition. Picking a range slides a lime selection pill between chips via shared geometry (spring, response 0.4 s, damping 0.8), the delta rolls to the new percentage while its chip cross-fades between lime (up) and coral (down), and the new sparkline draws itself left to right over 0.7 s (ease-out) with the fill revealed in step. Tapping the card flips it 180° around its vertical axis on a spring (response 0.6 s, damping 0.78) with light perspective; exactly at 90° the face swaps to the card back — masked number, expiry and an orange stripe. Precise, alive and trustworthy.",
            "深色光泽钱包小组件：小标题、大号圆体货币余额、青柠或珊瑚色的涨跌标签、带柔和渐变填充的橙色走势线（末端有脉冲“实时”圆点），以及 1天 · 1周 · 1月 · 1年 分段选择。每隔约 2.2 秒余额跳动几元，数字以数字滚动过渡更新。切换时间范围时，青柠色选中胶囊通过共享几何在标签间滑动（弹簧，响应 0.4 秒、阻尼 0.8），涨跌幅滚动到新百分比，标签在青柠（涨）与珊瑚色（跌）之间交叉渐变，新的走势线在 0.7 秒内自左向右描绘（缓出），下方填充同步揭示。点击卡片，它以弹簧（响应 0.6 秒、阻尼 0.78）带轻微透视绕竖轴翻转 180°，恰在 90° 时切换为卡背——隐藏的卡号、有效期与一条橙色色带。精确、鲜活、值得信赖。"
        ),
        implementation: L(
            "An Animatable flipper receives the interpolated angle and swaps face opacities at 90°; the balance is Text(_:format: .currency) with contentTransition(.numericText(value:)) fed by a task(id:) loop; the sparkline is a smoothed Path revealed with trim(from:to:) and a matching mask on its gradient fill.",
            "自定义 Animatable 翻转视图获取插值角度，在 90° 时切换正反面透明度；余额使用 Text(_:format: .currency) 配合 contentTransition(.numericText(value:))，由 task(id:) 循环驱动；走势线是平滑 Path，用 trim(from:to:) 描绘，渐变填充使用同步的遮罩揭示。"
        ),
        apis: ["Animatable", "rotation3DEffect", "contentTransition(.numericText(value:))", "trim(from:to:)", "matchedGeometryEffect"],
        tags: ["finance", "wallet", "balance", "sparkline", "金融", "钱包", "余额", "走势图"],
        params: [
            .slider("flip", L("Flip response", "翻转弹簧响应"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("draw", L("Sparkline draw", "走势线描绘时长"), 0.3...1.6, default: 0.7, unit: "s"),
            .slider("interval", L("Tick interval", "余额跳动间隔"), 1...5, default: 2.2, unit: "s"),
        ]
    ) { ctx in
        LifeFinanceDemo(ctx: ctx)
    }
}

// MARK: - Model

private enum LifeRange: Int, CaseIterable {
    case day, week, month, year

    var title: LocalizedText {
        switch self {
        case .day: return L("1D", "1天")
        case .week: return L("1W", "1周")
        case .month: return L("1M", "1月")
        case .year: return L("1Y", "1年")
        }
    }

    var change: Double {
        switch self {
        case .day: return 1.2
        case .week: return 3.8
        case .month: return -2.1
        case .year: return 18.6
        }
    }

    /// Deterministic 0…1 series: a trend plus hashed wiggle, ending where the trend points.
    var series: [Double] {
        let count = 32
        let trend = change / 20
        return (0..<count).map { i in
            let t = Double(i) / Double(count - 1)
            let n = sin(Double(i + rawValue * 40) * 12.9898 + 78.233) * 43758.5453
            let wiggle = (n - n.rounded(.down) - 0.5) * 0.22
            let wave = sin(t * .pi * (2.5 + Double(rawValue))) * 0.08
            return 0.5 + trend * (t - 0.5) * 1.6 + wiggle * (0.4 + 0.6 * t) + wave
        }
    }
}

// MARK: - Demo

private struct LifeFinanceDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var range: LifeRange = .week
    @State private var drawn: CGFloat = 0
    @State private var balance: Double = 0
    @State private var angle: Double = 0
    @State private var step = 0

    private var zh: Bool { ctx.language == .zh }
    private var baseBalance: Double { zh ? 176_240.18 : 24_815.42 }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LifeFinanceFlipper(angle: angle) {
                    front
                } back: {
                    LifeCardBack(zh: zh)
                }
                .frame(width: 300, height: 236)
                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .onTapGesture(perform: flip)
                Spacer(minLength: 0)
                DemoHint(text: L("Pick a range · tap the card to flip", "选择时间范围 · 点击卡片翻面"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if balance == 0 { balance = baseBalance }
            redraw()
        }
        .onChange(of: ctx.language) { _, _ in balance = baseBalance }
        .task(id: ctx["interval"]) { await tick() }
        .autoplay(ctx.isPreview, every: 1.8, delay: 1.0) { previewTick() }
    }

    private var front: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SportEyebrowRow(title: L("Total balance", "总资产")(ctx.language), symbol: "creditcard.fill")
                Spacer(minLength: 0)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Signature.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(balance, format: .currency(code: zh ? "CNY" : "USD").locale(Locale(identifier: zh ? "zh_CN" : "en_US")))
                    .font(Signature.number(30))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: balance))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                deltaChip
            }
            LifeSparkline(values: range.series, progress: drawn, rising: range.change >= 0)
            chips
        }
        .padding(18)
        .frame(width: 300, height: 236, alignment: .top)
        .signatureCard()
    }

    private var deltaChip: some View {
        let up = range.change >= 0
        return HStack(spacing: 3) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .heavy))
            Text(abs(range.change), format: .number.precision(.fractionLength(1)))
                .contentTransition(.numericText(value: range.change))
            Text(verbatim: "%")
        }
        .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
        .foregroundStyle(Color.black)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(up ? Signature.lime : Palette.coral))
        .animation(.easeInOut(duration: 0.3), value: up)
    }

    private var chips: some View {
        HStack(spacing: 4) {
            ForEach(LifeRange.allCases, id: \.self) { item in
                Button {
                    select(item)
                } label: {
                    Text(item.title, ctx.language)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(item == range ? Color.black : Signature.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background {
                            if item == range {
                                Capsule()
                                    .fill(Signature.lime)
                                    .matchedGeometryEffect(id: "range", in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func select(_ item: LifeRange) {
        guard item != range else { return }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { range = item }
        redraw()
    }

    private func redraw() {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { drawn = 0 }
        withAnimation(.easeOut(duration: ctx["draw"]).delay(0.05)) { drawn = 1 }
    }

    private func flip() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: ctx["flip"], dampingFraction: 0.78)) { angle += 180 }
    }

    private func tick() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(max(ctx["interval"], 0.5)))
            guard !Task.isCancelled else { return }
            let n = sin(Date().timeIntervalSinceReferenceDate * 7.3) * 43758.5453
            let jitter = (n - n.rounded(.down) - 0.4) * (zh ? 60 : 9)
            withAnimation(.snappy) { balance = max(0, balance + (jitter * 100).rounded() / 100) }
        }
    }

    private func previewTick() {
        switch step % 4 {
        case 3:
            flip()
        case 0 where Int(angle / 180) % 2 == 1:
            flip()
        default:
            select(LifeRange(rawValue: (range.rawValue + 1) % LifeRange.allCases.count) ?? .day)
        }
        step += 1
    }
}

// MARK: - Flip

/// Receives the interpolated angle every frame so both faces swap exactly at 90°.
private struct LifeFinanceFlipper<Front: View, Back: View>: View, Animatable {
    var angle: Double
    @ViewBuilder var front: () -> Front
    @ViewBuilder var back: () -> Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private var showsBack: Bool {
        let wrapped = angle.truncatingRemainder(dividingBy: 360)
        let a = wrapped < 0 ? wrapped + 360 : wrapped
        return a > 90 && a < 270
    }

    var body: some View {
        ZStack {
            front()
                .opacity(showsBack ? 0 : 1)
            back()
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsBack ? 1 : 0)
                .allowsHitTesting(showsBack)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

private struct LifeCardBack: View {
    let zh: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Signature.accentGradient)
                .frame(height: 40)
                .padding(.top, 26)
            HStack {
                Text(verbatim: "•••• •••• •••• 4821")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
            HStack(spacing: 22) {
                detail(zh ? "有效期" : "Expires", "08/29")
                detail("CVV", "•••")
                Spacer(minLength: 0)
                Image(systemName: "wave.3.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Signature.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            Spacer(minLength: 0)
            Text(zh ? "点击翻回正面" : "Tap to flip back")
                .signatureEyebrow()
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
        }
        .frame(width: 300, height: 236)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .signatureCard()
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).signatureEyebrow()
            Text(verbatim: value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white)
        }
    }
}

// MARK: - Sparkline

private struct LifeSparkline: View {
    let values: [Double]
    let progress: CGFloat
    let rising: Bool

    /// The card's content width is fixed (300 − 2 × 18), so no GeometryReader is needed.
    private static let size = CGSize(width: 264, height: 64)

    var body: some View {
        let size = Self.size
        let points = Self.points(values, in: size)
        let line = Self.smoothed(points)
        let tint = rising ? Signature.accent : Palette.coral
        return ZStack(alignment: .topLeading) {
            Self.area(line, points: points, height: size.height)
                .fill(LinearGradient(colors: [tint.opacity(0.35), tint.opacity(0)], startPoint: .top, endPoint: .bottom))
                .mask(alignment: .leading) {
                    Rectangle().frame(width: size.width * progress)
                }
            line
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .shadow(color: tint.opacity(0.6), radius: 5)
            if let last = points.last {
                SportLiveDot(color: tint, size: 7)
                    .position(last)
                    .opacity(progress >= 0.99 ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: progress >= 0.99)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private static func points(_ values: [Double], in size: CGSize) -> [CGPoint] {
        guard values.count > 1, let lo = values.min(), let hi = values.max() else { return [] }
        let span = max(hi - lo, 0.0001)
        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = size.height * (0.1 + 0.8 * CGFloat(1 - (value - lo) / span))
            return CGPoint(x: x, y: y)
        }
    }

    /// Midpoint quadratic smoothing: soft corners that still pass near every sample.
    private static func smoothed(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previous)
        }
        if let last = points.last { path.addLine(to: last) }
        return path
    }

    private static func area(_ line: Path, points: [CGPoint], height: CGFloat) -> Path {
        var path = line
        guard let first = points.first, let last = points.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: height))
        path.addLine(to: CGPoint(x: first.x, y: height))
        path.closeSubpath()
        return path
    }
}
