import SwiftUI

extension Effect {
    static let gesturesElasticTether = Effect(
        id: "gestures.elastic-tether",
        category: .gestures,
        interaction: .gesture,
        name: L("Elastic Band Launcher", "弹力皮筋发射"),
        summary: L("A stone in a pouch between two fork posts: bands sag when slack, thin when drawn, and fire the stone.", "弹弓叉架两柱间的皮兜夹着石子：皮筋松时下垂、拉紧变细，松手把石子射出。"),
        prompt: L(
            "A Y-shaped slingshot fork has two posts 156 pt apart; pink-to-coral elastic bands run from the post tips to a leather pouch cradling a 40 pt glossy stone, straight across at rest. Dragging the pouch draws it back with rubber-band resistance (limit 140 pt per axis). Each band reacts to its own length: shorter than its 78 pt rest it sags by 70% of the slack; stretched, it pulls straight and thins from 6 pt to 2 pt. On release the stone fires opposite the pull, flying 2.5× the draw while shrinking to 40% and fading over 0.5 s, and the empty pouch snaps through the post line on an under-damped spring (response 0.55 s, damping 0.32), oscillating two or three times. A new stone pops in 0.65 s later; a rigid haptic scales with the draw. Taut and twangy.",
            "Y形弹弓叉架的两根立柱相距156 pt，粉到珊瑚色的皮筋从柱尖连到皮兜，兜里夹着40 pt光泽石子，静止时皮筋笔直。拖动皮兜向后拉弓，带橡皮筋阻力（每轴上限140 pt）。每条皮筋按自身长度变化：短于78 pt时按松弛量的70%下垂，拉长时绷直并从6 pt变细到2 pt。松手后石子反向射出，飞出拉动距离的2.5倍，0.5秒内缩到40%并淡出；空皮兜以欠阻尼弹簧（响应0.55秒、阻尼0.32）冲过两柱连线，振荡两三次。0.65秒后新石子弹入，硬朗触感随拉动增强。紧绷而带劲。"
        ),
        implementation: L(
            "An animatable Shape draws both bands as quadratic curves to the pouch point, stroking each via path.strokedPath with a width from its own length so sag and thinning update on every spring frame; the stone rides the pouch until release, then animates to its own absolute target with a stored reload Task.",
            "可动画的 Shape 以二次曲线从两根柱尖画到皮兜位置，每条皮筋按自身长度计算线宽并通过 path.strokedPath 描边，因此下垂与变细会在弹簧的每一帧更新；石子松手前跟随皮兜，松手后飞向独立的目标位置，并由保存的重新装填 Task 复位。"
        ),
        apis: ["Shape", "animatableData", "Path.strokedPath", "DragGesture", "rubberBand", "spring(response:dampingFraction:)"],
        tags: ["launcher", "catapult", "elastic", "bungee", "拉弓", "皮筋", "弹射", "回弹"],
        params: [
            .slider("damping", L("Damping", "阻尼"), 0.15...0.9, default: 0.32),
            .slider("response", L("Spring response", "弹簧响应"), 0.3...1.0, default: 0.55, unit: "s"),
            .slider("sag", L("Slack sag", "松弛下垂"), 0.2...1.2, default: 0.7),
        ]
    ) { ctx in
        ElasticTetherDemo(ctx: ctx)
    }
}

/// Post tips and the pouch's rest point sit on this line (stage centre = origin).
private let tetherPostY: CGFloat = -40
private let tetherPostX: CGFloat = 78
private let tetherPullLimit: CGFloat = 140

/// The Y-shaped fork: a handle and two prongs ending in the post tips.
private struct TetherFork: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var fork = Path()
        fork.move(to: CGPoint(x: c.x, y: c.y + 130))
        fork.addLine(to: CGPoint(x: c.x, y: c.y + 60))
        fork.addQuadCurve(to: CGPoint(x: c.x - tetherPostX, y: c.y + tetherPostY), control: CGPoint(x: c.x - tetherPostX, y: c.y + 50))
        fork.move(to: CGPoint(x: c.x, y: c.y + 60))
        fork.addQuadCurve(to: CGPoint(x: c.x + tetherPostX, y: c.y + tetherPostY), control: CGPoint(x: c.x + tetherPostX, y: c.y + 50))
        return fork
    }
}

