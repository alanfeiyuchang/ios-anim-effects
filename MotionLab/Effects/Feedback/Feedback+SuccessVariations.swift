import SwiftUI

private struct SuccessCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.37, y: rect.maxY - rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.minY + rect.height * 0.06))
        return path
    }
}

// MARK: - Spark burst

extension Effect {
    static let feedbackSparkBurst = Effect(
        id: "feedback.spark-burst",
        category: .feedback,
        interaction: .tap,
        name: L("Spark Burst Check", "火花迸发对勾"),
        summary: L("A green disc pops with a ring of sparks flying out, then the check is written.", "绿色圆盘弹出，一圈火花向外飞散，随后写出对勾。"),
        prompt: L(
            "A payment card shows '$24.00 to Mia' above a 'Pay' pill. On tap the pill briefly shows a spinner for 0.7 s, then an 88 pt green disc pops from 0 to full size on a bouncy spring (response 0.4 s, damping 0.5), overshooting about 15%. At the same instant eight 3 × 14 pt spark rays fly out from 44 pt to 74 pt radius while shrinking and fading over 0.5 s, interleaved with eight small dots that travel farther and vanish; sparks alternate green, mint and amber. 200 ms later a 6 pt white check draws itself over 0.3 s ease-out and a success haptic fires. The caption fades in: 'Payment sent'. Celebratory in half a second, never noisy.",
            "一张付款卡片显示“向 Mia 支付 ¥168.00”，下方是“支付”胶囊按钮。点击后按钮先显示 0.7 秒的旋转指示，随后一枚 88 pt 的绿色圆盘以弹跳弹簧（响应 0.4 秒、阻尼 0.5）从 0 弹到满尺寸，约过冲 15%。同一刻八根 3 × 14 pt 的火花射线从 44 pt 半径飞到 74 pt，在 0.5 秒内边飞边缩短、淡出，其间穿插八颗飞得更远后消失的小圆点；火花在绿、薄荷绿、琥珀之间交替。200 毫秒后 6 pt 白色对勾以 0.3 秒缓出自绘完成，并触发成功触感。说明文字“付款成功”淡入。半秒内完成庆祝，从不喧闹。"
        ),
        implementation: L(
            "A success flag drives the disc's spring scale and a delayed check trim; a keyframeAnimator keyed on a burst counter moves the spark progress from 0 to 1, which places, shortens and fades the rays and dots.",
            "成功标志驱动圆盘的弹簧缩放与延迟的对勾 trim；以迸发计数为触发器的 keyframeAnimator 把火花进度从 0 推到 1，据此定位、缩短并淡出射线与圆点。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "trim(from:to:)", "spring(response:dampingFraction:)", "rotationEffect"],
        tags: ["success", "sparks", "burst", "payment", "成功", "火花", "迸发", "支付"],
        params: [
            .slider("damping", L("Pop damping", "弹出阻尼"), 0.3...1.0, default: 0.5),
            .slider("reach", L("Spark reach", "火花距离"), 10...60, default: 30, decimals: 0, unit: "pt"),
            .slider("count", L("Sparks", "火花数"), 5...12, default: 8, step: 1, decimals: 0),
        ]
    ) { ctx in
        SparkBurstDemo(ctx: ctx)
    }
}

private enum SparkPhase: Equatable {
    case idle
    case paying
    case paid
}

private struct SparkBurstDemo: View {
    let ctx: DemoContext
    @State private var phase: SparkPhase = .idle
    @State private var bursts = 0

