import SwiftUI

extension Effect {
    static let showcaseSlideToStart = Effect(
        id: "showcase.slide-to-start",
        category: .showcase,
        interaction: .gesture,
        name: L("Slide to Start", "滑动开始"),
        summary: L("A ready-to-ride pill: drag the knob, the track floods orange and turns into a live run timer.", "“准备出发”滑块：拖动圆钮，轨道被橙色填满，随即展开为实时计时状态。"),
        prompt: L(
            "A dark 64 pt capsule track reads \"Start Run\" with a slow shimmer sweeping across it, and a white 52 pt knob carries an arrow. As the knob is dragged, an orange gradient fill stretches behind it, the label fades out at 1.6× the drag progress, and a selection haptic ticks at evenly spaced detents. Past the commit threshold the knob locks to the end (spring 0.35 s, damping 0.8) and its arrow symbol-replaces into a checkmark with a success haptic; 0.7 s later the whole pill floods orange, grows to 103% and reveals a pulsing live dot, \"Run started\" and a ticking timer, while the knob turns into a stop button. While dragging, pulling beyond either end of the track meets rubber-band resistance (at most ~24 pt before the start, ~16 pt past the end); letting go short of the threshold springs the knob home with a small bounce. Physical, decisive and rewarding.",
            "深色 64pt 胶囊轨道上写着“开始滑行”，文字上有一道缓慢扫过的高光；左侧是 52pt 白色圆钮，内含箭头。拖动圆钮时，橙色渐变填充紧随其后拉伸，文字按 1.6 倍拖动进度淡出，每经过一个等距刻度触发一次选择触感。越过触发阈值后，圆钮吸附到末端（弹簧 0.35 秒、阻尼 0.8），箭头以符号替换动画变为对勾并伴随成功触感；0.7 秒后整条胶囊被橙色填满并放大到 103%，展开为脉冲直播点、“已开始滑行”与跳动的计时器，圆钮同时变为停止按钮。拖动时若拉出轨道两端会遇到橡皮筋阻尼（起点外最多约 24pt，终点外约 16pt）；未过阈值就松手，圆钮会带轻微回弹地弹回原位。手感扎实、果断，又有完成的满足感。"
        ),
        implementation: L(
            "A DragGesture drives the knob offset (rubber-banded outside the track) and the width of a leading gradient capsule; a TimelineView sweeps a masked shimmer over the label, and Text(_:style: .timer) renders the live run time.",
            "DragGesture 驱动圆钮位移（超出轨道部分做橡皮筋阻尼）与前置渐变胶囊的宽度；TimelineView 让遮罩高光扫过文字，Text(_:style: .timer) 显示实时计时。"
        ),
        apis: ["DragGesture", "contentTransition(.symbolEffect(.replace))", "Text(_:style: .timer)", "TimelineView", "mask"],
        tags: ["slide to unlock", "slider", "swipe button", "滑动解锁", "滑块按钮", "开始", "计时", "haptics"],
        params: [
            .slider("threshold", L("Commit threshold", "触发阈值"), 0.5...1.0, default: 0.85),
            .slider("damping", L("Snap-back damping", "回弹阻尼"), 0.3...1.0, default: 0.55),
            .slider("ticks", L("Haptic detents", "触感刻度数"), 3...16, default: 8, step: 1, decimals: 0),
        ]
    ) { ctx in
        SportSlideDemo(ctx: ctx)
    }
}

private struct SportSlideDemo: View {
    let ctx: DemoContext
    @State private var dragX: CGFloat = 0
    @State private var completed = false
    @State private var expanded = false
    @State private var startDate = Date()
    @State private var lastTick = 0
    @GestureState private var dragging = false

    private let trackWidth: CGFloat = 272
    private let trackHeight: CGFloat = 64
    private let knob: CGFloat = 52

