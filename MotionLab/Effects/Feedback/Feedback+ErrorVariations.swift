import SwiftUI

// MARK: - Jelly deny

extension Effect {
    static let feedbackJellyDeny = Effect(
        id: "feedback.jelly-deny",
        category: .feedback,
        interaction: .tap,
        name: L("Jelly Deny", "果冻拒绝"),
        summary: L("A declined button wobbles like jelly — squash and stretch instead of a shake.", "被拒绝的按钮像果冻一样晃动——用挤压拉伸代替左右摇头。"),
        prompt: L(
            "A checkout card shows 'Visa •••• 4242 · Balance $86.20' above a 250 × 56 pt 'Pay $1,249' pill. On tap the payment is declined: instead of shaking sideways, the pill wobbles in place with volume-preserving squash and stretch — 112% × 88%, then 90% × 110%, 106% × 95%, 97% × 103%, each beat 0.1 s — before settling to 100% on a spring over 0.3 s. During the first beat it floods red and the label blur-replaces to 'Card declined', the balance line turns red, and an error haptic fires. After 1.8 s everything eases back to the indigo 'Pay' state. Soft, forgiving, unmistakably 'no'.",
            "结账卡片上显示“Visa •••• 4242 · 余额 ¥86.20”，下方是一枚 250 × 56 pt 的“支付 ¥8,999”胶囊按钮。点击后支付被拒：按钮不是左右摇头，而是原地做保持体积的挤压拉伸——112% × 88%，然后 90% × 110%、106% × 95%、97% × 103%，每拍 0.1 秒——再以 0.3 秒弹簧回到 100%。第一拍时按钮被红色灌满，文字以模糊替换变为“卡片被拒绝”，余额一行同时变红，并触发错误触感。1.8 秒后一切平缓恢复为靛蓝的“支付”状态。柔软、宽容，却明确表达“不行”。"
        ),
        implementation: L(
            "A keyframeAnimator with separate X and Y scale tracks (each ending at 1) runs on a trigger counter; a declined flag cross-fades the fill and swaps the label with .blurReplace.",
            "keyframeAnimator 以计数器为触发器，分别用 X、Y 两条缩放轨道（都以 1 结束）；拒绝标志交叉淡换填充色，并用 .blurReplace 切换文字。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "scaleEffect(x:y:)", "transition(.blurReplace)", "UINotificationFeedbackGenerator"],
        tags: ["error", "declined", "jelly", "squash", "错误", "拒绝", "果冻", "挤压"],
        params: [
            .slider("amount", L("Squash amount", "挤压幅度"), 0.04...0.2, default: 0.12),
            .slider("beat", L("Beat", "节拍"), 0.06...0.2, default: 0.1, unit: "s"),
        ]
    ) { ctx in
        JellyDenyDemo(ctx: ctx)
    }
}

private struct JellyPose {
    var x: CGFloat = 1
    var y: CGFloat = 1
}

private struct JellyDenyDemo: View {
    let ctx: DemoContext
    @State private var declined = false
    @State private var wobbles = 0
    @State private var token = 0

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 22) {
            HStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundStyle(Palette.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "Visa •••• 4242")
                        .font(.subheadline.weight(.semibold))
                    Text(zh ? "余额 ¥86.20" : "Balance $86.20")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(declined ? AnyShapeStyle(Palette.red) : AnyShapeStyle(.secondary))
                }
                Spacer()
            }
            .frame(width: 250)
            .padding(16)
            .demoCard(cornerRadius: 18)
            Button(action: pay) { pill(zh: zh) }
                .buttonStyle(.plain)
            DemoHint(text: L("Tap Pay", "点击支付"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.25), value: declined)
        .autoplay(ctx.isPreview, every: 2.8, delay: 0.5) { pay() }
    }

    private func pill(zh: Bool) -> some View {
        let a: CGFloat = ctx.cg("amount")
        let beat: Double = ctx["beat"]
        return ZStack {
            Capsule().fill(Palette.primary)
            Capsule().fill(Palette.red).opacity(declined ? 1 : 0)
            if declined {
                Label(zh ? "卡片被拒绝" : "Card declined", systemImage: "xmark.octagon.fill")
                    .transition(.blurReplace)
            } else {
                Text(zh ? "支付 ¥8,999" : "Pay $1,249")
                    .transition(.blurReplace)
            }
        }
        .font(.headline)
        .foregroundStyle(.white)
        .frame(width: 250, height: 56)
        .shadow(color: (declined ? Palette.red : Palette.indigo).opacity(0.35), radius: 14, y: 7)
        .keyframeAnimator(initialValue: JellyPose(), trigger: wobbles) { content, pose in
            content.scaleEffect(x: pose.x, y: pose.y)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                CubicKeyframe(1 + a, duration: beat)
                CubicKeyframe(1 - a * 0.83, duration: beat)
                CubicKeyframe(1 + a * 0.5, duration: beat)
                CubicKeyframe(1 - a * 0.25, duration: beat)
                SpringKeyframe(1, duration: 0.3, spring: .smooth)
            }
            KeyframeTrack(\.y) {
                CubicKeyframe(1 - a, duration: beat)
                CubicKeyframe(1 + a * 0.83, duration: beat)
                CubicKeyframe(1 - a * 0.42, duration: beat)
                CubicKeyframe(1 + a * 0.25, duration: beat)
                SpringKeyframe(1, duration: 0.3, spring: .smooth)
            }
        }
    }

    private func pay() {
        guard !declined else { return }
        token += 1
        let current = token
        if !ctx.isPreview { Haptics.error() }
        wobbles += 1
        withAnimation(.easeOut(duration: 0.12)) { declined = true }
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard token == current else { return }
            withAnimation(.smooth(duration: 0.4)) { declined = false }
        }
    }
}

