import SwiftUI

// MARK: - Progress fill button

extension Effect {
    static let loadingFillButton = Effect(
        id: "loading.fill-button",
        category: .loading,
        interaction: .tap,
        name: L("Progress Fill Button", "进度填充按钮"),
        summary: L("The button's own surface fills left to right, inverting the label as it passes.", "按钮表面自身从左到右填充，经过处的文字随之反色。"),
        prompt: L(
            "A 250 × 56 pt outlined capsule reads 'Download · 1.2 GB' in indigo on a 10% indigo tint. On tap it presses to 96%, the label rolls to 'Downloading 0%', and a solid indigo → violet fill sweeps in from the left edge in irregular chunks (0.45 s smooth each). Where the fill passes, the label turns white — two stacked labels are clipped to either side of the fill edge, so letters split mid-glyph as it crosses. At 100% the capsule crossfades to green, the label rolls to 'Open', and the button bounces 1.0 → 1.05 → 1.0 with a success haptic. Tap again to reset. Honest, legible, compact.",
            "一枚 250 × 56 pt 的描边胶囊，10% 靛蓝底色上写着靛蓝色的“下载 · 1.2 GB”。点击后按钮压到 96%，文字滚动为“正在下载 0%”，一层靛蓝 → 紫罗兰的实色填充从左边缘分段扫入（每段 0.45 秒平滑曲线）。填充经过处文字变白——上下叠放两层文字，分别裁切在填充边缘两侧，所以边缘经过时一个字母会被一分为二。到达 100% 时胶囊交叉淡变为绿色，文字滚动为“打开”，按钮在 1.0 → 1.05 → 1.0 间弹一下并伴随成功触感。再次点击重置。诚实、清晰、紧凑。"
        ),
        implementation: L(
            "A fill rectangle of width progress × 250 sits inside the clipped capsule; a white copy of the label is masked to the same width so it reads inverted over the fill.",
            "裁切后的胶囊内放一块宽度为 进度 × 250 的填充矩形；白色文字副本用同样宽度做遮罩，在填充上方呈现反色效果。"
        ),
        apis: ["mask(alignment:_:)", "contentTransition(.numericText)", "keyframeAnimator", "ButtonStyle"],
        tags: ["download", "fill", "button", "invert", "下载", "填充", "按钮", "反色"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.4...2.5, default: 1.0),
            .toggle("invert", L("Invert label", "文字反色"), default: true),
        ]
    ) { ctx in
        FillButtonDemo(ctx: ctx)
    }
}

private enum FillButtonState: Equatable {
    case idle
    case loading
    case done
}

private struct FillButtonDemo: View {
    let ctx: DemoContext
    @State private var state: FillButtonState = .idle
    @State private var progress: Double = 0
    @State private var pops = 0
    @State private var task: Task<Void, Never>?

    private let width: CGFloat = 250

