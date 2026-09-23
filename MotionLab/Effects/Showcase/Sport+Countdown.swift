import SwiftUI

extension Effect {
    static let showcaseGoCountdown = Effect(
        id: "showcase.go-countdown",
        category: .showcase,
        interaction: .tap,
        name: L("3-2-1 GO Gate", "3-2-1 出发门"),
        summary: L("A start-gate ring drains every second while digits punch in, then GO bursts with a shockwave.", "出发门圆环每秒流逝、数字重击登场，最后 GO 伴随冲击波爆发。"),
        prompt: L(
            "A dark START GATE card with a 170 pt ring (10 pt track, orange gradient stroke with glow) around a rounded numeral. On tap each count punches in from 180% scale and zero opacity on a snappy spring (0.35 s, damping 0.6) while the previous digit shrinks to 40% and fades; the ring refills instantly and then drains linearly over one beat, and a medium haptic lands on every number. On zero the ring snaps full in lime, \"GO\" pops in with overshoot, a 3 pt shockwave ring expands to 190% while fading out over 0.9 s ease-out, and a success haptic fires; after 1.6 s it settles back to the idle \"Tap to start\" state. Rhythmic, tense, then explosive.",
            "深色“出发门”卡片：170pt 圆环（10pt 轨道、带辉光的橙色渐变描边）中央是圆体数字。点击后每个数字从 180% 缩放、零透明度以利落弹簧（0.35 秒、阻尼 0.6）重击登场，上一个数字缩到 40% 淡出；圆环瞬间补满，再在一拍内线性流逝，每个数字一次中等触感。归零时圆环以青柠色瞬间填满，“GO”带过冲弹出，一圈 3pt 冲击波以 0.9 秒 ease-out 扩到 190% 并消散，同时触发成功触感；1.6 秒后回到“点击开始”待机态。节奏紧凑，蓄力后爆发。"
        ),
        implementation: L(
            "An async loop in task(id:) steps the count; each digit is re-identified with .id so an asymmetric scale+opacity transition plays, while the ring trim animates linearly per beat and a separate ring handles the shockwave.",
            "task(id:) 中的异步循环推进计数；每个数字通过 .id 重新标识以触发非对称缩放+透明度转场，圆环 trim 每拍线性动画，另一圈独立圆环负责冲击波。"
        ),
        apis: ["task(id:)", "transition(.asymmetric)", "id(_:)", "Circle().trim", "withTransaction"],
        tags: ["countdown", "timer", "ring", "start", "倒计时", "计时器", "圆环", "出发"],
        params: [
            .slider("step", L("Beat length", "节拍时长"), 0.5...1.5, default: 0.9, unit: "s"),
            .slider("from", L("Count from", "起始数字"), 3...5, default: 3, step: 1, decimals: 0),
            .toggle("shockwave", L("Shockwave", "冲击波"), default: true),
        ]
    ) { ctx in
        SportCountdownDemo(ctx: ctx)
    }
}

private struct SportCountdownDemo: View {
    let ctx: DemoContext
    /// nil = idle, > 0 = counting, 0 = GO.
    @State private var count: Int?
    @State private var ring: CGFloat = 1
    @State private var waveScale: CGFloat = 1
    @State private var waveOpacity: Double = 0
    @State private var runID = 0
    /// Set when autoplay or the detail intro starts the run, so the simulated countdown stays silent.
    @State private var silentRun = false

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap the card to start the countdown", "点击卡片开始倒计时"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) {
            guard runID > 0 else { return }
            await run()
        }
        .autoplay(ctx.isPreview, every: Double(ctx.int("from")) * ctx["step"] + 3.0, delay: 0.6) { start() }
    }

    private var card: some View {
        VStack(spacing: 16) {
            SportEyebrowRow(title: L("Start gate", "出发门")(ctx.language), symbol: "flag.checkered", trailing: "Nordkette")
            ZStack {
                CountdownRing(progress: ring, isGo: count == 0)
                Circle()
                    .stroke(Signature.accent, lineWidth: 3)
                    .scaleEffect(waveScale)
                    .opacity(waveOpacity)
                CountdownLabel(count: count, language: ctx.language)
            }
            .frame(width: 170, height: 170)
        }
        .padding(20)
        .frame(width: 272)
        .signatureCard()
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture { start() }
    }

    private func start() {
        guard count == nil else { return }
        silentRun = Haptics.isMuted
        runID += 1
    }

    private func run() async {
        let step = ctx["step"]
        let from = max(ctx.int("from"), 1)
        let muted = ctx.isPreview || silentRun
        for n in stride(from: from, through: 1, by: -1) {
            guard !Task.isCancelled else { return }
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { ring = 1 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { count = n }
            if !muted { Haptics.tap(.medium) }
            try? await Task.sleep(for: .milliseconds(40))
            withAnimation(.linear(duration: step - 0.04)) { ring = 0 }
            try? await Task.sleep(for: .seconds(step - 0.04))
        }
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
            count = 0
            ring = 1
        }
        if ctx.bool("shockwave") {
            waveScale = 1
            waveOpacity = 0.9
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(.easeOut(duration: 0.9)) {
                waveScale = 1.9
                waveOpacity = 0
            }
        }
        if !muted { Haptics.success() }
        try? await Task.sleep(for: .seconds(1.6))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { count = nil }
    }
}

private struct CountdownRing: View {
    let progress: CGFloat
    let isGo: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isGo ? AnyShapeStyle(Signature.lime) : AnyShapeStyle(Signature.accentGradient),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (isGo ? Signature.lime : Signature.accent).opacity(0.6), radius: 10)
        }
    }
}

private struct CountdownLabel: View {
    let count: Int?
    let language: AppLanguage

    var body: some View {
        ZStack {
            if let count {
                Text(verbatim: count == 0 ? "GO" : String(count))
                    .font(Signature.number(count == 0 ? 58 : 76))
                    .foregroundStyle(count == 0 ? Signature.lime : Color.white)
                    .id(count)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.8).combined(with: .opacity),
                        removal: .scale(scale: 0.4).combined(with: .opacity)
                    ))
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Signature.accent)
                    Text(L("Tap to start", "点击开始"), language)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Signature.textSecondary)
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
    }
}
