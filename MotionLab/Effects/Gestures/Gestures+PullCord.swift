import SwiftUI

extension Effect {
    static let gesturesPullCord = Effect(
        id: "gestures.pull-cord",
        category: .gestures,
        interaction: .gesture,
        name: L("Pull-Cord Switch", "拉绳开关"),
        summary: L("Tug a lamp's cord past a click point to switch it; the cord bounces back and the shade sways.", "把台灯拉绳拽过“咔哒”点即可开关，拉绳回弹、灯罩轻晃。"),
        prompt: L(
            "A pendant lamp (110 pt trapezoid shade, bulb beneath) hangs at the top of the stage, and a thin cord drops 90 pt from the shade's edge to an 18 pt bead. Dragging the bead pulls the cord down 1:1, with rubber-band resistance toward 120 pt and a little sideways give. At 50 pt the switch arms: a rigid haptic clicks and the bead swells to 1.25×. Releasing while armed toggles the light: the bulb blooms amber with a 30 pt glow, a soft light cone fades in over 350 ms and the room icon below lights up, while the cord snaps back on a bouncy spring (response 0.35 s, damping 0.35) and the shade sways ±4° around its hook before settling. Releasing short just lets the cord bounce back. Tactile, nostalgic, delightful.",
            "舞台顶部悬挂着一盏吊灯（110pt 的梯形灯罩，下方是灯泡），灯罩边缘垂下一根 90pt 的细拉绳，末端是 18pt 的拉珠。拖动拉珠时拉绳 1:1 向下伸长，越往下阻力越大并趋近 120pt，左右也能轻微摆动。拉到 50pt 时开关就绪：触发一次硬朗的“咔哒”触感，拉珠放大到 1.25 倍。就绪时松手即切换灯光：灯泡绽放出带 30pt 光晕的琥珀色，一道柔和光锥在 350ms 内淡入，下方的房间图标随之点亮；同时拉绳以高弹性弹簧（响应 0.35 秒、阻尼 0.35）弹回，灯罩绕挂钩摆动 ±4° 后才停稳。未到位就松手，拉绳只是弹回。手感真实，带点怀旧，令人愉悦。"
        ),
        implementation: L(
            "An animatable line Shape draws the cord to the bead's offset; the bead follows a rubber-banded DragGesture and both spring back together. The shade uses rotationEffect(anchor: .top) kicked to 4° and released into an under-damped spring.",
            "可动画的直线 Shape 把拉绳画到拉珠的位置；拉珠跟随带橡皮筋的 DragGesture，松手后二者一起弹回。灯罩使用 rotationEffect(anchor: .top)，先被踢到 4° 再交给欠阻尼弹簧回稳。"
        ),
        apis: ["DragGesture", "Shape", "animatableData", "rotationEffect(_:anchor:)", "sensoryFeedback"],
        tags: ["pull cord", "lamp", "switch", "toggle", "skeuomorphic", "拉绳", "台灯", "开关", "拟物"],
        params: [
            .slider("threshold", L("Click distance", "触发距离"), 30...90, default: 50, step: 1, decimals: 0, unit: "pt"),
            .slider("damping", L("Cord bounce damping", "拉绳回弹阻尼"), 0.15...0.9, default: 0.35),
        ]
    ) { ctx in
        PullCordDemo(ctx: ctx)
    }
}

private let cordAnchor = CGPoint(x: 34, y: -92)
private let cordRest: CGFloat = 90

private struct CordLine: Shape {
    var end: CGPoint

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(end.x, end.y) }
        set { end = CGPoint(x: newValue.first, y: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX + cordAnchor.x, y: rect.midY + cordAnchor.y))
        path.addLine(to: CGPoint(x: rect.midX + end.x, y: rect.midY + end.y))
        return path
    }
}

private struct LampShade: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.28
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PullCordDemo: View {
    let ctx: DemoContext
    @State private var pull: CGSize = .zero
    @State private var dragging = false
    @State private var isOn = false
    @State private var sway: Double = 0

    var body: some View {
        let armed = pull.height >= ctx.cg("threshold")
        let end = CGPoint(x: cordAnchor.x + pull.width, y: cordAnchor.y + cordRest + pull.height)
        ZStack {
            lightCone
            room
            lamp
                .rotationEffect(.degrees(sway), anchor: .top)
            CordLine(end: end)
                .stroke(Color.primary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            bead(armed: armed)
                .offset(x: end.x, y: end.y + 9)
                .gesture(dragGesture)
        }
        .frame(width: 320, height: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.8), trigger: armed) { _, newValue in
            newValue && !ctx.isPreview
        }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Pull the bead down", "向下拉动拉珠"), ctx: ctx)
                .padding(.bottom, 4)
        }
        .autoplay(ctx.isPreview, every: 2.2) { simulate() }
    }

    private var lamp: some View {
        VStack(spacing: -6) {
            Rectangle()
                .fill(Color.primary.opacity(0.4))
                .frame(width: 2, height: 40)
            LampShade()
                .fill(LinearGradient(colors: [Palette.coral, Palette.pink], startPoint: .top, endPoint: .bottom))
                .frame(width: 110, height: 52)
                .zIndex(1)
            Circle()
                .fill(isOn ? AnyShapeStyle(RadialGradient(colors: [.white, Palette.amber], center: .center, startRadius: 1, endRadius: 14)) : AnyShapeStyle(Color.gray.opacity(0.4)))
                .frame(width: 26, height: 26)
                .shadow(color: Palette.amber.opacity(isOn ? 0.9 : 0), radius: 30)
        }
        .offset(y: -128)
    }

    private var lightCone: some View {
        LampShade()
            .fill(LinearGradient(colors: [Palette.amber.opacity(0.4), Palette.amber.opacity(0)], startPoint: .top, endPoint: .bottom))
            .frame(width: 300, height: 220)
            .offset(y: 30)
            .opacity(isOn ? 1 : 0)
            .allowsHitTesting(false)
    }

    private var room: some View {
        VStack(spacing: 4) {
            Image(systemName: "sofa.fill")
                .font(.system(size: 40))
                .foregroundStyle(isOn ? AnyShapeStyle(Palette.coral) : AnyShapeStyle(Color.primary.opacity(0.18)))
            Text(isOn ? (ctx.language == .zh ? "开" : "ON") : (ctx.language == .zh ? "关" : "OFF"))
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
        }
        .offset(x: -40, y: 90)
    }

    private func bead(armed: Bool) -> some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .top, endPoint: .bottom))
            .frame(width: 18, height: 18)
            .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            .scaleEffect(armed ? 1.25 : (dragging ? 1.1 : 1))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: armed)
            .padding(14)
            .contentShape(Circle())
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !dragging { dragging = true }
                pull = CGSize(
                    width: rubberBand(value.translation.width, limit: 24),
                    height: value.translation.height > 0 ? rubberBand(value.translation.height, limit: 120, coefficient: 0.9) : rubberBand(value.translation.height, limit: 12)
                )
            }
            .onEnded { _ in release() }
    }

    private func release() {
        let armed = pull.height >= ctx.cg("threshold")
        dragging = false
        withAnimation(.spring(response: 0.35, dampingFraction: ctx["damping"])) { pull = .zero }
        guard armed else { return }
        withAnimation(.easeInOut(duration: 0.35)) { isOn.toggle() }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.9)) { sway = 4 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.12))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.25)) { sway = 0 }
        }
    }

    private func simulate() {
        withAnimation(.easeIn(duration: 0.4)) {
            pull = CGSize(width: CGFloat.random(in: -8...8), height: ctx.cg("threshold") + 30)
            dragging = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            release()
        }
    }
}
