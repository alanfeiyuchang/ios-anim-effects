import SwiftUI

extension Effect {
    static let showcaseSleepTimeline = Effect(
        id: "showcase.sleep-timeline",
        category: .showcase,
        interaction: .gesture,
        name: L("Sleep Stages Timeline", "睡眠阶段时间轴"),
        summary: L(
            "Last night's hypnogram sweeps in left to right; scrub it to spotlight a stage and read the time.",
            "昨晚的睡眠阶段图从左到右扫出；拖动查看时间并高亮对应阶段。"
        ),
        prompt: L(
            "A dark sleep widget: a “7h 42m” headline that counts up, a small replay button, and a four-lane hypnogram (Awake, REM, Core, Deep) of rounded coloured blocks joined by thin connectors, with 23:10 · 03:00 · 06:52 below and a legend of per-stage totals with mini bars. On appear a soft-edged reveal with a glowing leading edge sweeps the chart left to right in ~1.4 s (ease-in-out), the headline counts up in 14 eased steps, and the legend bars grow from their leading edges 60 ms apart. Dragging across the chart drops a hairline cursor with a bubble (“02:14 · Deep”); blocks of other stages dim to ~40% on a spring (response 0.3 s, damping 0.8), the matching legend row brightens, and a selection haptic ticks whenever the stage under the finger changes. Lifting the finger releases the spotlight. Calm and precise.",
            "深色睡眠小组件：递增计数的“7 小时 42 分”标题、重播按钮，以及清醒、快速眼动、核心、深睡四泳道的阶段图，彩色圆角块由细线串起，下方是各阶段时长图例。出现时，一道带发光前沿的柔边揭示约 1.4 秒（缓入缓出）自左向右扫出全图，标题分 14 个缓出步进递增，图例条相隔 60 毫秒依次生长。横向拖动出现细游标与气泡（“02:14 · 深睡”），其他阶段以弹簧（响应 0.3 秒、阻尼 0.8）暗到约 40%，阶段每变一次触发选择触感；松手即解除。"
        ),
        implementation: L(
            "Blocks are positioned RoundedRectangles in a ZStack plus a connector Shape, revealed by an animated leading mask; a zero-distance DragGesture maps x to minutes and the stage under it drives per-block opacity with a spring and sensoryFeedback(.selection). The headline counts with task(id:) steps under numericText.",
            "色块是 ZStack 中按位置摆放的 RoundedRectangle，加上一个连接线 Shape，由带动画的前沿遮罩揭示；零距离 DragGesture 把横坐标换算为分钟，所在阶段通过弹簧驱动每个色块的透明度，并触发 sensoryFeedback(.selection)。标题由 task(id:) 分步递增并配合 numericText。"
        ),
        apis: ["mask(alignment:_:)", "DragGesture", "sensoryFeedback", "contentTransition(.numericText(value:))", "Shape"],
        tags: ["sleep", "health", "hypnogram", "timeline", "睡眠", "健康", "阶段", "时间轴"],
        params: [
            .slider("duration", L("Reveal duration", "揭示时长"), 0.5...3.0, default: 1.4, unit: "s"),
            .slider("dim", L("Spotlight dim", "高亮时其他阶段变暗"), 0...0.9, default: 0.6),
            .slider("response", L("Spotlight spring", "高亮弹簧响应"), 0.15...0.8, default: 0.3, unit: "s"),
        ]
    ) { ctx in
        LifeSleepDemo(ctx: ctx)
    }
}

// MARK: - Model

private enum LifeSleepStage: Int, CaseIterable {
    case awake, rem, core, deep

    var name: LocalizedText {
        switch self {
        case .awake: return L("Awake", "清醒")
        case .rem: return L("REM", "快速眼动")
        case .core: return L("Core", "核心")
        case .deep: return L("Deep", "深睡")
        }
    }

    var color: Color {
        switch self {
        case .awake: return Signature.accent
        case .rem: return Color(hex: 0x5AC8FA)
        case .core: return Color(hex: 0x4F7CFF)
        case .deep: return Color(hex: 0x8A5CFF)
        }
    }
}

private struct LifeSleepBlock {
    let stage: LifeSleepStage
    let start: Double
    let end: Double
}

private enum LifeSleepData {
    /// Minutes after 23:10; the night lasts 462 min (until 06:52).
    static let total: Double = 462
    static let startClock = 23 * 60 + 10

