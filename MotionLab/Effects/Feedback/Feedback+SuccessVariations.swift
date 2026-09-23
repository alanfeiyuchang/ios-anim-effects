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
                    .animation(paid ? .easeOut(duration: 0.3).delay(0.2) : .easeIn(duration: 0.1), value: paid)
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

// MARK: - Rubber stamp

extension Effect {
    static let feedbackStamp = Effect(
        id: "feedback.stamp-approve",
        category: .feedback,
        interaction: .tap,
        name: L("Rubber Stamp", "橡皮图章"),
        summary: L("An APPROVED stamp slams onto the document, the card flinches and the ink settles.", "“已批准”图章重重盖在单据上，卡片一震，墨迹随之沉定。"),
        prompt: L(
            "An expense report card (title, line items, total) sits above an 'Approve' button. On tap a green 'APPROVED' stamp — heavy rounded caps inside a 3 pt double-ruled border — drops from 220% scale, 0% opacity and -18° rotation to 94% scale and -8° in 0.16 s ease-in, then settles to 100% on a spring; its ink starts at a 3 pt blur and sharpens over 0.25 s. At impact the card flinches down 4 pt and springs back, an outline of the stamp expands 30% and fades, and a heavy haptic thumps. Tapping again lifts the stamp off with a fade. Decisive, tactile, a little theatrical.",
            "一张报销单卡片（标题、明细、合计）位于“批准”按钮上方。点击后一枚绿色“已批准”图章——粗体圆角字、外框为 3 pt 双线——从 220% 缩放、0% 透明度、-18° 旋转，在 0.16 秒缓入内砸到 94% 缩放、-8°，再以弹簧回到 100%；墨迹从 3 pt 模糊在 0.25 秒内变清晰。落下瞬间卡片向下一震 4 pt 再弹回，一圈图章轮廓向外扩大 30% 并淡出，同时伴随一次重触感。再次点击图章淡出抬起。果断、有触感、略带戏剧性。"
        ),
        implementation: L(
            "Two keyframeAnimators share one trigger: one drives the stamp's scale, rotation, opacity and blur from dramatic start values to its rest pose, the other drives the card's impact offset; the rest pose is the initial value so the stamp persists.",
            "两个 keyframeAnimator 共用一个触发器：一个把图章的缩放、旋转、透明度与模糊从夸张的初值带回静止姿态，另一个驱动卡片的冲击位移；静止姿态即初始值，因此图章会保留在原处。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "MoveKeyframe", "SpringKeyframe", "UIImpactFeedbackGenerator(.heavy)"],
        tags: ["stamp", "approve", "slam", "impact", "图章", "批准", "盖章", "冲击"],
        params: [
            .slider("scale", L("Drop scale", "起始缩放"), 1.4...3.0, default: 2.2, decimals: 1),
            .slider("tilt", L("Rest tilt", "静止倾角"), -20...20, default: -8, decimals: 0, unit: "°"),
            .choice("tone", L("Stamp", "图章"), [L("Approved", "已批准"), L("Rejected", "已驳回")], default: 0),
        ]
    ) { ctx in
        StampDemo(ctx: ctx)
    }
}

private struct StampPose {
    var scale: CGFloat = 1
    var rotation: Double = 0
    var opacity: Double = 1
    var blur: CGFloat = 0
    var ring: CGFloat = 1
    var ringOpacity: Double = 0
}

private struct StampDemo: View {
    let ctx: DemoContext
    @State private var stamped = false
    @State private var hits = 0

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 18) {
            ZStack {
                report(zh: zh)
                // Always in the hierarchy so the keyframes see the trigger change.
                stamp(zh: zh)
                    .opacity(stamped ? 1 : 0)
            }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: hits) { content, dip in
                content.offset(y: dip)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(0, duration: 0.16)
                    CubicKeyframe(4, duration: 0.05)
                    SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                }
            }
            Button(action: toggle) {
                Text(stamped ? (zh ? "撤销" : "Undo") : (zh ? "批准" : "Approve"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(Palette.primary, in: Capsule())
                    .contentTransition(.opacity)
            }
            .buttonStyle(.plain)
            DemoHint(text: L("Tap Approve", "点击批准"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.5) { toggle() }
    }

    private func report(zh: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(zh ? "报销单 #2031" : "Expense #2031")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(zh ? "5月12日" : "May 12")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            reportLine(zh ? "机票" : "Flight", "$412.00")
            reportLine(zh ? "酒店 · 2 晚" : "Hotel · 2 nights", "$286.00")
            reportLine(zh ? "餐饮" : "Meals", "$64.50")
            Divider()
            reportLine(zh ? "合计" : "Total", "$762.50", bold: true)
        }
        .padding(18)
        .frame(width: 260)
        .demoCard()
    }

    private func reportLine(_ title: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(bold ? Font.subheadline.weight(.bold) : Font.subheadline)
        .foregroundStyle(bold ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
    }

    private func stamp(zh: Bool) -> some View {
        let rejected = ctx.int("tone") == 1
        let color: Color = rejected ? Palette.red : Palette.green
        let text: String = rejected ? (zh ? "已驳回" : "REJECTED") : (zh ? "已批准" : "APPROVED")
        let drop: CGFloat = ctx.cg("scale")
        let tilt: Double = ctx["tilt"]
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return Text(text)
            .font(.system(size: 26, weight: .black, design: .rounded))
            .tracking(zh ? 6 : 2)
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay { shape.strokeBorder(color, lineWidth: 3) }
            .overlay { shape.inset(by: -5).stroke(color.opacity(0.7), lineWidth: 1.5) }
            .keyframeAnimator(initialValue: StampPose(), trigger: hits) { content, pose in
                content
                    .blur(radius: pose.blur)
                    .scaleEffect(pose.scale)
                    .opacity(pose.opacity)
                    .background {
                        shape
                            .stroke(color.opacity(pose.ringOpacity), lineWidth: 2)
                            .scaleEffect(pose.ring)
                    }
                    .rotationEffect(.degrees(tilt + pose.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    MoveKeyframe(drop)
                    CubicKeyframe(0.94, duration: 0.16)
                    SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
                }
                KeyframeTrack(\.rotation) {
                    MoveKeyframe(-10)
                    CubicKeyframe(0, duration: 0.16)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(0)
                    LinearKeyframe(1, duration: 0.1)
                }
                KeyframeTrack(\.blur) {
                    MoveKeyframe(3)
                    LinearKeyframe(3, duration: 0.14)
                    CubicKeyframe(0, duration: 0.25)
                }
                KeyframeTrack(\.ring) {
                    MoveKeyframe(1)
                    LinearKeyframe(1, duration: 0.16)
                    CubicKeyframe(1.3, duration: 0.45)
                }
                KeyframeTrack(\.ringOpacity) {
                    MoveKeyframe(0)
                    LinearKeyframe(0, duration: 0.15)
                    LinearKeyframe(0.8, duration: 0.02)
                    CubicKeyframe(0, duration: 0.45)
                }
            }
    }

    private func toggle() {
        if stamped {
            withAnimation(.easeOut(duration: 0.3)) { stamped = false }
            return
        }
        stamped = true
        hits += 1
        guard !ctx.isPreview else { return }
        Task {
            try? await Task.sleep(for: .seconds(0.16))
            Haptics.tap(.heavy)
        }
    }
}
