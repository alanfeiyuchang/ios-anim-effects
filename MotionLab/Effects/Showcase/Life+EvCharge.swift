import SwiftUI

extension Effect {
    static let showcaseEvCharge = Effect(
        id: "showcase.ev-charge",
        category: .showcase,
        interaction: .loop,
        name: L("EV Charging Live", "充电实况卡片"),
        summary: L(
            "A live charging card: the percentage ticks up, power flickers and chevrons stream through the battery.",
            "实时充电卡片：电量百分比逐格上涨，功率微微跳动，箭头光带在电池里流动。"
        ),
        prompt: L(
            "A dark glossy \"Charging · Bay 4\" widget. A 46 pt rounded percentage ticks up one point every 0.8 s, while three smaller stats — power in kW, minutes left and energy added — refresh on the same beat, the power jittering between 148 and 156 kW. Beneath them a 240 × 34 pt battery fills to the current level with an orange gradient on a smooth 0.6 s ease-out, and a row of faint chevrons streams rightward through the fill at 60 pt/s, masked to the charged part, so energy visibly flows in. Tapping pauses the session: the chevrons freeze, the fill dims and the eyebrow reads \"Paused\". At 100% the bar flashes lime, reads \"Charged\" and after 2 s restarts at 62%. Calm and alive.",
            "一张暗色光泽的“充电中 · 4 号桩”小组件。46pt 的圆体百分比每 0.8 秒通过数字滚动增加 1，下方三个小指标——功率（kW）、剩余分钟与已充电量——按同一节拍刷新，功率在 148 到 156 kW 之间轻微跳动。再下方是一块 240 × 34pt 的电池条，以 0.6 秒 ease-out 平滑填充到当前电量，填充为橙色渐变；一排淡淡的箭头以每秒 60pt 的速度在填充区域内向右流动（仅在已充部分可见），让能量“流进去”清晰可见。点击可暂停：箭头静止、填充变暗、眉标显示“已暂停”。到 100% 时电池条闪成青柠色并显示“已充满”，2 秒后从 62% 重新开始。冷静、专业又鲜活。"
        ),
        implementation: L(
            "A task(id:) loop advances the percentage and power every beat inside withAnimation, feeding numericText transitions and the bar width; a TimelineView offsets a repeating chevron row that is masked to the filled width, and pausing cancels the loop via the task id.",
            "task(id:) 循环每拍在 withAnimation 中推进电量与功率，驱动 numericText 过渡与电池宽度；TimelineView 让一排重复的箭头平移，并以已填充宽度作遮罩；暂停时通过改变 task id 取消循环。"
        ),
        apis: ["task(id:)", "contentTransition(.numericText)", "TimelineView", "mask(alignment:)", "LinearGradient"],
        tags: ["charging", "ev", "battery", "live", "充电", "电动车", "电池", "实时"],
        params: [
            .slider("beat", L("Update beat", "刷新节拍"), 0.3...1.5, default: 0.8, unit: "s"),
            .slider("flow", L("Chevron speed", "箭头流速"), 20...120, default: 60, decimals: 0, unit: "pt/s"),
            .toggle("chevrons", L("Energy chevrons", "能量箭头"), default: true),
        ]
    ) { ctx in
        LifeEvChargeDemo(ctx: ctx)
    }
}

private struct LifeEvChargeDemo: View {
    let ctx: DemoContext
    @State private var percent = 62
    @State private var power = 152
    @State private var paused = false
    @State private var charged = false

    private var zh: Bool { ctx.language == .zh }
    private let barSize = CGSize(width: 240, height: 34)

