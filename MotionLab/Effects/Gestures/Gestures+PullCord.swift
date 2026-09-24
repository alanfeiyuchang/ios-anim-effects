import SwiftUI

extension Effect {
    static let gesturesPullCord = Effect(
        id: "gestures.pull-cord",
        category: .gestures,
        interaction: .gesture,
        name: L("Pull-Cord Switch", "拉绳开关"),
        summary: L("Tug a lamp's cord past a click point to switch it; the cord bounces back and the shade sways.", "把台灯拉绳拽过“咔哒”点即可开关，拉绳回弹、灯罩轻晃。"),
        prompt: L(
            "A pendant lamp (110 pt shade, bulb beneath) hangs at the top of the stage, with a thin cord dropping 90 pt from the shade's edge to an 18 pt bead. Dragging the bead pulls the cord down 1:1, rubber-banded toward 120 pt with a little sideways give; at 50 pt the switch arms with a rigid haptic click and the bead swells to 1.25×. Releasing while armed toggles the light: the bulb blooms amber with a 30 pt glow, a soft light cone fades in over 350 ms and the room icon below lights up, while the cord snaps back on a bouncy spring (response 0.35 s, damping 0.35) and the shade sways ±4° on its hook before settling. Releasing short just lets the cord bounce back. Tactile and nostalgic.",
            "顶部悬着一盏吊灯（110 pt灯罩下是灯泡），灯罩边缘垂下90 pt细拉绳，末端挂着18 pt的拉珠。拖动拉珠，拉绳1:1伸长，越往下阻力越大并趋近120 pt，可略微摆动；拉到50 pt时开关就绪，一下硬朗的“咔哒”触感，拉珠放大到1.25倍。就绪松手即切换灯光：灯泡亮起带30 pt光晕的琥珀色，柔和光锥在350毫秒内淡入，房间图标随之点亮；拉绳以高弹性弹簧（响应0.35秒、阻尼0.35）弹回，灯罩绕挂钩摆动±4°才停稳。没拉到位则只弹回。真实又怀旧。"
        ),
        implementation: L(
            "An animatable line Shape draws the cord to the bead's offset; the bead follows a rubber-banded DragGesture and both spring back together. Shade, cord and bead share one rotationEffect anchored at the hook, kicked to 4° and released into an under-damped spring, so the cord stays attached.",
            "可动画的直线 Shape 把拉绳画到拉珠的位置；拉珠跟随带橡皮筋的 DragGesture，松手后二者一起弹回。灯罩、拉绳与拉珠共用一个以挂钩为锚点的 rotationEffect，先被踢到 4° 再交给欠阻尼弹簧回稳，拉绳始终连在灯罩上。"
        ),
        apis: ["DragGesture", "Shape", "animatableData", "rotationEffect(_:anchor:)", "UIImpactFeedbackGenerator"],
        tags: ["pull cord", "lamp", "switch", "toggle", "拉绳", "台灯", "开关", "拟物"],
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
/// The lamp's hook, 181 pt above the centre of the 320 pt stage: shade, cord and bead swing about it together.
private let lampHook = UnitPoint(x: 0.5, y: (160.0 - 181.0) / 320.0)

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
    /// True while autoplay (or the detail intro) pulls the cord, so the scripted arm click stays silent.
    @State private var scripted = false
    /// True while a real finger holds the bead.
    @State private var held = false
    /// The scripted pull, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// The click's sway settle, cancelled by the next click or when the demo leaves.
    @State private var swayTask: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the cord pulled and armed.
    @GestureState private var pressing = false

    var body: some View {
        let armed = pull.height >= ctx.cg("threshold")
        let end = CGPoint(x: cordAnchor.x + pull.width, y: cordAnchor.y + cordRest + pull.height)
        ZStack {
            room
            rig(end: end, armed: armed)
                .rotationEffect(.degrees(sway), anchor: lampHook)
        }
        .frame(width: 320, height: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: armed) { _, newValue in
            if newValue && !ctx.isPreview && !scripted { Haptics.tap(.rigid) }
        }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Pull the bead down", "向下拉动拉珠"), ctx: ctx)
                .padding(.bottom, 4)
        }
        .autoplay(ctx.isPreview, every: 2.2) { simulate() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold(completed: false) }
        }
        .onDisappear {
            script?.cancel()
            swayTask?.cancel()
            sway = 0
        }
    }

    /// Everything that hangs from the hook, so the cord stays attached while the shade sways.
    private func rig(end: CGPoint, armed: Bool) -> some View {
        ZStack {
            lightCone
            lamp
            CordLine(end: end)
                .stroke(Color.primary.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            bead(armed: armed)
                .offset(x: end.x, y: end.y + 9)
                .gesture(dragGesture)
        }
        .frame(width: 320, height: 320)
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
            Text(isOn ? L("ON", "开") : L("OFF", "关"), ctx.language)
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
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                    dragging = true
                    scripted = false
                }
                pull = CGSize(
                    width: rubberBand(value.translation.width, limit: 24),
                    height: value.translation.height > 0 ? rubberBand(value.translation.height, limit: 120, coefficient: 0.9) : rubberBand(value.translation.height, limit: 12)
                )
            }
            .onEnded { _ in endHold(completed: true) }
    }

    /// Release, or system cancellation (the page scrolled): a cancelled pull springs back without clicking the lamp.
    private func endHold(completed: Bool) {
        guard held else { return }
        held = false
        release(canToggle: completed)
    }

    private func release(canToggle: Bool = true) {
        let armed = canToggle && pull.height >= ctx.cg("threshold")
        dragging = false
        withAnimation(.spring(response: 0.35, dampingFraction: ctx["damping"])) { pull = .zero }
        guard armed else { return }
        withAnimation(.easeInOut(duration: 0.35)) { isOn.toggle() }
        withAnimation(.spring(response: 0.18, dampingFraction: 0.9)) { sway = 4 }
        swayTask?.cancel()
        swayTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.12))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.25)) { sway = 0 }
        }
    }

    private func simulate() {
        guard !held else { return }
        scripted = true
        withAnimation(.easeIn(duration: 0.4)) {
            pull = CGSize(width: CGFloat.random(in: -8...8), height: ctx.cg("threshold") + 30)
            dragging = true
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            release()
        }
    }
}
