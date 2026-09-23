import SwiftUI

extension Effect {
    static let iconsPaperPlane = Effect(
        id: "icons.paper-plane",
        category: .icons,
        interaction: .tap,
        name: L("Paper Plane Send", "纸飞机发送"),
        summary: L("The send glyph launches on a swooping curve with a dotted contrail, then a check lands.", "发送图标沿弧线起飞并拖出虚线尾迹，随后换成对勾。"),
        prompt: L(
            "A round gradient send button holds a white paper-plane glyph. On tap the button dips to 90% and the plane pulls back with a −12° wind-up, then launches along a swooping quadratic curve — out to the left, then climbing to the top-right corner of the stage — banking to follow the curve's tangent and tinting from white to indigo once it clears the disc, easing in and out over ~0.7 s and shrinking to 70%. A dotted contrail trails a third of the path behind it and fades with the plane. While the plane is away a checkmark scales into the button and the caption changes to “Sent”; then a fresh plane springs back in (bouncy, from 20%). Light, joyful and precise.",
            "圆形渐变发送按钮中是一架白色纸飞机图标。点击时按钮下沉到90%，纸飞机先向后−12°蓄力，然后沿一条二次贝塞尔弧线起飞——先向左外摆，再爬升到舞台右上角——机身随曲线切线倾斜转向、离开按钮后由白转为靛蓝，约0.7秒内缓入缓出并缩小到70%。一道虚线尾迹在其身后跟随约三分之一路径，并与飞机一同淡出。飞机离场期间，对勾在按钮中放大出现，说明文字变为「已发送」；随后一架新的纸飞机以弹性弹簧从20%大小弹回。轻快、愉悦而精准。"
        ),
        implementation: L(
            "A keyframeAnimator animates a 0→1 flight progress plus scale, opacity and wind-up tracks; position and bank angle are evaluated from a quadratic Bézier and its derivative, and the contrail is the same curve as a Shape trimmed behind the plane.",
            "keyframeAnimator 驱动 0→1 的飞行进度以及缩放、透明度与蓄力轨道；位置与倾斜角由二次贝塞尔曲线及其导数计算，尾迹是同一条曲线的 Shape，按飞机位置向后 trim。"
        ),
        apis: ["keyframeAnimator", "Path.addQuadCurve", "Shape.trim(from:to:)", "StrokeStyle(dash:)", "position(_:)"],
        tags: ["send", "paper plane", "message", "flight path", "发送", "纸飞机", "消息", "飞行轨迹"],
        params: [
            .slider("duration", L("Flight time", "飞行时长"), 0.4...1.4, default: 0.7, unit: "s"),
            .slider("swoop", L("Swoop", "外摆幅度"), 0...1, default: 0.7),
            .toggle("trail", L("Contrail", "尾迹"), default: true),
        ]
    ) { ctx in
        IconsPlaneDemo(ctx: ctx)
    }
}

private struct IconsPlaneValues {
    var fly: Double = 0
    var scale: Double = 1
    var opacity: Double = 1
    var windup: Double = 0
    var press: Double = 1
}

/// The flight curve in a 300×222 scene: from the button up-left, then to the top-right corner.
private struct IconsPlaneCurve {
    let swoop: Double

    var start: CGPoint { CGPoint(x: 150, y: 170) }
    var control: CGPoint { CGPoint(x: CGFloat(150 - 150 * swoop), y: CGFloat(50 + 50 * (1 - swoop))) }
    var end: CGPoint { CGPoint(x: 296, y: 12) }

    func point(_ progress: Double) -> CGPoint {
        let t = CGFloat(progress)
        let u = 1 - t
        let x = u * u * start.x + 2 * u * t * control.x + t * t * end.x
        let y = u * u * start.y + 2 * u * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }

    /// Heading of the curve in degrees (screen coordinates).
    func heading(_ progress: Double) -> Double {
        let t = CGFloat(progress)
        let u = 1 - t
        let dx = 2 * u * (control.x - start.x) + 2 * t * (end.x - control.x)
        let dy = 2 * u * (control.y - start.y) + 2 * t * (end.y - control.y)
        return atan2(Double(dy), Double(dx)) * 180 / .pi
    }
}

private struct IconsPlaneTrail: Shape {
    let curve: IconsPlaneCurve

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: curve.start)
        path.addQuadCurve(to: curve.end, control: curve.control)
        return path
    }
}

private struct IconsPlaneDemo: View {
    let ctx: DemoContext
    @State private var launches = 0
    @State private var sent = false

