import SwiftUI

extension Effect {
    static let iconsPadlock = Effect(
        id: "icons.padlock",
        category: .icons,
        interaction: .state,
        name: L("Padlock Unlock", "挂锁解锁"),
        summary: L("The key turns, the shackle pops up and swivels open, and the lock glows green.", "钥匙孔先转动，锁梁弹起并旋开，锁身转为绿色辉光。"),
        prompt: L(
            "A chunky padlock drawn from shapes: a rounded 84×66 pt indigo body with a keyhole, and a thick metallic shackle whose left leg is longer than the right. Unlocking plays in three overlapping beats: the keyhole turns 90° (≈150 ms), the shackle pops up 14 pt on a bouncy spring, then swivels 180° in perspective around its long leg so the free end swings out to the left; as it clears, the body cross-fades to mint-green, a green ring pulses out to 1.8× and fades, and a success haptic plays. Locking reverses the order — swing back, drop into the body with a small overshoot, keyhole returns — ending in a rigid click. Mechanical, legible and satisfying.",
            "一把由图形绘制的厚实挂锁：84×66 pt的圆角靛蓝锁身带钥匙孔，粗壮的金属锁梁左腿长于右腿。解锁分三个相互交叠的节拍：钥匙孔先旋转90°（约150毫秒）；锁梁以弹性弹簧向上弹起14 pt，随后以长腿为轴在透视中旋转180°，自由端向左甩出；锁梁脱离时，锁身渐变为薄荷绿，一道绿色光环扩散到1.8倍并淡出，同时触发成功触感。上锁时顺序反转——先转回、再带小幅过冲落入锁身、钥匙孔复位——以一声硬朗的“咔哒”触感收尾。机械、清晰、令人满足。"
        ),
        implementation: L(
            "A custom Shape draws the shackle with tangent arcs; separate .animation(_:value:) modifiers with direction-dependent delays sequence the keyhole rotation, the lift offset and a rotation3DEffect anchored on the long leg, while a keyframeAnimator drives the pulse ring.",
            "自定义 Shape 用切线圆弧绘制锁梁；多个带方向相关延迟的 .animation(_:value:) 分别编排钥匙孔旋转、上抬位移以及锚定在长腿上的 rotation3DEffect，keyframeAnimator 驱动脉冲光环。"
        ),
        apis: ["Shape", "Path.addArc(tangent1End:tangent2End:radius:)", "rotation3DEffect(_:axis:anchor:perspective:)", "animation(_:value:)", "keyframeAnimator"],
        tags: ["lock", "unlock", "padlock", "security", "state", "锁", "解锁", "挂锁", "安全"],
        params: [
            .choice("style", L("Open style", "开锁方式"), [L("Lift & swivel", "弹起并旋开"), L("Lift only", "仅弹起")], default: 0),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.4, unit: "s"),
            .toggle("pulse", L("Pulse ring", "脉冲光环"), default: true),
        ]
    ) { ctx in
        IconsPadlockDemo(ctx: ctx)
    }
}

private struct IconsShackle: Shape {
    var lineWidth: CGFloat
    /// How much shorter the free (right) leg is than the hinge (left) leg.
    var shortfall: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = lineWidth / 2
        let left = rect.minX + inset
        let right = rect.maxX - inset
        let radius = (right - left) / 2
        let top = rect.minY + inset
        var path = Path()
        path.move(to: CGPoint(x: left, y: rect.maxY))
        path.addLine(to: CGPoint(x: left, y: top + radius))
        path.addArc(tangent1End: CGPoint(x: left, y: top), tangent2End: CGPoint(x: left + radius, y: top), radius: radius)
        path.addArc(tangent1End: CGPoint(x: right, y: top), tangent2End: CGPoint(x: right, y: top + radius), radius: radius)
        path.addLine(to: CGPoint(x: right, y: rect.maxY - shortfall))
        return path
    }
}

private struct IconsPulseValues {
    var scale: Double = 0.8
    var opacity: Double = 0
}