// MARK: - Limit bounce

extension Effect {
    static let feedbackLimitBounce = Effect(
        id: "feedback.limit-bounce",
        category: .feedback,
        interaction: .tap,
        name: L("Limit Rubber-Band", "上限回弹"),
        summary: L("Pushing past the maximum stretches the stepper like rubber and snaps it back.", "超过上限时步进器像橡皮筋一样被拉长，再弹回原位。"),
        prompt: L(
            "A ticket stepper — minus button, rolling count, plus button in a 200 × 52 pt capsule — sits under 'Tickets · Max 4 per order'. Valid taps roll the digit with a numeric transition and a light tick. Tapping plus at the limit does not shake: the capsule stretches 6% toward the tapped side from its leading anchor in 0.1 s, the digit rises 10 pt and drops back past its line by 3 pt, and both snap home on a bouncy spring in 0.4 s — a rubber band hitting its end stop. The plus glyph dims to 30%, the border flashes red and the 'Max 4' caption turns red and pulses to 106%, with a rigid haptic. Clear boundaries, zero scolding.",
            "一个购票步进器——减号、滚动数字、加号，装在 200 × 52 pt 的胶囊里——位于“票数 · 每单最多 4 张”下方。有效点击会让数字以数字转场滚动并伴随轻触感。在上限时点击加号不会抖动：胶囊以前缘为锚点在 0.1 秒内向点击一侧拉长 6%，数字上升 10 pt 再越过基线下沉 3 pt，然后二者一起以弹跳弹簧在 0.4 秒内弹回原位——像橡皮筋撞到尽头。加号变暗到 30%，边框闪红，“最多 4 张”说明文字变红并脉冲到 106%，同时伴随一次硬朗触感。边界清晰，从不责备。"
        ),
        implementation: L(
            "A keyframeAnimator keyed on a 'bump' counter drives the capsule's horizontal stretch and the digit's vertical rubber-band; a flash flag tints the border and caption.",
            "以“撞墙”计数为触发器的 keyframeAnimator 驱动胶囊的横向拉伸与数字的纵向橡皮筋回弹；闪烁标志为边框和说明着色。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "contentTransition(.numericText)", "scaleEffect(x:y:anchor:)", "UIImpactFeedbackGenerator(.rigid)"],
        tags: ["limit", "stepper", "rubber band", "maximum", "上限", "步进器", "橡皮筋", "边界"],
        params: [
            .slider("max", L("Maximum", "上限"), 2...9, default: 4, step: 1, decimals: 0),
            .slider("stretch", L("Stretch", "拉伸"), 0.02...0.15, default: 0.06),
            .slider("lift", L("Digit lift", "数字上浮"), 4...20, default: 10, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        LimitBounceDemo(ctx: ctx)
    }
}

private struct LimitPose {
    var stretch: CGFloat = 1
    var lift: CGFloat = 0
}

private struct LimitBounceDemo: View {
    let ctx: DemoContext
    @State private var value = 1
    @State private var bumps = 0
    @State private var flash = false
    @State private var autoHits = 0

    var body: some View {
        let zh = ctx.language == .zh
        let maxValue: Int = max(ctx.int("max"), 1)
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(zh ? "票数" : "Tickets")
                    .font(.headline)
                Text(zh ? "每单最多 \(maxValue) 张" : "Max \(maxValue) per order")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(flash ? AnyShapeStyle(Palette.red) : AnyShapeStyle(.secondary))
                    .scaleEffect(flash ? 1.06 : 1)
            }
            stepper(maxValue: maxValue)
            DemoHint(text: L("Tap + past the limit", "超过上限后继续点 +"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: flash)
        .autoplay(ctx.isPreview, every: 0.8, delay: 0.5) { autoStep(maxValue: maxValue) }
    }

    private func stepper(maxValue: Int) -> some View {
        let atMax = value >= maxValue
        let stretch: CGFloat = ctx.cg("stretch")
        let lift: CGFloat = ctx.cg("lift")
        return HStack(spacing: 0) {
            stepButton("minus", enabled: value > 1) { change(-1, maxValue: maxValue) }
            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: Double(value)))
                .frame(maxWidth: .infinity)
                .keyframeAnimator(initialValue: CGFloat(0), trigger: bumps) { content, y in
                    content.offset(y: y)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(-lift, duration: 0.1)
                        CubicKeyframe(3, duration: 0.12)
                        SpringKeyframe(0, duration: 0.3, spring: .bouncy)
                    }
                }
            stepButton("plus", enabled: !atMax) { change(1, maxValue: maxValue) }
        }
        .frame(width: 200, height: 52)
        .background(Palette.elevated, in: Capsule())
        .overlay { Capsule().strokeBorder(flash ? Palette.red : Color.primary.opacity(0.1), lineWidth: flash ? 2 : 1) }
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        .keyframeAnimator(initialValue: CGFloat(1), trigger: bumps) { content, sx in
            content.scaleEffect(x: sx, y: 1, anchor: .leading)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(1 + stretch, duration: 0.1)
                SpringKeyframe(1, duration: 0.4, spring: .bouncy)
            }
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Palette.indigo)
                .opacity(enabled ? 1 : 0.3)
                .frame(width: 56, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func change(_ delta: Int, maxValue: Int) {
        let next = value + delta
        if next > maxValue {
            bumps += 1
            if !ctx.isPreview { Haptics.tap(.rigid) }
            flash = true
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                flash = false
            }
            return
        }
        guard next >= 1 else { return }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(.snappy(duration: 0.25)) { value = next }
    }