    var body: some View {
        VStack(spacing: 22) {
            Button(action: tap) {
                face
            }
            .buttonStyle(FillPressStyle())
            .keyframeAnimator(initialValue: CGFloat(1), trigger: pops) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(1.05, duration: 0.14)
                    SpringKeyframe(1.0, duration: 0.45, spring: .bouncy)
                }
            }
            DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Only an idle button is tapped, so a slow download is never reset mid-way; previews
        // return to idle 1.5 s after finishing, so the next play follows within about a second.
        .autoplay(ctx.isPreview, every: 1.0, delay: 0.5) {
            if state == .idle { tap() }
        }
        .onDisappear {
            // @State survives navigation: never come back to a half-filled, frozen button.
            task?.cancel()
            task = nil
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) {
                state = .idle
                progress = 0
            }
        }
    }

    private var title: String {
        let zh = ctx.language == .zh
        switch state {
        case .idle: return zh ? "下载 · 1.2 GB" : "Download · 1.2 GB"
        case .loading: return (zh ? "正在下载 " : "Downloading ") + "\(Int((progress * 100).rounded()))%"
        case .done: return zh ? "打开" : "Open"
        }
    }

    private var face: some View {
        let fillWidth: CGFloat = width * CGFloat(progress)
        let done = state == .done
        return ZStack(alignment: .leading) {
            Capsule().fill(Palette.indigo.opacity(0.1))
            Rectangle()
                .fill(Palette.primary)
                .frame(width: fillWidth)
            // successStrong keeps the white "Open" label above 4.5:1.
            Capsule().fill(Palette.successStrong).opacity(done ? 1 : 0)
            label(color: done ? .white : Palette.indigo)
            label(color: .white)
                .mask(alignment: .leading) {
                    Rectangle().frame(width: ctx.bool("invert") ? fillWidth : 0)
                }
                .opacity(done ? 0 : 1)
        }
        .frame(width: width, height: 56)
        .clipShape(Capsule())
        .overlay { Capsule().strokeBorder(done ? Palette.green : Palette.indigo.opacity(0.5), lineWidth: 1.5) }
        .shadow(color: (done ? Palette.green : Palette.indigo).opacity(0.25), radius: 12, y: 6)
        .animation(.easeInOut(duration: 0.3), value: done)
    }

    private func label(color: Color) -> some View {
        Text(title)
            .font(.headline.monospacedDigit())
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .frame(width: width)
    }

    private func tap() {
        task?.cancel()
        if state != .idle {
            withAnimation(.smooth(duration: 0.4)) {
                state = .idle
                progress = 0
            }
            return
        }
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.smooth(duration: 0.3)) { state = .loading }
        let speed = ctx["speed"]
        // Captured now: false inside the silent intro/autoplay, so delayed feedback stays quiet too.
        let buzz: Bool = !ctx.isPreview && !Haptics.isMuted
        let loops: Bool = ctx.isPreview
        task = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            while progress < 1 {
                if Task.isCancelled { return }
                let step: Double = Double.random(in: 0.05...0.14) * speed
                withAnimation(.smooth(duration: 0.45)) { progress = min(1, progress + step) }
                try? await Task.sleep(for: .seconds(Double.random(in: 0.2...0.38)))
            }
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.35)) { state = .done }
            pops += 1
            if buzz { Haptics.success() }
            guard loops else { return }
            // Previews hold the finished state briefly, then reset for the next play.
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation(.smooth(duration: 0.4)) {
                state = .idle
                progress = 0
            }
        }
    }
}

private struct FillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Send → dots → sent

extension Effect {
    static let loadingDotsButton = Effect(
        id: "loading.dots-button",
        category: .loading,
        interaction: .tap,
        name: L("Send · Dots · Sent", "发送 · 跳点 · 已发送"),
        summary: L("The label rolls away, the pill tightens around bouncing dots, then 'Sent' rolls in.", "文字滚走，胶囊收紧包住跳动圆点，随后“已发送”滚入。"),
        prompt: L(
            "Under a short message composer, a 150 × 50 pt indigo pill reads 'Send' with a paper-plane glyph. On tap the label rolls up 18 pt while blurring 6 pt and fading, and the pill tightens to 96 pt on a spring (response 0.45 s, damping 0.7) around three white 8 pt dots that hop in a staggered wave (0.12 s apart, 0.6 s cycle). After the send completes the dots roll up and out the same way, the pill widens to 136 pt and turns green, and 'Sent ✓' rolls up from 18 pt below out of a blur, with a success haptic. After 1.4 s it rolls back to 'Send'. Conversational, springy, polite.",
            "在一段简短的消息输入框下方，一枚 150 × 50 pt 的靛蓝胶囊写着“发送”并带纸飞机图标。点击后文字向上滚走 18 pt，同时模糊 6 pt 并淡出；胶囊以弹簧（响应 0.45 秒、阻尼 0.7）收紧到 96 pt，包住三颗 8 pt 白色圆点，圆点以 0.12 秒间隔、0.6 秒周期错峰跳动。发送完成后圆点以同样方式向上滚出，胶囊加宽到 136 pt 并变为绿色，“已发送 ✓”从下方 18 pt 处由模糊中滚入，伴随成功触感。1.4 秒后滚回“发送”。像对话一样轻松、有弹性、礼貌。"
        ),
        implementation: L(
            "A phase enum switches three label layers that use asymmetric move + blur transitions; the pill width animates with a spring and the dots run on a TimelineView half-sine.",
            "阶段枚举切换三个标签层，各自使用非对称的位移 + 模糊转场；胶囊宽度用弹簧动画，圆点由 TimelineView 半正弦驱动。"
        ),
        apis: ["transition(.asymmetric(insertion:removal:))", "blur(radius:)", "TimelineView", "spring(response:dampingFraction:)"],
        tags: ["send", "dots", "label roll", "chat", "发送", "跳点", "文字滚动", "聊天"],
        params: [
            .slider("duration", L("Send time", "发送时长"), 0.6...3.0, default: 1.6, decimals: 1, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.7),
        ]
    ) { ctx in
        DotsButtonDemo(ctx: ctx)
    }
}

