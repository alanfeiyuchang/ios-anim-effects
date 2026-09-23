import SwiftUI

extension Effect {
    static let showcaseRunSummary = Effect(
        id: "showcase.run-summary",
        category: .showcase,
        interaction: .tap,
        name: L("Run Summary Bento", "滑行总结便当格"),
        summary: L("Stat tiles fly in from blur one after another and their numbers count up as they land.", "数据方块依次从模糊中飞入落位，数字随落地同步递增。"),
        prompt: L(
            "A day-summary bento of dark glossy tiles: a wide DISTANCE tile with a mini bar sparkline, a RUNS tile, and a row of VERTICAL, TOP (km/h) and MINUTES tiles, one number highlighted in orange. On appear (or tap) the tiles assemble in reading order with a ~70 ms stagger: each rises 26 pt from 82% scale, 8 pt blur and zero opacity into place on a spring (≈0.55 s response, damping 0.72, a touch of overshoot), and as it lands its numeral genuinely counts up from zero — 12 ease-out steps about 40 ms apart, each digit change rolling with a numeric text transition; the sparkline bars grow in their own quick 25 ms stagger. On replay everything collapses at once in 200 ms, then rebuilds. Rewarding, orderly and celebratory.",
            "深色便当格总结当日滑行：宽幅“距离”格含迷你柱状趋势，旁边“趟数”，下方“落差”“最高速”“分钟”，一个数字橙色高亮。出现（或点击）时，方块按阅读顺序以约 70 毫秒错峰组装：每块从 82% 缩放、8pt 模糊、全透明上移 26pt 落位，弹簧响应约 0.55 秒、阻尼 0.72，略带过冲；落地时数字真正从零递增，约 12 个缓出步进、每步约 40 毫秒；迷你柱以 25 毫秒错峰长高。重播时所有方块 200 毫秒内同时收起再重组。有奖励感。"
        ),
        implementation: L(
            "Each tile reads one `assembled` flag and carries its own .animation(value:) with a spring delayed by its index; each numeral is a small view whose task(id:) waits for that same delay, then steps its value to the target with eased increments under numericText.",
            "每个方块读取同一个 assembled 状态，并各自带有按序号延迟的弹簧 .animation(value:)；每个数字是一个小视图，其 task(id:) 等待相同延迟后，以缓出步进把数值递增到目标值，并配合 numericText 滚动。"
        ),
        apis: ["animation(_:value:)", "spring(response:dampingFraction:).delay", "blur(radius:)", "contentTransition(.numericText(value:))", "task(id:)"],
        tags: ["bento", "stagger", "dashboard", "summary", "便当格", "错峰", "仪表盘", "数据总结"],
        params: [
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.2, default: 0.07, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.0, default: 0.55, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.72),
        ]
    ) { ctx in
        SportRunSummaryDemo(ctx: ctx)
    }
}

/// Everything a single tile needs to choreograph its own entrance.
private struct BentoMotion {
    let assembled: Bool
    let stagger: Double
    let response: Double
    let damping: Double
    /// Rendering a still snapshot: numbers start at their targets because `task` never runs.
    var still: Bool = false

    func animation(_ index: Int) -> Animation {
        if assembled {
            return .spring(response: response, dampingFraction: damping).delay(Double(index) * stagger)
        }
        return .easeIn(duration: 0.2)
    }

    /// When a tile's spring has mostly settled, so its number starts counting as it lands.
    func landingDelay(_ index: Int) -> Double {
        Double(index) * stagger + response * 0.35
    }
}

/// A numeral that really counts: after `delay` it steps from 0 to `target` in eased increments,
/// each rolled with numericText. Dropping the target to 0 clears it at once.
private struct BentoCountUp: View {
    let target: Double
    let decimals: Int
    let delay: Double
    @State private var shown: Double

    init(target: Double, decimals: Int, delay: Double, still: Bool = false) {
        self.target = target
        self.decimals = decimals
        self.delay = delay
        _shown = State(initialValue: still ? target : 0)
    }

    var body: some View {
        Text(verbatim: decimals == 0 ? "\(Int(shown.rounded()))" : String(format: "%.\(decimals)f", shown))
            .contentTransition(.numericText(value: shown))
            .task(id: target) { await count() }
    }

    private func count() async {
        guard target > 0 else {
            withAnimation(.easeIn(duration: 0.2)) { shown = 0 }
            return
        }
        try? await Task.sleep(for: .seconds(delay))
        let steps = 12
        for step in 1...steps {
            guard !Task.isCancelled else { return }
            let t = Double(step) / Double(steps)
            let eased = 1 - pow(1 - t, 3)
            withAnimation(.snappy(duration: 0.16)) { shown = target * eased }
            try? await Task.sleep(for: .milliseconds(40))
        }
    }
}