/// Both bands, from each post tip to the pouch. Each band sags or thins with its own length.
private struct TetherBands: Shape {
    var end: CGPoint
    let sag: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(end.x, end.y) }
        set { end = CGPoint(x: newValue.first, y: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let tip = CGPoint(x: rect.midX + end.x, y: rect.midY + end.y)
        var bands = Path()
        for side in [CGFloat(-1), CGFloat(1)] {
            let post = CGPoint(x: rect.midX + side * tetherPostX, y: rect.midY + tetherPostY)
            bands.addPath(band(from: post, to: tip))
        }
        return bands
    }

    private func band(from post: CGPoint, to tip: CGPoint) -> Path {
        let dx: CGFloat = tip.x - post.x
        let dy: CGFloat = tip.y - post.y
        let length: CGFloat = (dx * dx + dy * dy).squareRoot()
        let rest: CGFloat = tetherPostX
        let slack: CGFloat = max(rest - length, 0)
        let stretch: CGFloat = max(length - rest, 0)
        let control = CGPoint(x: (post.x + tip.x) / 2, y: (post.y + tip.y) / 2 + slack * sag)
        var cord = Path()
        cord.move(to: post)
        cord.addQuadCurve(to: tip, control: control)
        let width: CGFloat = max(6 - stretch / 25, 2)
        return cord.strokedPath(StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

private struct ElasticTetherDemo: View {
    let ctx: DemoContext
    /// Pouch displacement from its rest point.
    @State private var drag: CGSize = .zero
    @State private var dragging = false
    /// While fired, the stone's own absolute position (nil: it rides the pouch).
    @State private var stonePosition: CGPoint?
    @State private var stoneScale: CGFloat = 1
    @State private var stoneAlpha: Double = 1
    /// Reload after a shot.
    @State private var reload: Task<Void, Never>?
    /// The scripted (preview / intro) pull, cancelled on the first real touch and on disappear.
    @State private var script: Task<Void, Never>?
    /// True while a real finger holds the pouch.
    @State private var held = false
    /// Resets on system cancellation too, so a stolen touch still releases the pouch.
    @GestureState private var pressing = false

    var body: some View {
        let end = CGPoint(x: drag.width, y: tetherPostY + drag.height)
        let stone = stonePosition ?? end
        ZStack {
            TetherFork()
                .stroke(LinearGradient(colors: [Palette.indigo, Palette.violet], startPoint: .bottom, endPoint: .top), style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            postTip(-1)
            postTip(1)
            TetherBands(end: end, sag: ctx.cg("sag"))
                .fill(LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .leading, endPoint: .trailing))
            pouch
                .offset(x: end.x, y: end.y)
            stoneView
                .scaleEffect(stoneScale)
                .opacity(stoneAlpha)
                .offset(x: stone.x, y: stone.y)
                .allowsHitTesting(false)
            // Generous invisible handle on the pouch.
            Circle()
                .fill(Color.clear)
                .frame(width: 76, height: 76)
                .contentShape(Circle())
                .offset(x: end.x, y: end.y)
                .gesture(dragGesture)
        }
        .frame(width: 320, height: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Draw the pouch back and let go", "向后拉动皮兜后松手"), ctx: ctx)
                .padding(.bottom, 6)
        }
        .autoplay(ctx.isPreview, every: 2.4) { simulate() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold(completed: false) }
        }
        .onDisappear { settleNow() }
    }

    private func postTip(_ side: CGFloat) -> some View {
        Circle()
            .fill(Palette.violet)
            .frame(width: 16, height: 16)
            .offset(x: side * tetherPostX, y: tetherPostY)
    }

    private var pouch: some View {
        Capsule()
            .fill(Color(hex: 0x7A4A32))
            .frame(width: 54, height: 22)
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            .scaleEffect(dragging ? 1.06 : 1)
    }

    private var stoneView: some View {
        Circle()
            .fill(LinearGradient(colors: [Palette.pink, Palette.violet], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .center))
                    .padding(5)
            }
            .frame(width: 40, height: 40)
            .shadow(color: Palette.pink.opacity(0.4), radius: dragging ? 14 : 8, y: dragging ? 9 : 5)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    // A real touch takes over: stop the script and put a stone back in the pouch.
                    held = true
                    script?.cancel()
                    script = nil
                    reloadNow()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { dragging = true }
                }
                drag = CGSize(
                    width: rubberBand(value.translation.width, limit: tetherPullLimit),
                    height: rubberBand(value.translation.height, limit: tetherPullLimit)
                )
            }
            .onEnded { _ in endHold(completed: true) }
    }

    /// Single, guarded end of a real pull. A lift fires; a system cancellation (the touch was
    /// stolen) springs the pouch home without firing and without a haptic.
    private func endHold(completed: Bool) {
        guard held else { return }
        held = false
        if completed {
            release(haptic: true)
        } else {
            withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
                drag = .zero
                dragging = false
            }
        }
    }

    private func release(haptic: Bool) {
        let pull = drag
        let pulled: CGFloat = (pull.width * pull.width + pull.height * pull.height).squareRoot()
        let from = CGPoint(x: pull.width, y: tetherPostY + pull.height)
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            drag = .zero
            dragging = false
        }
        if pulled > 30 { fire(from: from, pull: pull) }
        if haptic && !ctx.isPreview && pulled > 30 {
            Haptics.tap(pulled > 100 ? .rigid : .light)
        }
    }

    /// The stone leaves the pouch opposite the pull, shrinking into the distance, then a new one pops in.
    private func fire(from: CGPoint, pull: CGSize) {
        let target = CGPoint(x: from.x - pull.width * 2.5, y: from.y - pull.height * 2.5)
        var start = Transaction()
        start.disablesAnimations = true
        withTransaction(start) { stonePosition = from }
        withAnimation(.easeOut(duration: 0.5)) {
            stonePosition = target
            stoneScale = 0.4
            stoneAlpha = 0
        }
        reload?.cancel()
        reload = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.65))
            guard !Task.isCancelled else { return }
            var jump = Transaction()
            jump.disablesAnimations = true
            withTransaction(jump) {
                stonePosition = nil
                stoneScale = 0.5
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                stoneScale = 1
                stoneAlpha = 1
            }
        }
    }

    /// Put a stone back in the pouch at once (a new touch, or leaving the screen).
    private func reloadNow() {
        reload?.cancel()
        reload = nil
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            stonePosition = nil
            stoneScale = 1
            stoneAlpha = 1
        }
    }

    private func settleNow() {
        script?.cancel()
        script = nil
        held = false
        reloadNow()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            drag = .zero
            dragging = false
        }
    }

    private func simulate() {
        guard !held else { return }
        reloadNow()
        let angle = Double.random(in: 1.15...1.95)
        let reach = CGFloat.random(in: 105...135)
        withAnimation(.easeOut(duration: 0.55)) {
            drag = CGSize(width: CGFloat(cos(angle)) * reach, height: CGFloat(sin(angle)) * reach)
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