    var body: some View {
        let duration = ctx["duration"]
        let curve = IconsPlaneCurve(swoop: ctx["swoop"])
        let trail = ctx.bool("trail")
        let hold = 0.6
        VStack(spacing: 4) {
            Color.clear
                .frame(width: 300, height: IconsPlaneScene.height)
                .keyframeAnimator(initialValue: IconsPlaneValues(), trigger: launches) { content, value in
                    content.overlay(alignment: .topLeading) {
                        IconsPlaneScene(value: value, curve: curve, trail: trail, sent: sent)
                    }
                } keyframes: { _ in
                    KeyframeTrack(\.press) {
                        CubicKeyframe(0.9, duration: 0.12)
                        SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                    }
                    KeyframeTrack(\.windup) {
                        CubicKeyframe(-12, duration: 0.14)
                        CubicKeyframe(0, duration: 0.16)
                    }
                    KeyframeTrack(\.fly) {
                        LinearKeyframe(0, duration: 0.14)
                        CubicKeyframe(1, duration: duration)
                        LinearKeyframe(1, duration: hold)
                        LinearKeyframe(0, duration: 0.01)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(1, duration: 0.14 + duration * 0.75)
                        LinearKeyframe(0, duration: duration * 0.25)
                        LinearKeyframe(0, duration: hold + 0.01)
                        CubicKeyframe(1, duration: 0.3)
                    }
                    KeyframeTrack(\.scale) {
                        LinearKeyframe(1, duration: 0.14)
                        CubicKeyframe(0.7, duration: duration)
                        LinearKeyframe(0.7, duration: hold)
                        LinearKeyframe(0.2, duration: 0.01)
                        SpringKeyframe(1, duration: 0.45, spring: .bouncy)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { send() }
            Text(sent ? L("Sent", "已发送") : L("Send", "发送"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(sent ? AnyShapeStyle(Palette.green) : AnyShapeStyle(.secondary))
                .contentTransition(.opacity)
            DemoHint(text: L("Tap to send", "点击发送"), ctx: ctx)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: max(duration, 0.4) + 1.5) { send() }
    }

    private func send() {
        launches += 1
        if !ctx.isPreview { Haptics.tap(.medium) }
        // Captured now: the landing haptic runs after autoplay (or the detail intro) has unmuted Haptics.
        let muted = Haptics.isMuted || ctx.isPreview
        let away = 0.14 + ctx["duration"] * 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + away) {
            withAnimation(.snappy) { sent = true }
            if !muted { Haptics.success() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + away + 1.2) {
            withAnimation(.snappy) { sent = false }
        }
    }
}

private struct IconsPlaneScene: View {
    /// Button centre sits at y 170, leaving just the caption below it.
    static let height: CGFloat = 222

    let value: IconsPlaneValues
    let curve: IconsPlaneCurve
    let trail: Bool
    let sent: Bool

    var body: some View {
        let t = value.fly
        let position = curve.point(t)
        // Blend from the glyph's resting pose into the curve's heading over the first 20% of the flight.
        // The paperplane glyph points up-right (−45° in screen space), so offset the heading by 45°.
        let bank = (curve.heading(t) + 45).truncatingRemainder(dividingBy: 360)
        let normalized = bank > 180 ? bank - 360 : (bank < -180 ? bank + 360 : bank)
        let angle = normalized * min(t * 5, 1) + value.windup
        // White while over the disc, then indigo so the flight reads on the light stage too.
        let tint: Double = ((t - 0.1) / 0.2).clamped(to: 0...1)
        let shadowOpacity: Double = t > 0.02 ? 0.2 + 0.15 * tint : 0
        ZStack(alignment: .topLeading) {
            if trail {
                IconsPlaneTrail(curve: curve)
                    .trim(from: CGFloat(max(t - 0.34, 0)), to: CGFloat(t))
                    .stroke(Palette.violet.opacity(0.55), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 7]))
                    .opacity(value.opacity)
            }
            button
                .position(curve.start)
            plane(tint: tint)
                .shadow(color: Palette.indigo.opacity(shadowOpacity), radius: 6, y: 4)
                .rotationEffect(.degrees(angle))
                .scaleEffect(CGFloat(value.scale) * CGFloat(value.press))
                .opacity(value.opacity)
                .position(position)
        }
        .frame(width: 300, height: IconsPlaneScene.height, alignment: .topLeading)
    }

    private func plane(tint: Double) -> some View {
        let glyph = Image(systemName: "paperplane.fill").font(.system(size: 28, weight: .semibold))
        return ZStack {
            glyph.foregroundStyle(.white)
            glyph.foregroundStyle(Palette.indigo).opacity(tint)
        }
    }

    private var button: some View {
        Circle()
            .fill(Palette.primary)
            .frame(width: 84, height: 84)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
            .overlay {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(sent ? 1 : 0.3)
                    .opacity(sent ? 1 - value.opacity : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: sent)
            }
            .shadow(color: Palette.indigo.opacity(0.4), radius: 16, y: 8)
            .scaleEffect(CGFloat(value.press))
    }
}