private enum DotsSendPhase: Equatable {
    case idle
    case sending
    case sent
}

private struct DotsButtonDemo: View {
    let ctx: DemoContext
    @State private var phase: DotsSendPhase = .idle
    @State private var token = 0
    @State private var task: Task<Void, Never>?

    private var rollIn: AnyTransition {
        AnyTransition.asymmetric(
            insertion: AnyTransition.offset(y: 18).combined(with: .opacity).combined(with: DotsBlurTransition.blurred),
            removal: AnyTransition.offset(y: -18).combined(with: .opacity).combined(with: DotsBlurTransition.blurred)
        )
    }

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 20) {
            composer(zh: zh)
            Button(action: send) {
                pill(zh: zh)
            }
            .buttonStyle(.plain)
            DemoHint(text: L("Tap Send", "点击发送"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 3.2, delay: 0.5) { send() }
        .onDisappear {
            task?.cancel()
            phase = .idle
        }
    }

    private func composer(zh: Bool) -> some View {
        Text(zh ? "周五的评审我们推到下午三点吧 🙌" : "Let's move Friday's review to 3 pm 🙌")
            .font(.subheadline)
            .frame(width: 250, alignment: .leading)
            .padding(14)
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke))
    }

    private func pill(zh: Bool) -> some View {
        let width: CGFloat = phase == .idle ? 150 : (phase == .sending ? 96 : 136)
        return ZStack {
            Capsule().fill(Palette.primary)
            Capsule().fill(Palette.successStrong).opacity(phase == .sent ? 1 : 0)
            switch phase {
            case .idle:
                Label(zh ? "发送" : "Send", systemImage: "paperplane.fill")
                    .transition(rollIn)
            case .sending:
                SendDots(preview: ctx.isPreview)
                    .transition(rollIn)
            case .sent:
                Label(zh ? "已发送" : "Sent", systemImage: "checkmark")
                    .transition(rollIn)
            }
        }
        .font(.headline)
        .foregroundStyle(.white)
        .frame(width: width, height: 50)
        .clipShape(Capsule())
        .shadow(color: (phase == .sent ? Palette.green : Palette.indigo).opacity(0.35), radius: 12, y: 6)
    }

    private func send() {
        guard phase == .idle else { return }
        let spring = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
        let wait = ctx["duration"]
        // Captured now: false inside the silent intro/autoplay, so delayed feedback stays quiet too.
        let buzz: Bool = !ctx.isPreview && !Haptics.isMuted
        token += 1
        let current = token
        if buzz { Haptics.tap(.medium) }
        withAnimation(spring) { phase = .sending }
        task?.cancel()
        task = Task { @MainActor in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled, token == current else { return }
            withAnimation(spring) { phase = .sent }
            if buzz { Haptics.success() }
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled, token == current else { return }
            withAnimation(spring) { phase = .idle }
        }
    }
}

private struct DotsBlurModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

private enum DotsBlurTransition {
    static var blurred: AnyTransition {
        AnyTransition.modifier(active: DotsBlurModifier(radius: 6), identity: DotsBlurModifier(radius: 0))
    }
}

private struct SendDots: View {
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t: Double = timeline.date.timeIntervalSinceReferenceDate / 0.6
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    let raw: Double = t - Double(index) * 0.2
                    let phase: Double = raw - floor(raw)
                    let lift: CGFloat = phase < 0.5 ? CGFloat(sin(phase * 2 * .pi)) : 0
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .offset(y: -5 * lift)
                        .opacity(0.6 + 0.4 * Double(lift))
                }
            }
        }
    }
}