    private var minutesLeft: Int { max(0, (100 - percent) * 2 / 3) }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
                DemoHint(text: L("Tap the card to pause or resume", "点击卡片暂停或继续"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: paused) {
            guard !paused else { return }
            await run()
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(percent, format: .number)
                    .font(Signature.number(46))
                    .foregroundStyle(charged ? Signature.lime : Color.white)
                    .contentTransition(.numericText(value: Double(percent)))
                Text(verbatim: "%")
                    .font(Signature.number(20))
                    .foregroundStyle(Signature.textSecondary)
                Spacer(minLength: 0)
            }
            stats
            battery
        }
        .padding(18)
        .frame(width: barSize.width + 44)
        .signatureCard()
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture { togglePause() }
    }

    private var header: some View {
        HStack(spacing: 6) {
            if paused {
                Image(systemName: "pause.fill")
                    .foregroundStyle(Signature.textSecondary)
                    .frame(width: 24, height: 24)
            } else {
                SportLiveDot(color: charged ? Signature.lime : Signature.accent)
            }
            Text(eyebrow)
                .signatureEyebrow()
                .contentTransition(.opacity)
            Spacer(minLength: 0)
            Image(systemName: "bolt.car.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Signature.accent)
        }
    }

    private var eyebrow: String {
        if charged { return zh ? "已充满 · 4 号桩" : "Charged · Bay 4" }
        if paused { return zh ? "已暂停 · 4 号桩" : "Paused · Bay 4" }
        return zh ? "充电中 · 4 号桩" : "Charging · Bay 4"
    }

    private var stats: some View {
        HStack(spacing: 22) {
            stat(value: paused || charged ? 0 : power, unit: "kW", label: zh ? "功率" : "Power")
            stat(value: minutesLeft, unit: zh ? "分钟" : "min", label: zh ? "剩余" : "Left")
            stat(value: (percent - 62) * 3 / 4 + 4, unit: "kWh", label: zh ? "已充" : "Added")
        }
    }

    private func stat(value: Int, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .signatureEyebrow()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value, format: .number)
                    .font(Signature.number(18))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(value)))
                Text(unit)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Signature.textSecondary)
            }
        }
    }

    private var battery: some View {
        let fillWidth = barSize.width * CGFloat(percent) / 100
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return HStack(spacing: 3) {
            ZStack(alignment: .leading) {
                shape.fill(Color.white.opacity(0.07))
                ZStack(alignment: .leading) {
                    shape.fill(charged ? AnyShapeStyle(Signature.lime) : AnyShapeStyle(Signature.accentGradient))
                    if ctx.bool("chevrons") {
                        LifeChargeChevrons(speed: ctx["flow"], paused: paused || charged, preview: ctx.isPreview, size: barSize)
                    }
                }
                .frame(width: barSize.width)
                .mask(alignment: .leading) {
                    shape.frame(width: fillWidth)
                }
                .opacity(paused ? 0.45 : 1)
                .shadow(color: (charged ? Signature.lime : Signature.accent).opacity(0.45), radius: 8)
            }
            .frame(width: barSize.width, height: barSize.height)
            .overlay(shape.strokeBorder(Signature.hairline, lineWidth: 1))
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 4, height: 12)
        }
        .animation(.easeOut(duration: 0.6), value: percent)
        .animation(.smooth(duration: 0.3), value: paused)
        .animation(.smooth(duration: 0.3), value: charged)
    }

    private func togglePause() {
        guard !charged else { return }
        Haptics.tap(.medium)
        withAnimation(.smooth(duration: 0.3)) { paused.toggle() }
    }

    private func run() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(ctx["beat"]))
            guard !Task.isCancelled else { return }
            if percent >= 100 {
                withAnimation(.smooth(duration: 0.3)) { charged = true }
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.5)) {
                    charged = false
                    percent = 62
                }
                continue
            }
            let jitter = Int(sportHash(Double(percent)) * 8)
            withAnimation(.snappy(duration: 0.35)) {
                percent += 1
                power = 148 + jitter
            }
        }
    }
}

/// A row of chevrons scrolling right forever; frozen when paused.
private struct LifeChargeChevrons: View {
    let speed: Double
    let paused: Bool
    let preview: Bool
    let size: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: paused)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let spacing: CGFloat = 22
            let shift = CGFloat((t * speed).truncatingRemainder(dividingBy: Double(spacing)))
            HStack(spacing: 0) {
                ForEach(0..<14, id: \.self) { _ in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .frame(width: spacing)
                }
            }
            .offset(x: shift - spacing)
            // A fixed frame keeps the wider chevron row from changing the bar's layout.
            .frame(width: size.width, height: size.height, alignment: .leading)
            .clipped()
        }
        .allowsHitTesting(false)
    }
}
