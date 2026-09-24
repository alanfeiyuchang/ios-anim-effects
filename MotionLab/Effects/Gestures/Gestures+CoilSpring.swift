import SwiftUI

extension Effect {
    static let gesturesCoilSpring = Effect(
        id: "gestures.coil-spring",
        category: .gestures,
        interaction: .gesture,
        name: L("Hooke's Coil Spring", "胡克弹簧振子"),
        summary: L("Pull a weight hanging from a coil spring and watch it bob with real mass, stiffness and damping.", "拉下挂在弹簧上的砝码，看它按真实的质量、劲度与阻尼上下振荡。"),
        prompt: L(
            "A 64×56 pt weight (continuous 16 pt corners, indigo-to-violet gradient, “1 kg” label) hangs from a ceiling bar on a steel-grey coil spring of nine turns, 130 pt long at rest. The weight drags vertically only, rubber-banded toward 150 pt of stretch and 90 pt of compression, and the coil redraws every frame, its turns spreading as it lengthens and its diameter narrowing up to 25% to conserve volume, while a pointer on a tick ruler tracks the weight. On release a physical spring with mass 1, stiffness 90 and damping 3.5 (ζ ≈ 0.18) takes over, so the weight bobs through the rest line five or six times at about 1.5 Hz before settling, with a light or rigid haptic scaled to the pull. Tactile lab physics.",
            "一个64×56 pt的砝码（16 pt圆角，靛紫渐变，标着“1 kg”）由一根9圈钢灰色螺旋弹簧挂在横梁上，弹簧自然长130 pt。砝码只能竖直拖动，拉伸和压缩都带橡皮筋阻尼，分别趋近150 pt和90 pt；弹簧每帧重绘，拉长时圈距拉开、直径最多收窄25%以保持体积，右侧刻度指针同步示位。松手后由质量1、劲度90、阻尼3.5（阻尼比约0.18）的物理弹簧接管，砝码以约1.5 Hz穿过平衡位置五六次才停稳，并按幅度给出轻或硬的触感。如指尖上的物理实验。"
        ),
        implementation: L(
            "An Animatable coil Shape redraws its zigzag from the current length; release uses Animation.interpolatingSpring(mass:stiffness:damping:), so the three physical constants are exposed directly as parameters.",
            "可动画的弹簧 Shape 根据当前长度重绘折线；松手使用 Animation.interpolatingSpring(mass:stiffness:damping:)，三个物理常数直接作为参数开放。"
        ),
        apis: ["interpolatingSpring(mass:stiffness:damping:)", "Shape", "animatableData", "DragGesture", "rubberBand"],
        tags: ["spring", "hooke", "oscillation", "physics", "弹簧", "胡克定律", "振荡", "物理"],
        params: [
            .slider("mass", L("Mass", "质量"), 0.4...3.0, default: 1),
            .slider("stiffness", L("Stiffness", "劲度"), 30...300, default: 90, step: 1, decimals: 0),
            .slider("damping", L("Damping", "阻尼"), 0.5...20, default: 3.5, decimals: 1),
        ]
    ) { ctx in
        CoilSpringDemo(ctx: ctx)
    }
}

private let coilCeilingY: CGFloat = -140
private let coilRestLength: CGFloat = 130

private struct CoilShape: Shape {
    var length: CGFloat
    let turns: Int
    let diameter: CGFloat