// MARK: - Border trace button

extension Effect {
    static let loadingTraceButton = Effect(
        id: "loading.trace-button",
        category: .loading,
        interaction: .tap,
        name: L("Border Trace Button", "描边追光按钮"),
        summary: L("A comet of light laps the button's outline while it works, then closes the loop in green.", "处理中一道彗星光沿按钮轮廓绕行，完成时以绿色闭合整圈。"),
        prompt: L(
            "A 230 × 56 pt outlined capsule labeled 'Deploy' with a hairline border. On tap the label changes to 'Deploying…' and pulses between 55% and 100% opacity, while a comet — a 28%-long segment of the outline with a transparent tail and a bright sky → violet head, 3 pt wide and softly blurred beneath — laps the border once every 1.2 s. When the job finishes, a green trace sets off from the comet's head and runs on around the loop until the whole outline is green, over 0.5 s; the label rolls to 'Live' with a check, a faint green fill fades in, and a success haptic fires. Technical, focused, premium.",
            "一枚 230 × 56 pt 的描边胶囊按钮，细线边框，写着“部署”。点击后文字变为“正在部署…”并在 55% 与 100% 透明度间脉动；同时一道彗星光——占轮廓 28% 长度、尾部透明、头部为明亮的天蓝 → 紫罗兰、线宽 3 pt、下方带柔和模糊——每 1.2 秒沿边框绕行一圈。任务完成时，一道绿色描边从彗星头部出发继续绕行，在 0.5 秒内把整圈轮廓描成绿色；文字滚动为带对勾的“已上线”，淡淡的绿色底色浮现，并伴随成功触感。技术感、专注、高级。"
        ),
        implementation: L(
            "A TimelineView slides six fading slices of the Capsule outline (a Shape using trimmedPath that wraps across the seam); on completion an Animatable slice grows from the comet's head to a full green loop.",
            "TimelineView 沿胶囊轮廓滑动六段渐隐切片（用 trimmedPath 实现、可跨越接缝的 Shape）；完成时一段可动画的切片从彗星头部生长为完整的绿色闭环。"
        ),
        apis: ["TimelineView", "Path.trimmedPath(from:to:)", "Shape", "animatableData", "blur(radius:)"],
        tags: ["border", "trace", "comet", "deploy", "描边", "追光", "彗星", "部署"],
        params: [
            .slider("lap", L("Lap time", "绕行周期"), 0.5...3.0, default: 1.2, decimals: 1, unit: "s"),
            .slider("length", L("Comet length", "彗星长度"), 0.1...0.6, default: 0.28),
            .slider("duration", L("Job time", "任务时长"), 1...5, default: 2.6, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        TraceButtonDemo(ctx: ctx)
    }
}

private enum TracePhase: Equatable {
    case idle
    case working
    case done
}

private struct TraceButtonDemo: View {
    let ctx: DemoContext
    @State private var phase: TracePhase = .idle
    @State private var started = Date.distantPast
    @State private var closeFrom: Double = 0
    @State private var closed: Double = 0
    @State private var token = 0
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 22) {
            Button(action: tap) { face }
                .buttonStyle(.plain)
            DemoHint(text: L("Tap Deploy", "点击部署"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 3.4, delay: 0.5) { tap() }
        .onDisappear {
            task?.cancel()
            phase = .idle
            closed = 0
        }
    }

    private var face: some View {
        let zh = ctx.language == .zh
        let done = phase == .done
        return ZStack {
            Capsule().fill(Palette.green.opacity(done ? 0.12 : 0))
            Capsule().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            if phase == .working {
                TraceComet(started: started, lap: max(ctx["lap"], 0.2), length: ctx["length"], preview: ctx.isPreview)
                    .transition(.opacity)
            }
            // Its own 0.5 s curve: the 0.3 s modifier below would otherwise override the closing trace.
            TraceSlice(from: closeFrom, length: closed)
                .stroke(Palette.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .animation(.easeInOut(duration: 0.5), value: closed)
                .opacity(closed > 0.001 ? 1 : 0)
            labelView(zh: zh)
        }
        .frame(width: 230, height: 56)
        .contentShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    @ViewBuilder
    private func labelView(zh: Bool) -> some View {
        switch phase {
        case .idle:
            Text(zh ? "部署" : "Deploy")
                .font(.headline)
                .transition(.push(from: .bottom))
        case .working:
            Text(zh ? "正在部署…" : "Deploying…")
                .font(.headline)
                .foregroundStyle(.secondary)
                .phaseAnimator([false, true]) { content, dim in
                    content.opacity(dim ? 0.55 : 1)
                } animation: { _ in
                    .easeInOut(duration: 0.7)
                }
                .transition(.push(from: .bottom))
        case .done:
            Label(zh ? "已上线" : "Live", systemImage: "checkmark")
                .font(.headline)
                .foregroundStyle(Palette.green)
                .transition(.push(from: .bottom))
        }
    }

    private func tap() {
        if phase == .done {
            token += 1
            task?.cancel()
            withAnimation(.smooth(duration: 0.35)) {
                phase = .idle
                closed = 0
            }
            return
        }
        guard phase == .idle else { return }
        token += 1
        let current = token
        let live = !ctx.isPreview
        // Captured now: false inside the silent intro/autoplay, so delayed feedback stays quiet too.
        let buzz: Bool = live && !Haptics.isMuted
        if buzz { Haptics.tap(.medium) }
        started = .now
        closed = 0
        withAnimation(.smooth(duration: 0.3)) { phase = .working }
        let wait = ctx["duration"]
        let lap = max(ctx["lap"], 0.2)
        task?.cancel()
        task = Task { @MainActor in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled, token == current else { return }
            // Continue from where the comet's head currently is.
            let elapsed: Double = Date.now.timeIntervalSince(started)
            let head: Double = (elapsed / lap).truncatingRemainder(dividingBy: 1)
            closeFrom = head
            closed = 0
            withAnimation(.easeInOut(duration: 0.5)) {
                phase = .done
                closed = 1
            }
            if buzz { Haptics.success() }
            if !live {
                try? await Task.sleep(for: .seconds(2.2))
                guard !Task.isCancelled, token == current else { return }
                withAnimation(.smooth(duration: 0.35)) {
                    phase = .idle
                    closed = 0
                }
            }
        }
    }
}

private struct TraceComet: View {
    let started: Date
    let lap: Double
    let length: Double
    let preview: Bool

    private let colors: [Color] = [Palette.sky, Palette.sky, Palette.blue, Palette.indigo, Palette.violet, Palette.violet]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let elapsed: Double = timeline.date.timeIntervalSince(started)
            let head: Double = (elapsed / lap).truncatingRemainder(dividingBy: 1)
            ZStack {
                comet(head: head).blur(radius: 5).opacity(0.7)
                comet(head: head)
            }
        }
    }

    /// Six slices from a transparent tail to a bright head.
    private func comet(head: Double) -> some View {
        let slice: Double = length / 6
        return ZStack {
            ForEach(0..<6, id: \.self) { index in
                let start: Double = head - length + Double(index) * slice
                TraceSlice(from: start, length: slice + 0.002)
                    .stroke(colors[index].opacity(Double(index + 1) / 6), style: StrokeStyle(lineWidth: 3, lineCap: .butt))
            }
        }
    }
}

/// A stretch of the button's capsule outline that may wrap across the path's seam.
private struct TraceSlice: Shape {
    var from: Double
    var length: Double

    var animatableData: Double {
        get { length }
        set { length = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let base = Capsule().path(in: rect.insetBy(dx: 1.5, dy: 1.5))
        var start: Double = from - floor(from)
        if start >= 1 { start = 0 }
        let end: Double = start + min(max(length, 0), 1)
        var path = base.trimmedPath(from: CGFloat(start), to: CGFloat(min(end, 1)))
        if end > 1 {
            path.addPath(base.trimmedPath(from: 0, to: CGFloat(end - 1)))
        }
        return path
    }
}