    private func autoStep(maxValue: Int) {
        if value >= maxValue {
            autoHits += 1
            if autoHits > 2 {
                autoHits = 0
                withAnimation(.snappy(duration: 0.25)) { value = 1 }
                return
            }
        }
        change(1, maxValue: maxValue)
    }
}

// MARK: - Face ID failure

extension Effect {
    static let feedbackFaceIDFail = Effect(
        id: "feedback.faceid-fail",
        category: .feedback,
        interaction: .tap,
        name: L("Face ID Head Shake", "面容识别摇头"),
        summary: L("The scan glyph turns red and shakes 'no' in 3D, like a head turning side to side.", "识别图标变红，并在 3D 中左右转动，像在摇头说“不”。"),
        prompt: L(
            "A 'Confirm with Face ID' sheet shows a 76 pt Face ID glyph inside four corner brackets. On tap it scans for 1.2 s: the brackets breathe 100% → 92% every 0.5 s and a sky scan line sweeps top to bottom through the glyph. Then recognition fails: the glyph and brackets turn red and the glyph yaws in 3D perspective (0.5) like a head shaking no — 28°, -22°, 14°, -8°, 0° over about 0.6 s — while 'Face Not Recognized' blur-replaces the caption and an error haptic fires. A 'Try Again' link fades in; after 2 s it resets to idle. Human, legible, gently apologetic.",
            "一张“使用面容 ID 确认”面板中，76 pt 的面容 ID 图标被四个角标框住。点击后扫描 1.2 秒：角标每 0.5 秒在 100% → 92% 间呼吸，一条天蓝色扫描线自上而下扫过图标。随后识别失败：图标与角标变红，图标以 3D 透视（0.5）左右偏转，像人在摇头说“不”——28°、-22°、14°、-8°、0°，历时约 0.6 秒——同时说明文字以模糊替换变为“无法识别面容”，并触发错误触感。“再试一次”链接淡入；2 秒后恢复待机。有人情味、清晰、带着温和的歉意。"
        ),
        implementation: L(
            "A keyframeAnimator keyed on the failure count drives rotation3DEffect around the Y axis; the scan line is an offset gradient bar clipped to the glyph frame, and the brackets use phaseAnimator.",
            "以失败次数为触发器的 keyframeAnimator 驱动绕 Y 轴的 rotation3DEffect；扫描线是裁切在图标区域内、带位移的渐变条，角标使用 phaseAnimator 呼吸。"
        ),
        apis: ["rotation3DEffect(_:axis:perspective:)", "keyframeAnimator(initialValue:trigger:)", "phaseAnimator", "transition(.blurReplace)"],
        tags: ["face id", "biometric", "failure", "shake", "面容 ID", "生物识别", "失败", "摇头"],
        params: [
            .slider("yaw", L("Yaw angle", "偏转角"), 10...45, default: 28, decimals: 0, unit: "°"),
            .slider("scan", L("Scan time", "扫描时长"), 0.6...2.5, default: 1.2, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        FaceIDFailDemo(ctx: ctx)
    }
}

private enum FaceScanState: Equatable {
    case idle
    case scanning
    case failed
}

private struct FaceIDFailDemo: View {
    let ctx: DemoContext
    @State private var state: FaceScanState = .idle
    @State private var fails = 0

    var body: some View {
        let zh = ctx.language == .zh
        let failed = state == .failed
        let tint: Color = failed ? Palette.red : Palette.sky
        VStack(spacing: 18) {
            ZStack {
                FaceBrackets(color: tint, breathing: state == .scanning)
                Image(systemName: "faceid")
                    .font(.system(size: 76, weight: .regular))
                    .foregroundStyle(failed ? Palette.red : Color.primary)
                    .keyframeAnimator(initialValue: 0.0, trigger: fails) { content, yaw in
                        content.rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                    } keyframes: { _ in
                        let yaw: Double = ctx["yaw"]
                        KeyframeTrack(\.self) {
                            CubicKeyframe(yaw, duration: 0.12)
                            CubicKeyframe(-yaw * 0.78, duration: 0.14)
                            CubicKeyframe(yaw * 0.5, duration: 0.12)
                            CubicKeyframe(-yaw * 0.28, duration: 0.1)
                            SpringKeyframe(0, duration: 0.2, spring: .smooth)
                        }
                    }
                if state == .scanning {
                    FaceScanLine(duration: max(ctx["scan"], 0.3))
                        .transition(.opacity)
                }
            }
            .frame(width: 120, height: 120)
            .animation(.easeInOut(duration: 0.2), value: failed)
            caption(zh: zh)
            Button(action: attempt) {
                Text(zh ? "再试一次" : "Try Again")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
            .buttonStyle(.plain)
            .opacity(failed ? 1 : 0)
            DemoHint(text: L("Tap the glyph", "点击图标"), ctx: ctx)
        }
        .padding(.vertical, 24)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
        .contentShape(Rectangle())
        .onTapGesture { attempt() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["scan"] + 3.4, delay: 0.5) { attempt() }
    }

    @ViewBuilder
    private func caption(zh: Bool) -> some View {
        Group {
            switch state {
            case .idle:
                Text(zh ? "使用面容 ID 确认" : "Confirm with Face ID")
                    .transition(.blurReplace)
            case .scanning:
                Text(zh ? "正在识别…" : "Scanning…")
                    .transition(.blurReplace)
            case .failed:
                Text(zh ? "无法识别面容" : "Face Not Recognized")
                    .foregroundStyle(Palette.red)
                    .transition(.blurReplace)
            }
        }
        .font(.headline)
    }

    private func attempt() {
        guard state != .scanning else { return }
        let scan = max(ctx["scan"], 0.3)
        let live = !ctx.isPreview
        withAnimation(.smooth(duration: 0.3)) { state = .scanning }
        Task {
            try? await Task.sleep(for: .seconds(scan))
            withAnimation(.smooth(duration: 0.3)) { state = .failed }
            fails += 1
            if live { Haptics.error() }
            try? await Task.sleep(for: .seconds(2.0))
            guard state == .failed else { return }
            withAnimation(.smooth(duration: 0.4)) { state = .idle }
        }
    }
}

private struct FaceBrackets: View {
    let color: Color
    let breathing: Bool

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                FaceCorner()
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: 26, height: 26)
                    .frame(width: 120, height: 120, alignment: .topLeading)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
        }
        .phaseAnimator([false, true]) { content, pulse in
            content.scaleEffect(breathing && pulse ? 0.92 : 1)
        } animation: { _ in
            .easeInOut(duration: 0.5)
        }
    }
}

private struct FaceCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 8))
        path.addQuadCurve(to: CGPoint(x: rect.minX + 8, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

private struct FaceScanLine: View {
    let duration: Double
    @State private var down = false

    var body: some View {
        LinearGradient(colors: [Palette.sky.opacity(0), Palette.sky.opacity(0.8), Palette.sky.opacity(0)], startPoint: .leading, endPoint: .trailing)
            .frame(width: 96, height: 3)
            .shadow(color: Palette.sky, radius: 6)
            .offset(y: down ? 44 : -44)
            .onAppear {
                withAnimation(.easeInOut(duration: duration)) { down = true }
            }
    }
}