    var body: some View {
        let zh = ctx.language == .zh
        let paid = phase == .paid
        VStack(spacing: 18) {
            ZStack {
                SparkRing(count: max(ctx.int("count"), 3), reach: ctx.cg("reach"))
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: bursts) { content, spark in
                        content.environment(\.sparkProgress, spark)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            MoveKeyframe(0)
                            CubicKeyframe(1, duration: 0.5)
                        }
                    }
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0x4BE08F), Palette.green], startPoint: .top, endPoint: .bottom))
                    .frame(width: 88, height: 88)
                    .shadow(color: Palette.green.opacity(0.4), radius: 14, y: 6)
                    .scaleEffect(paid ? 1 : 0.01)
                    .opacity(paid ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: ctx["damping"]), value: paid)
                SuccessCheckShape()
                    .trim(from: 0, to: paid ? 1 : 0)
                    .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .frame(width: 36, height: 28)
                    .animation(paid ? Animation.easeOut(duration: 0.3).delay(0.2) : Animation.easeIn(duration: 0.1), value: paid)
                if !paid {
                    amountCard(zh: zh)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .frame(width: 240, height: 170)
            Text(zh ? "付款成功" : "Payment sent")
                .font(.headline)
                .opacity(paid ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(paid ? 0.3 : 0), value: paid)
            payButton(zh: zh)
            DemoHint(text: L("Tap Pay", "点击支付"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 4.2, delay: 0.5) { pay() }
    }

    private func amountCard(zh: Bool) -> some View {
        VStack(spacing: 6) {
            Text(zh ? "向 Mia 支付" : "Pay Mia")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(zh ? "¥168.00" : "$24.00")
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
        }
        .frame(width: 220, height: 130)
        .demoCard()
    }

    private func payButton(zh: Bool) -> some View {
        Button(action: pay) {
            ZStack {
                if phase == .paying {
                    ProgressView()
                        .tint(.white)
                        .transition(.opacity)
                } else {
                    Text(phase == .paid ? (zh ? "完成" : "Done") : (zh ? "支付" : "Pay"))
                        .transition(.opacity)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 200, height: 50)
            .background(phase == .paid ? AnyShapeStyle(Palette.green) : AnyShapeStyle(Palette.primary), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func pay() {
        switch phase {
        case .paying:
            return
        case .paid:
            withAnimation(.smooth(duration: 0.35)) { phase = .idle }
            return
        case .idle:
            break
        }
        let live = !ctx.isPreview
        if live { Haptics.tap(.medium) }
        withAnimation(.easeInOut(duration: 0.2)) { phase = .paying }
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            withAnimation(.smooth(duration: 0.25)) { phase = .paid }
            bursts += 1
            try? await Task.sleep(for: .seconds(0.2))
            if live { Haptics.success() }
            if !live {
                try? await Task.sleep(for: .seconds(2.4))
                withAnimation(.smooth(duration: 0.35)) { phase = .idle }
            }
        }
    }
}

private struct SparkProgressKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private extension EnvironmentValues {
    var sparkProgress: CGFloat {
        get { self[SparkProgressKey.self] }
        set { self[SparkProgressKey.self] = newValue }
    }
}

private struct SparkRing: View {
    let count: Int
    let reach: CGFloat
    @Environment(\.sparkProgress) private var spark

    private let colors: [Color] = [Palette.green, Palette.mint, Palette.amber]

    var body: some View {
        let live: Bool = spark > 0.001 && spark < 0.999
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ray(index)
                dot(index)
            }
        }
        .opacity(live ? 1 : 0)
    }

    private func ray(_ index: Int) -> some View {
        let angle: Double = Double(index) / Double(count) * 360
        let radius: CGFloat = 44 + reach * spark
        return Capsule()
            .fill(colors[index % colors.count])
            .frame(width: 3, height: 14 * (1 - spark * 0.8))
            .offset(y: -radius)
            .opacity(Double(1 - spark))
            .rotationEffect(.degrees(angle))
    }

    private func dot(_ index: Int) -> some View {
        let angle: Double = (Double(index) + 0.5) / Double(count) * 360
        let radius: CGFloat = 40 + (reach + 12) * spark
        let size: CGFloat = 6 * (1 - spark)
        return Circle()
            .fill(colors[(index + 1) % colors.count])
            .frame(width: size, height: size)
            .offset(y: -radius)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Level up

extension Effect {
    static let feedbackLevelUp = Effect(
        id: "feedback.level-up",
        category: .feedback,
        interaction: .tap,
        name: L("Level-Up Flip", "升级翻牌"),
        summary: L("XP overflows the bar, the level badge flips to the next number and a gleam sweeps it.", "经验值溢出进度条，等级徽章翻面到下一个数字，一道高光扫过。"),
        prompt: L(
            "A lesson card holds a 56 pt gradient level badge, a 180 × 10 pt XP bar with a '70 / 100 XP' readout, and a 'Complete lesson' pill. Each tap earns 50 XP: a '+50 XP' label floats 40 pt up from the button and fades over 0.9 s while the bar fills on a 0.5 s ease-in-out. When it overflows, the full bar flashes white, the badge flips 180° around its vertical axis in 0.8-perspective 3D on a spring (response 0.6 s, damping 0.6) and its number switches exactly when it is edge-on, then a diagonal gleam sweeps across it in 0.5 s; the bar empties and refills to the 20 XP carried over, and a success haptic plays. Rewarding, game-like, crisp.",
            "一张课程卡片上有一枚 56 pt 的渐变等级徽章、一条 180 × 10 pt 的经验条（显示“70 / 100 XP”）以及“完成课程”胶囊按钮。每次点击获得 50 XP：“+50 XP”标签从按钮处上浮 40 pt，并在 0.9 秒内淡出，同时经验条以 0.5 秒缓入缓出填充。一旦溢出，满格的经验条闪一下白光，徽章以 0.8 透视绕竖直轴用弹簧（响应 0.6 秒、阻尼 0.6）翻转 180°，数字恰好在侧面朝向镜头时切换，随后一道斜向高光在 0.5 秒内扫过徽章；经验条清空再填到结转的 20 XP，并触发成功触感。有奖励感、游戏感、干脆利落。"
        ),
        implementation: L(
            "An Animatable badge interpolates a 'turns' value so rotation3DEffect and the displayed number stay in sync (the face is mirrored on odd turns); keyframeAnimators keyed on counters run the floating XP label and the gleam.",
            "Animatable 徽章插值“翻转圈数”，让 rotation3DEffect 与显示的数字保持同步（奇数次翻转时镜像内容）；以计数器为触发器的 keyframeAnimator 驱动上浮的经验标签与高光。"
        ),
        apis: ["Animatable", "rotation3DEffect(_:axis:perspective:)", "keyframeAnimator(initialValue:trigger:)", "contentTransition(.numericText)"],
        tags: ["level up", "xp", "gamification", "flip", "升级", "经验值", "游戏化", "翻牌"],
        params: [
            .slider("gain", L("XP per lesson", "每课经验"), 10...100, default: 50, step: 10, decimals: 0, unit: " XP"),
            .slider("response", L("Flip response", "翻转响应"), 0.3...1.0, default: 0.6, unit: "s"),
            .slider("damping", L("Flip damping", "翻转阻尼"), 0.3...1.0, default: 0.6),
        ]
    ) { ctx in
        LevelUpDemo(ctx: ctx)
    }
}

private struct FloatXP {
    var y: CGFloat = 0
    var opacity: Double = 0
}

private struct LevelUpDemo: View {
    let ctx: DemoContext
    @State private var xp: Double = 0.7
    @State private var turns: Double = 0
    @State private var gains = 0
    @State private var gleams = 0
    @State private var flash = false
    @State private var busy = false

    private let startLevel = 4

    var body: some View {
        let zh = ctx.language == .zh
        let gain: Int = max(ctx.int("gain"), 10)
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    LevelBadge(turns: turns, startLevel: startLevel, gleams: gleams)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(zh ? "西班牙语 · 第 12 课" : "Spanish · Lesson 12")
                            .font(.subheadline.weight(.semibold))
                        xpBar
                        Text("\(Int((xp * 100).rounded())) / 100 XP")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: xp))
                    }
                }
                Button(action: { complete(gain: gain) }) {
                    Text(zh ? "完成课程" : "Complete lesson")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Palette.primary, in: Capsule())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) { floatingGain(gain) }
            }
            .frame(width: 262)
            .padding(18)
            .demoCard()
            DemoHint(text: L("Tap Complete lesson", "点击“完成课程”"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.6, delay: 0.5) { complete(gain: gain) }
    }

    private var xpBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.08))
            Capsule()
                .fill(LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(10, 180 * CGFloat(min(xp, 1))))
            Capsule()
                .fill(.white)
                .opacity(flash ? 0.8 : 0)
        }
        .frame(width: 180, height: 10)
    }

    private func floatingGain(_ gain: Int) -> some View {
        Text("+\(gain) XP")
            .font(.subheadline.weight(.heavy).monospacedDigit())
            .foregroundStyle(Palette.coral)
            .allowsHitTesting(false)
            .keyframeAnimator(initialValue: FloatXP(), trigger: gains) { content, value in
                content
                    .offset(y: value.y)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    MoveKeyframe(0)
                    CubicKeyframe(-40, duration: 0.9)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(1)
                    LinearKeyframe(1, duration: 0.4)
                    CubicKeyframe(0, duration: 0.5)
                }
            }
    }

    private func complete(gain: Int) {
        guard !busy else { return }
        busy = true
        let live = !ctx.isPreview
        let step: Double = Double(gain) / 100
        let total: Double = xp + step
        let flipSpring = Animation.spring(response: ctx["response"], dampingFraction: ctx["damping"])
        gains += 1
        if live { Haptics.tap() }
        withAnimation(.easeInOut(duration: 0.5)) { xp = min(total, 1) }
        Task {
            try? await Task.sleep(for: .seconds(0.55))
            guard total >= 1 else {
                busy = false
                return
            }
            withAnimation(.easeOut(duration: 0.12)) { flash = true }
            withAnimation(flipSpring) { turns += 1 }
            if live { Haptics.success() }
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.easeIn(duration: 0.25)) { flash = false }
            xp = 0
            withAnimation(.easeOut(duration: 0.45)) { xp = total - 1 }
            try? await Task.sleep(for: .seconds(0.25))
            gleams += 1
            try? await Task.sleep(for: .seconds(0.5))
            busy = false
        }
    }
}