    var animatableData: CGFloat {
        get { length }
        set { length = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let lead: CGFloat = 12
        let top = CGPoint(x: rect.midX, y: rect.midY + coilCeilingY)
        let usable: CGFloat = max(length - lead * 2, 8)
        let ratio: CGFloat = (coilRestLength / max(length, 1)).squareRoot()
        let width: CGFloat = diameter * min(max(ratio, 0.75), 1.2)
        let segments = turns * 2
        let pitch: CGFloat = usable / CGFloat(segments)
        var path = Path()
        path.move(to: top)
        path.addLine(to: CGPoint(x: top.x, y: top.y + lead))
        for index in 0..<segments {
            let side: CGFloat = index % 2 == 0 ? 1 : -1
            let y: CGFloat = top.y + lead + pitch * (CGFloat(index) + 0.5)
            path.addLine(to: CGPoint(x: top.x + side * width / 2, y: y))
        }
        path.addLine(to: CGPoint(x: top.x, y: top.y + lead + usable))
        path.addLine(to: CGPoint(x: top.x, y: top.y + length))
        return path
    }
}

private struct CoilSpringDemo: View {
    let ctx: DemoContext
    @State private var stretch: CGFloat = 0
    @State private var dragging = false
    /// True while a real finger holds the weight.
    @State private var held = false
    /// The scripted pull, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the spring stretched.
    @GestureState private var pressing = false

    var body: some View {
        let length = coilRestLength + stretch
        let weightY = coilCeilingY + length + 28
        ZStack {
            ruler
            Capsule()
                .fill(Color.primary.opacity(0.7))
                .frame(width: 120, height: 8)
                .offset(y: coilCeilingY - 4)
            CoilShape(length: length, turns: 9, diameter: 44)
                .stroke(
                    LinearGradient(colors: [Color.gray.opacity(0.95), Color.gray.opacity(0.55)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            weight
                .offset(y: weightY)
                .gesture(dragGesture)
            pointer
                .offset(x: 110, y: weightY)
        }
        .frame(width: 320, height: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Pull the weight down and let go", "把砝码往下拉再松手"), ctx: ctx)
                .padding(.bottom, 4)
        }
        .autoplay(ctx.isPreview, every: 3.6, delay: 0.4) { simulate() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold(completed: false) }
        }
        .onDisappear { script?.cancel() }
    }

    private var weight: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Palette.primary)
            .frame(width: 64, height: 56)
            .overlay {
                Text(verbatim: "1 kg")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay(alignment: .top) {
                Circle()
                    .strokeBorder(Color.gray, lineWidth: 3)
                    .frame(width: 14, height: 14)
                    .offset(y: -9)
            }
            .scaleEffect(dragging ? 1.05 : 1)
            .shadow(color: Palette.indigo.opacity(0.35), radius: dragging ? 16 : 10, y: dragging ? 10 : 6)
    }

    private var ruler: some View {
        VStack(spacing: 9) {
            ForEach(0..<24, id: \.self) { index in
                Capsule()
                    .fill(Color.primary.opacity(index % 4 == 0 ? 0.35 : 0.15))
                    .frame(width: index % 4 == 0 ? 16 : 9, height: 1.5)
                    .frame(width: 16, alignment: .trailing)
            }
        }
        .offset(x: 130)
    }

    private var pointer: some View {
        Image(systemName: "arrowtriangle.right.fill")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Palette.violet)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { dragging = true }
                }
                let dy = value.translation.height
                stretch = dy >= 0 ? rubberBand(dy, limit: 150, coefficient: 0.8) : rubberBand(dy, limit: 90, coefficient: 0.8)
            }
            .onEnded { _ in endHold(completed: true) }
    }

    /// Release or system cancellation (silent, no haptic): the weight springs back to rest.
    private func endHold(completed: Bool) {
        guard held else { return }
        held = false
        release(haptic: completed)
    }

    private func release(haptic: Bool) {
        let pulled = abs(stretch)
        withAnimation(.interpolatingSpring(mass: ctx["mass"], stiffness: ctx["stiffness"], damping: ctx["damping"])) {
            stretch = 0
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dragging = false }
        if haptic && !ctx.isPreview && pulled > 20 {
            Haptics.tap(pulled > 70 ? .rigid : .light)
        }
    }

    private func simulate() {
        guard !held else { return }
        withAnimation(.easeInOut(duration: 0.55)) {
            stretch = CGFloat.random(in: 70...100)
            dragging = true
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled else { return }
            release(haptic: false)
        }
    }
}