    static let blocks: [LifeSleepBlock] = [
        LifeSleepBlock(stage: .core, start: 0, end: 18),
        LifeSleepBlock(stage: .deep, start: 18, end: 62),
        LifeSleepBlock(stage: .core, start: 62, end: 98),
        LifeSleepBlock(stage: .rem, start: 98, end: 120),
        LifeSleepBlock(stage: .core, start: 120, end: 160),
        LifeSleepBlock(stage: .deep, start: 160, end: 190),
        LifeSleepBlock(stage: .core, start: 190, end: 232),
        LifeSleepBlock(stage: .rem, start: 232, end: 262),
        LifeSleepBlock(stage: .awake, start: 262, end: 268),
        LifeSleepBlock(stage: .core, start: 268, end: 318),
        LifeSleepBlock(stage: .rem, start: 318, end: 352),
        LifeSleepBlock(stage: .core, start: 352, end: 392),
        LifeSleepBlock(stage: .deep, start: 392, end: 404),
        LifeSleepBlock(stage: .core, start: 404, end: 430),
        LifeSleepBlock(stage: .rem, start: 430, end: 456),
        LifeSleepBlock(stage: .awake, start: 456, end: 462),
    ]

    static func minutes(in stage: LifeSleepStage) -> Double {
        blocks.filter { $0.stage == stage }.map { $0.end - $0.start }.reduce(0, +)
    }

    static func stage(at minute: Double) -> LifeSleepStage {
        blocks.first { minute >= $0.start && minute < $0.end }?.stage ?? .awake
    }

    static func clock(at minute: Double) -> String {
        let value = (startClock + Int(minute)) % 1440
        return String(format: "%02d:%02d", value / 60, value % 60)
    }

    static func duration(_ minutes: Double, _ language: AppLanguage) -> String {
        let m = Int(minutes.rounded())
        if language == .zh { return m >= 60 ? "\(m / 60) 小时 \(m % 60) 分" : "\(m) 分" }
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m)m"
    }
}

// MARK: - Demo

