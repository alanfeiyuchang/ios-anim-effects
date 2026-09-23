import SwiftUI

extension Effect {
    static let iconsBatteryCharge = Effect(
        id: "icons.battery-charge",
        category: .icons,
        interaction: .tap,
        name: L("Battery Charge", "电池充电"),
        summary: L("The plug docks, a bolt pops in and the cell fills through red, amber and green.", "插头接入，闪电弹出，电量依次经过红、黄、绿涨满。"),
        prompt: L(
            "A large horizontal battery outline (150×70 pt, 3 pt rounded stroke, small terminal cap) sits at 18% with a red fill. Tapping plugs it in: a cable plug slides 60 pt from the right into the cap on a snappy spring (≈0.35 s), and 250 ms later a lightning bolt pops into the centre from 20% to 100% on a bouncy spring and keeps pulsing. The fill then grows to 100% over 2.4 s with ease-in-out, its colour stepping from red (under 20%) to amber (under 45%) to green, while the percentage counts up inside and a soft highlight sweeps across the fill every 1.3 s. A success haptic lands at full; tapping again unplugs, the bolt shrinks away and the level eases back to 18%. Clear, reassuring feedback.",
            "一个大号横向电池轮廓（150×70 pt，3 pt 圆角描边，带小正极帽）显示 18% 电量，填充为红色。点击即插电：插头以利落的弹簧（约 0.35 秒）从右侧 60 pt 外滑进正极帽；250 毫秒后，中央闪电以弹性弹簧从 20% 放大到 100%，并持续脉动。随后电量在 2.4 秒内缓入缓出地涨满，颜色由红（低于 20%）转琥珀（低于 45%）再转绿，百分比同步计数，一道柔光每 1.3 秒扫过填充。充满时一下成功触感；再点一次就拔掉插头，闪电缩小消失，电量缓缓回到 18%。反馈清楚，让人安心。"
        ),
        implementation: L(
            "An Animatable fill view turns the animated level into width, a stepped colour and the percentage label every frame; the plug offset and the bolt's scale transition are sequenced with delayed springs, and a repeating keyframeAnimator drives the highlight sweep.",
            "Animatable 填充视图在每一帧把动画中的电量换算成宽度、分级颜色与百分比文字；插头位移与闪电的缩放过渡通过带延迟的弹簧依次编排，重复播放的 keyframeAnimator 驱动高光扫过。"
        ),
        apis: ["Animatable", "keyframeAnimator(initialValue:repeating:)", "symbolEffect(.pulse)", "transition(.scale)", "Animation.delay"],
        tags: ["battery", "charging", "power", "status", "电池", "充电", "电量", "状态"],
        params: [
            .slider("duration", L("Charge time", "充电时长"), 0.8...5.0, default: 2.4, unit: "s"),
            .slider("bounce", L("Bolt bounce", "闪电回弹"), 0...0.6, default: 0.4),
            .toggle("sweep", L("Highlight sweep", "高光扫过"), default: true),
        ]
    ) { ctx in
        BatteryChargeDemo(ctx: ctx)
    }
}

private struct BatteryChargeDemo: View {
    let ctx: DemoContext
    @State private var plugged = false
    @State private var level: Double = 0.18
    @State private var token = 0

    private let bodySize = CGSize(width: 150, height: 70)

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                battery
                plug
            }
            Text(plugged ? L("Charging", "正在充电") : L("On battery", "使用电池"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.interpolate)
                .animation(.snappy, value: plugged)
            DemoHint(text: L("Tap to plug in / unplug", "点击插上 / 拔下电源"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .autoplay(ctx.isPreview, every: max(ctx["duration"] + 1.4, 2.6)) { toggle() }
    }

    private var battery: some View {
        HStack(spacing: 3) {
            ZStack {
                BatteryFill(level: level, sweep: ctx.bool("sweep") && plugged)
                    .padding(6)
                if plugged {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 3)
                        .symbolEffect(.pulse, isActive: true)
                        .transition(
                            .asymmetric(
                                insertion: AnyTransition.scale(scale: 0.2).combined(with: .opacity)
                                    .animation(.spring(duration: 0.5, bounce: ctx["bounce"]).delay(0.25)),
                                removal: AnyTransition.scale(scale: 0.2).combined(with: .opacity)
                                    .animation(.easeIn(duration: 0.2))
                            )
                        )
                }
            }
            .frame(width: bodySize.width, height: bodySize.height)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.primary.opacity(0.55), lineWidth: 3))
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.primary.opacity(0.55))
                .frame(width: 7, height: 24)
        }
    }

    private var plug: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.primary.opacity(0.7))
                .frame(width: 18, height: 20)
            Capsule()
                .fill(Color.primary.opacity(0.45))
                .frame(width: 40, height: 6)
        }
        .offset(x: plugged ? 0 : 60)
        .opacity(plugged ? 1 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: plugged)
    }

    private func toggle() {
        token += 1
        let current = token
        let muted = Haptics.isMuted || ctx.isPreview
        let duration: Double = ctx["duration"]
        if plugged {
            Haptics.tap(.light)
            withAnimation(.easeIn(duration: 0.2)) { plugged = false }
            withAnimation(.easeInOut(duration: 0.9)) { level = 0.18 }
            return
        }
        Haptics.tap(.medium)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { plugged = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard current == token else { return }
            withAnimation(.easeInOut(duration: duration)) { level = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + duration) {
            guard current == token, !muted else { return }
            Haptics.success()
        }
    }
}

/// Width, colour and label all follow the animated level.
private struct BatteryFill: View, Animatable {
    var level: Double
    let sweep: Bool

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    private var tint: Color {
        if level < 0.2 { return Palette.red }
        if level < 0.45 { return Palette.amber }
        return Palette.green
    }

    var body: some View {
        let clamped: Double = min(max(level, 0), 1)
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.gradient)
                .frame(width: 138 * CGFloat(clamped))
                .overlay { highlight }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(verbatim: "\(Int((clamped * 100).rounded()))%")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.primary.opacity(0.75))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 8)
                .padding(.bottom, 4)
        }
    }

    @ViewBuilder
    private var highlight: some View {
        if sweep {
            LinearGradient(colors: [.white.opacity(0), .white.opacity(0.45), .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                .frame(width: 40)
                .keyframeAnimator(initialValue: CGFloat(-60), repeating: true) { content, x in
                    content.offset(x: x)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        LinearKeyframe(CGFloat(-60), duration: 0.3)
                        CubicKeyframe(CGFloat(160), duration: 1.0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