private struct IconsPadlockDemo: View {
    let ctx: DemoContext
    @State private var unlocked = false
    @State private var pulses = 0

    private let shackleSize = CGSize(width: 50, height: 62)
    private let lineWidth: CGFloat = 10

    var body: some View {
        VStack(spacing: 26) {
            lock
                .contentShape(Rectangle())
                .onTapGesture { toggle() }
            status
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: 0.62)
    }

    private var lock: some View {
        let swivel = ctx.int("style") == 0
        // Hinge sits on the centre line of the long leg.
        let hinge = UnitPoint(x: lineWidth / 2 / shackleSize.width, y: 0.5)
        return ZStack {
            if ctx.bool("pulse") {
                Circle()
                    .stroke(Palette.green, lineWidth: 3)
                    .frame(width: 130, height: 130)
                    .keyframeAnimator(initialValue: IconsPulseValues(), trigger: pulses) { content, value in
                        content
                            .scaleEffect(CGFloat(value.scale))
                            .opacity(value.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            LinearKeyframe(0.8, duration: 0.26)
                            CubicKeyframe(1.8, duration: 0.6)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(0, duration: 0.25)
                            LinearKeyframe(0.6, duration: 0.01)
                            CubicKeyframe(0, duration: 0.6)
                        }
                    }
                    .offset(y: 8)
            }
            IconsShackle(lineWidth: lineWidth, shortfall: 10)
                .stroke(
                    LinearGradient(colors: [Color(hex: 0xD9DEE8), Color(hex: 0x8C94A6)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: shackleSize.width, height: shackleSize.height)
                .rotation3DEffect(.degrees(unlocked && swivel ? -180 : 0), axis: (x: 0, y: 1, z: 0), anchor: hinge, perspective: 0.5)
                .animation(spring.delay(unlocked ? 0.22 : 0), value: unlocked)
                .offset(y: unlocked ? -44 : -30)
                .animation(spring.delay(unlocked ? 0.1 : (swivel ? 0.24 : 0)), value: unlocked)
            lockBody(swivel: swivel)
                .offset(y: 20)
        }
        .frame(width: 200, height: 190)
    }

    private func lockBody(swivel: Bool) -> some View {
        let colors = unlocked ? [Palette.mint, Palette.green] : [Palette.indigo, Palette.violet]
        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 84, height: 66)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
            .overlay { keyhole }
            .shadow(color: (unlocked ? Palette.green : Palette.indigo).opacity(0.35), radius: 16, y: 8)
            .animation(.smooth(duration: 0.35).delay(unlocked ? 0.22 : (swivel ? 0.3 : 0.1)), value: unlocked)
    }

    private var keyhole: some View {
        VStack(spacing: -3) {
            Circle().frame(width: 14, height: 14)
            RoundedRectangle(cornerRadius: 2, style: .continuous).frame(width: 6, height: 13)
        }
        .foregroundStyle(Color.black.opacity(0.28))
        .rotationEffect(.degrees(unlocked ? 90 : 0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7).delay(unlocked ? 0 : 0.36), value: unlocked)
    }

    private var status: some View {
        HStack(spacing: 6) {
            Image(systemName: unlocked ? "lock.open.fill" : "lock.fill")
                .contentTransition(.symbolEffect(.replace))
            Text(unlocked ? L("Unlocked", "已解锁") : L("Locked", "已锁定"), ctx.language)
                .contentTransition(.opacity)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(unlocked ? AnyShapeStyle(Palette.green) : AnyShapeStyle(.secondary))
        .animation(.snappy, value: unlocked)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap the lock", "点击挂锁"), ctx: ctx)
                .fixedSize()
                .offset(y: 26)
        }
    }

    private func toggle() {
        // Captured now: the delayed haptics run after autoplay (or the detail intro) has unmuted Haptics.
        let muted = Haptics.isMuted || ctx.isPreview
        unlocked.toggle()
        if unlocked {
            pulses += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if !muted { Haptics.success() }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if !muted { Haptics.tap(.rigid) }
            }
        }
    }
}