/// The level badge. `turns` is animatable so the number flips exactly at 90°.
private struct LevelBadge: View, Animatable {
    var turns: Double
    let startLevel: Int
    let gleams: Int

    var animatableData: Double {
        get { turns }
        set { turns = newValue }
    }

    var body: some View {
        let passed: Int = Int((turns + 0.5).rounded(.down))
        let mirrored: Bool = passed % 2 == 1
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Palette.violet, Palette.indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(.white.opacity(0.35), lineWidth: 2)
            VStack(spacing: -2) {
                Text("LV")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .opacity(0.8)
                Text("\(startLevel + passed)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded).monospacedDigit())
            }
            .foregroundStyle(.white)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            LevelGleam(trigger: gleams)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
        }
        .rotation3DEffect(.degrees(turns * 180), axis: (x: 0, y: 1, z: 0), perspective: 0.8)
        .shadow(color: Palette.violet.opacity(0.4), radius: 10, y: 5)
    }
}

private struct LevelGleam: View {
    let trigger: Int

    var body: some View {
        LinearGradient(
            colors: [.white.opacity(0), .white.opacity(0.7), .white.opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 24, height: 90)
        .rotationEffect(.degrees(25))
        .keyframeAnimator(initialValue: CGFloat(-70), trigger: trigger) { content, x in
            content.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                MoveKeyframe(-60)
                CubicKeyframe(60, duration: 0.5)
                MoveKeyframe(-70)
            }
        }
        .allowsHitTesting(false)
    }
}