private struct LifeSleepDemo: View {
    let ctx: DemoContext
    @State private var reveal: CGFloat = 0
    @State private var counted: Double = 0
    @State private var scrub: Double?
    @State private var runID = 0
    @State private var step = 0
    /// Only a real finger on the chart ticks the selection haptic; the preview scrub stays silent.
    @State private var userScrubbing = false

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run `task`, so they show the fully revealed night.
        _reveal = State(initialValue: ctx.isStill ? 1 : 0)
        _counted = State(initialValue: ctx.isStill ? LifeSleepData.total : 0)
    }

    private static let chartSize = CGSize(width: 264, height: 108)
    private static let previewScrubs: [Double?] = [0.12, 0.3, 0.55, nil, 0.87, nil]

    private var focusStage: LifeSleepStage? {
        scrub.map { LifeSleepData.stage(at: $0 * LifeSleepData.total) }
    }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
                DemoHint(text: L("Drag across the chart", "在图上横向拖动"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: runID) { await play() }
        .sensoryFeedback(.selection, trigger: focusStage) { old, new in
            userScrubbing && new != nil && old != new
        }
        // The reveal already plays on appear; the detail stage must not start a preview scrub that never clears.
        .autoplay(ctx.isPreview, every: 1.1, delay: 2.0, intro: false) { previewTick() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            chart
            legend
        }
        .padding(18)
        .frame(width: 300)
        .signatureCard()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                SportEyebrowRow(title: L("Sleep · last night", "睡眠 · 昨晚")(ctx.language), symbol: "bed.double.fill")
                Text(LifeSleepData.duration(counted, ctx.language))
                    .font(Signature.number(26))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: counted))
            }
            Spacer(minLength: 0)
            Button {
                if !ctx.isPreview { Haptics.tap() }
                runID += 1
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Signature.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
            .buttonStyle(SportPressStyle(scale: 0.88, dim: 0.05))
            .accessibilityLabel(Text(L("Replay", "重播"), ctx.language))
        }
    }

    private var chart: some View {
        let size = Self.chartSize
        let lane = size.height / 4
        return VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                // Faint lane guides.
                ForEach(LifeSleepStage.allCases, id: \.self) { stage in
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: size.width, height: 1)
                        .offset(y: lane * (CGFloat(stage.rawValue) + 0.5))
                }
                LifeSleepConnectors(lane: lane, width: size.width)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                ForEach(LifeSleepData.blocks.indices, id: \.self) { index in
                    block(LifeSleepData.blocks[index], lane: lane, width: size.width)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .mask(alignment: .leading) {
                LinearGradient(
                    stops: [.init(color: .black, location: 0.9), .init(color: .clear, location: 1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: size.width * reveal * 1.1)
            }
            .overlay(alignment: .leading) { sweepEdge(size) }
            .overlay(alignment: .topLeading) { cursor(size) }
            .contentShape(Rectangle())
            .gesture(scrubGesture)
            HStack {
                Text(verbatim: "23:10")
                Spacer(minLength: 0)
                Text(verbatim: "03:00")
                Spacer(minLength: 0)
                Text(verbatim: "06:52")
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(Signature.textSecondary)
        }
        .padding(.top, 22)
    }

    private func block(_ block: LifeSleepBlock, lane: CGFloat, width: CGFloat) -> some View {
        let x = width * CGFloat(block.start / LifeSleepData.total)
        let w = max(width * CGFloat((block.end - block.start) / LifeSleepData.total), 3)
        let dimmed = focusStage != nil && focusStage != block.stage
        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(block.stage.color.gradient)
            .frame(width: w, height: lane * 0.6)
            .shadow(color: block.stage.color.opacity(dimmed ? 0 : 0.45), radius: 4)
            .opacity(dimmed ? 1 - ctx["dim"] : 1)
            .animation(.spring(response: ctx["response"], dampingFraction: 0.8), value: dimmed)
            .offset(x: x, y: lane * (CGFloat(block.stage.rawValue) + 0.2))
    }

    /// A soft glowing line riding the reveal's leading edge while it sweeps.
    private func sweepEdge(_ size: CGSize) -> some View {
        Capsule()
            .fill(Color.white)
            .frame(width: 2, height: size.height)
            .shadow(color: Color.white.opacity(0.8), radius: 6)
            .offset(x: size.width * reveal - 1)
            .opacity(reveal > 0.01 && reveal < 0.99 ? 0.7 : 0)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func cursor(_ size: CGSize) -> some View {
        if let scrub, let stage = focusStage {
            let x = size.width * CGFloat(scrub)
            let label = LifeSleepData.clock(at: scrub * LifeSleepData.total) + " · " + stage.name(ctx.language)
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 1, height: size.height + 6)
                    .offset(x: x, y: -3)
                Text(verbatim: label)
                    .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(stage.color))
                    .fixedSize()
                    .frame(width: 110)
                    .offset(x: min(max(x - 55, -4), size.width - 106), y: -24)
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    private var legend: some View {
        HStack(spacing: 8) {
            ForEach(LifeSleepStage.allCases, id: \.self) { stage in
                let minutes = LifeSleepData.minutes(in: stage)
                let lit = focusStage == nil || focusStage == stage
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle().fill(stage.color).frame(width: 6, height: 6)
                        Text(stage.name, ctx.language)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
                    Text(LifeSleepData.duration(minutes, ctx.language))
                        .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(stage.color)
                                .scaleEffect(x: reveal > 0.5 ? CGFloat(minutes / LifeSleepData.total) * 1.6 : 0.001, anchor: .leading)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8).delay(Double(stage.rawValue) * 0.06),
                                    value: reveal > 0.5
                                )
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(lit ? 1 : 0.45)
                .animation(.easeOut(duration: 0.2), value: lit)
            }
        }
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                userScrubbing = true
                let fraction = Double(value.location.x / Self.chartSize.width).clamped(to: 0...0.999)
                if scrub == nil {
                    withAnimation(.easeOut(duration: 0.15)) { scrub = fraction }
                } else {
                    scrub = fraction
                }
            }
            .onEnded { _ in
                userScrubbing = false
                withAnimation(.easeOut(duration: 0.2)) { scrub = nil }
            }
    }

    private func play() async {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) {
            reveal = 0
            counted = 0
            scrub = nil
        }
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        let duration = ctx["duration"]
        withAnimation(.easeInOut(duration: duration)) { reveal = 1 }
        let steps = 14
        for index in 1...steps {
            guard !Task.isCancelled else { return }
            let t = Double(index) / Double(steps)
            let eased = 1 - pow(1 - t, 3)
            withAnimation(.snappy(duration: 0.2)) { counted = LifeSleepData.total * eased }
            try? await Task.sleep(for: .seconds(duration / Double(steps)))
        }
    }

    private func previewTick() {
        let next = Self.previewScrubs[step % Self.previewScrubs.count]
        step += 1
        withAnimation(.smooth(duration: 0.5)) { scrub = next }
    }
}

/// Thin vertical links from one stage block to the next, like a stepped hypnogram.
private struct LifeSleepConnectors: Shape {
    let lane: CGFloat
    let width: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let blocks = LifeSleepData.blocks
        guard blocks.count > 1 else { return path }
        for index in 1..<blocks.count {
            let previous = blocks[index - 1]
            let current = blocks[index]
            let x = width * CGFloat(current.start / LifeSleepData.total)
            let y0 = lane * (CGFloat(previous.stage.rawValue) + 0.5)
            let y1 = lane * (CGFloat(current.stage.rawValue) + 0.5)
            path.move(to: CGPoint(x: x, y: y0))
            path.addLine(to: CGPoint(x: x, y: y1))
        }
        return path
    }
}