    private var inset: CGFloat { (trackHeight - knob) / 2 }
    private var maxX: CGFloat { trackWidth - knob - inset * 2 }
    private var progress: CGFloat { (dragX / maxX).clamped(to: 0...1) }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                VStack(alignment: .leading, spacing: 18) {
                    SportSlideHeader(expanded: expanded, language: ctx.language)
                    track
                }
                .padding(18)
                .frame(maxWidth: trackWidth + 36)
                .signatureCard()
                .padding(.horizontal, 16)
                Spacer()
                DemoHint(text: L("Drag the knob to the end", "把圆钮拖到最右端"), ctx: ctx)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 6.5, delay: 0.5) { simulate() }
    }

    private var track: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay(Capsule().strokeBorder(Signature.hairline))
            Capsule()
                .fill(Signature.accentGradient)
                .frame(width: expanded ? trackWidth : max(trackHeight + dragX, 44))
                .opacity(expanded ? 1 : 0.35 + 0.65 * Double(progress))
            SportShimmerLabel(text: L("Start Run", "开始滑行")(ctx.language))
                .frame(maxWidth: .infinity)
                .padding(.leading, knob)
                .opacity(expanded ? 0 : max(0, 1 - Double(progress) * 1.6))
            SportRunningContent(startDate: startDate, language: ctx.language)
                .padding(.leading, 20)
                .padding(.trailing, knob + inset * 2)
                .opacity(expanded ? 1 : 0)
                .offset(x: expanded ? 0 : -16)
            knobView
        }
        .frame(width: trackWidth, height: trackHeight)
        .scaleEffect(expanded ? 1.03 : 1)
    }

    private var knobView: some View {
        let symbol = expanded ? "stop.fill" : (completed ? "checkmark" : "arrow.right")
        return Circle()
            .fill(Color.white)
            .frame(width: knob, height: knob)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Signature.accentHot)
                    .contentTransition(.symbolEffect(.replace))
            }
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
            .scaleEffect(dragging && !completed ? 1.07 : (expanded ? 0.86 : 1))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragging)
            .offset(x: inset + dragX)
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragging) { _, state, _ in state = true }
            .onChanged { value in
                guard !completed else { return }
                let raw = value.translation.width
                if raw < 0 {
                    dragX = rubberBand(raw, limit: 24)
                } else if raw > maxX {
                    dragX = maxX + rubberBand(raw - maxX, limit: 16)
                } else {
                    dragX = raw
                }
                let tick = Int((progress * CGFloat(max(ctx.int("ticks"), 1))).rounded(.down))
                if tick != lastTick {
                    lastTick = tick
                    if !ctx.isPreview { Haptics.selection() }
                }
            }
            .onEnded { value in
                if expanded {
                    if abs(value.translation.width) < 10 { reset() }
                    return
                }
                guard !completed else { return }
                if progress >= ctx.cg("threshold") {
                    complete()
                } else {
                    springBack()
                }
            }
    }

    private func springBack() {
        withAnimation(.spring(response: 0.5, dampingFraction: ctx["damping"])) { dragX = 0 }
        lastTick = 0
        if !ctx.isPreview { Haptics.tap(.soft) }
    }

    private func complete() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            dragX = maxX
            completed = true
        }
        if !ctx.isPreview { Haptics.success() }
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            guard completed else { return }
            startDate = Date()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { expanded = true }
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            expanded = false
            completed = false
            dragX = 0
        }
        lastTick = 0
        if !ctx.isPreview { Haptics.tap(.medium) }
    }

    private func simulate() {
        Task {
            reset()
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(.easeInOut(duration: 0.55)) { dragX = maxX * 0.45 }
            try? await Task.sleep(for: .seconds(0.65))
            withAnimation(.spring(response: 0.5, dampingFraction: ctx["damping"])) { dragX = 0 }
            try? await Task.sleep(for: .seconds(0.9))
            withAnimation(.easeIn(duration: 0.7)) { dragX = maxX }
            try? await Task.sleep(for: .seconds(0.7))
            complete()
        }
    }
}

private struct SportSlideHeader: View {
    let expanded: Bool
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(expanded ? L("On the run", "滑行中") : L("Ready to ride", "准备出发"), language)
                    .signatureEyebrow()
                    .contentTransition(.opacity)
                HStack(spacing: 6) {
                    Text(verbatim: "Nordkette")
                    Text(verbatim: "·").foregroundStyle(Signature.textSecondary)
                    Text(verbatim: "46 cm").foregroundStyle(Signature.accent)
                }
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            }
            Spacer(minLength: 0)
            Image(systemName: "figure.skiing.downhill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .symbolEffect(.bounce, value: expanded)
        }
    }
}

private struct SportRunningContent: View {
    let startDate: Date
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 8) {
            SportLiveDot(color: .white, size: 7)
            VStack(alignment: .leading, spacing: 0) {
                Text(L("Run started", "已开始滑行"), language)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                Text(startDate, style: .timer)
                    .font(Signature.number(20))
                    .foregroundStyle(Color.white)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Label with a soft highlight sweeping across it, like the classic slide-to-unlock.
private struct SportShimmerLabel: View {
    let text: String

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = CGFloat(t.truncatingRemainder(dividingBy: 2.2) / 2.2)
            label
                .foregroundStyle(Signature.textSecondary)
                .overlay {
                    label
                        .foregroundStyle(Color.white)
                        .mask {
                            LinearGradient(colors: [.clear, .white, .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 56)
                                .offset(x: phase * 240 - 120)
                        }
                }
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            Text(text)
            Image(systemName: "chevron.right.2")
        }
        .font(.system(size: 16, weight: .semibold, design: .rounded))
    }
}