private struct BentoEntrance: ViewModifier {
    let index: Int
    let motion: BentoMotion

    func body(content: Content) -> some View {
        let on = motion.assembled
        return content
            .opacity(on ? 1 : 0)
            .scaleEffect(on ? 1 : 0.82)
            .offset(y: on ? 0 : 26)
            .blur(radius: on ? 0 : 8)
            .animation(motion.animation(index), value: on)
    }
}

private struct SportRunSummaryDemo: View {
    let ctx: DemoContext
    @State private var assembled = false
    @State private var runID = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run `task`, so they show the assembled bento with final numbers.
        _assembled = State(initialValue: ctx.isStill)
    }

    private var motion: BentoMotion {
        BentoMotion(assembled: assembled, stagger: ctx["stagger"], response: ctx["response"], damping: ctx["damping"], still: ctx.isStill)
    }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                bento
                    .contentShape(Rectangle())
                    .onTapGesture { runID += 1 }
                Spacer()
                DemoHint(text: L("Tap to rebuild", "点击重新组装"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) { await replay() }
        // The bento already assembles on appear, so the detail stage skips its one-shot intro replay.
        .autoplay(ctx.isPreview, every: 3.8, delay: 3.8, intro: false) { runID += 1 }
    }

    private var bento: some View {
        let lang = ctx.language
        let on = assembled
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L("Today · Nordkette", "今日 · Nordkette"), lang)
                    .signatureEyebrow()
                Spacer(minLength: 0)
                Text(verbatim: "PR")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Signature.lime))
            }
            .modifier(BentoEntrance(index: 0, motion: motion))
            HStack(spacing: 8) {
                BentoDistanceTile(assembled: on, motion: motion, language: lang)
                    .frame(width: 196)
                    .modifier(BentoEntrance(index: 1, motion: motion))
                BentoStatTile(title: L("Runs", "趟数")(lang), value: on ? 14 : 0, unit: "", accent: false, motion: motion, index: 2)
            }
            HStack(spacing: 8) {
                BentoStatTile(title: L("Vertical", "落差")(lang), value: on ? 3120 : 0, unit: "m", accent: false, motion: motion, index: 3)
                BentoStatTile(title: L("Top", "最高速")(lang), value: on ? 50 : 0, unit: "km/h", accent: true, motion: motion, index: 4)
                BentoStatTile(title: L("Minutes", "分钟")(lang), value: on ? 222 : 0, unit: "", accent: false, motion: motion, index: 5)
            }
        }
        .frame(width: 298)
    }

    private func replay() async {
        let silent = ctx.isPreview || runID == 0
        if assembled {
            assembled = false
            try? await Task.sleep(for: .milliseconds(320))
        } else {
            try? await Task.sleep(for: .milliseconds(150))
        }
        guard !Task.isCancelled else { return }
        assembled = true
        if !silent { Haptics.tap(.soft) }
    }
}

private struct BentoStatTile: View {
    let title: String
    let value: Int
    let unit: String
    let accent: Bool
    let motion: BentoMotion
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .signatureEyebrow()
                .lineLimit(1)
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                BentoCountUp(target: Double(value), decimals: 0, delay: motion.landingDelay(index), still: motion.still)
                    .font(Signature.number(22))
                    .foregroundStyle(accent ? Signature.accent : Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Signature.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 86)
        .signatureCard(cornerRadius: 20)
        .modifier(BentoEntrance(index: index, motion: motion))
    }
}

private struct BentoDistanceTile: View {
    let assembled: Bool
    let motion: BentoMotion
    let language: AppLanguage

    private static let bars: [CGFloat] = [0.35, 0.6, 0.45, 0.8, 0.55, 1.0, 0.7, 0.5, 0.85, 0.65]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Distance", "距离"), language)
                    .signatureEyebrow()
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    BentoCountUp(target: assembled ? 24.6 : 0, decimals: 1, delay: motion.landingDelay(1), still: motion.still)
                        .font(Signature.number(30))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(verbatim: "km")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Signature.textSecondary)
                        .fixedSize()
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            sparkline
        }
        .padding(12)
        .frame(height: 86)
        .signatureCard(cornerRadius: 20)
    }

    private var sparkline: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<Self.bars.count, id: \.self) { i in
                Capsule()
                    .fill(i == 5 ? AnyShapeStyle(Signature.accentGradient) : AnyShapeStyle(Color.white.opacity(0.2)))
                    .frame(width: 4, height: assembled ? 44 * Self.bars[i] : 3)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.6)
                            .delay(assembled ? motion.stagger + 0.15 + Double(i) * 0.025 : 0),
                        value: assembled
                    )
            }
        }
        .frame(height: 44, alignment: .bottom)
    }
}
