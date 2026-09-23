import SwiftUI

extension Effect {
    static let inputsPullCordToggle = Effect(
        id: "inputs.pull-cord-toggle",
        category: .inputs,
        interaction: .gesture,
        name: L("Pull-Cord Lamp Switch", "拉绳台灯开关"),
        summary: L("Tug a hanging cord past its click point; it springs back and the lamp floods on.", "把垂下的拉绳拽过“咔哒”点，松手弹回，台灯随之亮起。"),
        prompt: L(
            "A pendant lamp shade hangs at the top of the stage with a thin cord and a 20 pt wooden bead dangling 80 pt below it. Dragging the bead stretches the cord downward with rubber-band resistance that tightens toward ~110 pt and lets it sway sideways up to 12° from the pivot. Crossing the 38 pt click point fires a medium haptic and arms the switch; releasing snaps the cord back up on an underdamped spring (response 0.5 s, damping 0.42), so the bead bobs above its rest and swings a couple of times before settling. If armed, the lamp toggles: a warm light cone fades in beneath the shade over 350 ms, the bulb blooms and a soft pool of light spreads on the floor; switching off drops everything to dark in 200 ms. Nostalgic, tactile, with real rope physics.",
            "舞台顶部悬着吊灯灯罩，细绳末端的 20pt 木珠垂在灯罩下 80pt。拖动木珠会以渐紧的橡皮筋阻尼把绳子向下拉长（上限趋近 110pt），并允许以挂点为轴左右摆动至多 12°。拉过 38pt 的“咔哒”点时中等触觉一下并进入待触发；松手后绳子以欠阻尼弹簧（响应 0.5 秒、阻尼 0.42）弹回，木珠先弹过静止位再摆几下才停。若已触发则切换：暖色光锥 350 毫秒内在灯罩下淡入，灯泡晕开，地面铺开柔和光斑；关灯时 200 毫秒内全部暗下。怀旧，带真实绳索物理。"
        ),
        implementation: L(
            "A DragGesture feeds rubberBand(_:limit:) into the cord length and a clamped sway angle applied with rotationEffect(anchor: .top); release resets both on an underdamped spring and, past the threshold, toggles the light layers.",
            "DragGesture 通过 rubberBand(_:limit:) 计算绳长，并把限制后的摆角用 rotationEffect(anchor: .top) 施加；松手时以欠阻尼弹簧复位二者，超过阈值则切换灯光图层。"
        ),
        apis: ["DragGesture", "rubberBand", "rotationEffect(_:anchor:)", "spring(response:dampingFraction:)", "RadialGradient"],
        tags: ["toggle", "pull cord", "lamp", "light switch", "开关", "拉绳", "台灯", "物理"],
        params: [
            .slider("threshold", L("Click point", "触发距离"), 20...60, default: 38, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "回弹响应"), 0.2...0.9, default: 0.5, unit: "s"),
            .slider("damping", L("Spring damping", "回弹阻尼"), 0.2...0.9, default: 0.42),
        ]
    ) { ctx in
        PullCordToggleDemo(ctx: ctx)
    }
}

private struct PullCordToggleDemo: View {
    let ctx: DemoContext
    @State private var isOn = false
    @State private var pull: CGFloat = 0
    @State private var sway: Double = 0
    @State private var armed = false

    private let restLength: CGFloat = 80

    var body: some View {
        ZStack(alignment: .top) {
            floorGlow
            VStack(spacing: 0) {
                shade
                ZStack(alignment: .top) {
                    cone
                    cord
                }
            }
            .padding(.top, 24)
            VStack {
                Spacer()
                DemoHint(text: L("Pull the cord down and let go", "向下拉绳子再松手"), ctx: ctx)
                    .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8, delay: 0.4) { simulatePull() }
    }

    private var shade: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(isOn ? Color(hex: 0xFFE8A3) : Color.primary.opacity(0.2))
                .frame(width: 26, height: 26)
                .shadow(color: Palette.amber.opacity(isOn ? 0.9 : 0), radius: 14)
                .offset(y: 10)
            LampShadeShape()
                .fill(LinearGradient(colors: [Palette.coral, Color(hex: 0xC94A36)], startPoint: .top, endPoint: .bottom))
                .frame(width: 132, height: 58)
                .shadow(color: .black.opacity(0.18), radius: 6, y: 4)
        }
        .animation(.easeOut(duration: isOn ? 0.35 : 0.2), value: isOn)
    }

    private var cone: some View {
        LightConeShape()
            .fill(
                LinearGradient(
                    colors: [Palette.amber.opacity(0.45), Palette.amber.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 280, height: 190)
            .opacity(isOn ? 1 : 0)
            .animation(.easeOut(duration: isOn ? 0.35 : 0.2), value: isOn)
            .allowsHitTesting(false)
    }

    private var floorGlow: some View {
        VStack {
            Spacer()
            Ellipse()
                .fill(RadialGradient(colors: [Palette.amber.opacity(0.35), .clear], center: .center, startRadius: 4, endRadius: 130))
                .frame(width: 280, height: 70)
                .opacity(isOn ? 1 : 0)
                .scaleEffect(isOn ? 1 : 0.6)
                .animation(.easeOut(duration: isOn ? 0.45 : 0.2), value: isOn)
                .padding(.bottom, 36)
        }
    }

    private var cord: some View {
        let length: CGFloat = max(restLength + pull, 20)
        return VStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.45))
                .frame(width: 1.5, height: length)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xE2B07A), Color(hex: 0x9C6B3E)],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 1,
                        endRadius: 14
                    )
                )
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                .scaleEffect(armed ? 1.15 : 1)
                .padding(16)
                .contentShape(Rectangle())
                .gesture(drag)
                .padding(-16)
        }
        .rotationEffect(.degrees(sway), anchor: .top)
        .offset(x: 34)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let down: CGFloat = max(value.translation.height, 0)
                pull = rubberBand(down, limit: 110, coefficient: 0.9)
                sway = Double(-value.translation.width / 6).clamped(to: -12...12)
                let past = pull >= ctx.cg("threshold")
                if past && !armed {
                    Haptics.tap(.medium)
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { armed = true }
                } else if !past && armed {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { armed = false }
                }
            }
            .onEnded { _ in release(silent: false) }
    }

    private func release(silent: Bool) {
        let fire = armed
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            pull = 0
            sway = 0
            armed = false
        }
        if fire {
            if !ctx.isPreview && !silent { Haptics.tap() }
            isOn.toggle()
        }
    }

    private func simulatePull() {
        // Captured now: autoplay (and the detail intro) mute haptics only for the synchronous part.
        let muted = Haptics.isMuted
        let target: CGFloat = ctx.cg("threshold") + 10
        withAnimation(.easeOut(duration: 0.35)) {
            pull = target
            sway = 4
            armed = true
        }
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            release(silent: muted)
        }
    }
}

private struct LampShadeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset: CGFloat = rect.width * 0.28
        path.move(to: CGPoint(x: rect.minX + topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX - topInset * 0.3, y: rect.minY + rect.height * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 6)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topInset, y: rect.minY),
            control: CGPoint(x: rect.minX + topInset * 0.3, y: rect.minY + rect.height * 0.3)
        )
        path.closeSubpath()
        return path
    }
}

private struct LightConeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top: CGFloat = rect.width * 0.26
        path.move(to: CGPoint(x: rect.minX + top, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
