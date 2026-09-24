import SwiftUI

extension Effect {
    static let gesturesPendulumSwing = Effect(
        id: "gestures.pendulum-swing",
        category: .gestures,
        interaction: .gesture,
        name: L("Pendulum Swing Drag", "摆动拖拽"),
        summary: L("A badge carried by its lanyard hole that swings behind your finger like a pendulum.", "捏着挂孔拖动的工牌，像钟摆一样在指尖后方摆荡。"),
        prompt: L(
            "A 150×200 pt ID badge (22 pt continuous corners, elevated surface, violet header band, avatar and placeholder lines) is held by a lanyard hole at its top edge. Dragging moves the hole 1:1 while the badge pivots around it: horizontal finger velocity maps to a lag angle of up to ±28° through an under-damped spring (response 0.45 s, damping 0.4), so the badge trails behind, swings past vertical when you stop and sways back, relaxing to zero if the finger rests for 90 ms. On release it flies home on a spring (response 0.5 s, damping 0.7) while an opposite kick from the return velocity makes it swing two or three times before hanging still, with a soft haptic. Weighty, physical and charming.",
            "一张150×200 pt的工牌（22 pt连续圆角、浮起表面、紫色顶栏、头像与占位文字）被顶部的挂绳孔“捏”住。拖动时挂孔1:1跟手，工牌绕它摆动：手指的水平速度映射为最多±28°的滞后角，经欠阻尼弹簧（响应0.45秒、阻尼0.4）作用，于是工牌拖在手指后面，停下时越过竖直位置再摆回；手指静止90毫秒，角度便回到零。松手后工牌以弹簧（响应0.5秒、阻尼0.7）飞回原位，回程速度带来一记反向摆动，来回荡两三下才静静垂下，并伴随柔和触感。有分量又讨喜。"
        ),
        implementation: L(
            "rotationEffect(anchor: .top) is driven by DragGesture.Value.velocity through an under-damped spring on every change; a single cancellable relax Task resets the angle when movement stops, and release adds a counter-swing proportional to the return distance.",
            "rotationEffect(anchor: .top) 在每次拖动变化时由 DragGesture.Value.velocity 经欠阻尼弹簧驱动；单个可取消的 Task 在停止移动时让角度回零，松手时再按回程距离施加一个反向摆动。"
        ),
        apis: ["DragGesture.Value.velocity", "rotationEffect(_:anchor:)", "spring(response:dampingFraction:)", "Task.sleep"],
        tags: ["pendulum", "swing", "lanyard", "badge", "钟摆", "摆动", "工牌", "惯性"],
        params: [
            .slider("sensitivity", L("Swing sensitivity", "摆动灵敏度"), 0.3...2.0, default: 1),
            .slider("damping", L("Swing damping", "摆动阻尼"), 0.15...0.8, default: 0.4),
            .slider("maxAngle", L("Max angle", "最大角度"), 10...45, default: 28, step: 1, decimals: 0, unit: "°"),
        ]
    ) { ctx in
        PendulumSwingDemo(ctx: ctx)
    }
}

private struct PendulumSwingDemo: View {
    let ctx: DemoContext
    @State private var drag: CGSize = .zero
    @State private var angle: Double = 0
    @State private var dragging = false
    /// The one pending relax; each drag change cancels and replaces it.
    @State private var relaxTask: Task<Void, Never>?
    /// True while a real finger holds the badge.
    @State private var held = false
    /// The scripted swing, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the badge offset.
    @GestureState private var pressing = false

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Palette.violet)
                .frame(width: 12, height: 12)
                .overlay(Circle().fill(.white).frame(width: 4, height: 4))
                .zIndex(1)
                .offset(y: 8)
            PendulumBadge(language: ctx.language)
                .shadow(color: .black.opacity(dragging ? 0.2 : 0.12), radius: dragging ? 20 : 12, y: dragging ? 14 : 8)
        }
        .rotationEffect(.degrees(angle), anchor: .top)
        .offset(drag)
        .gesture(dragGesture)
        .offset(y: -12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Drag the badge side to side", "左右拖动工牌"), ctx: ctx)
                .padding(.bottom, 8)
        }
        .autoplay(ctx.isPreview, every: 2.4) { simulate() }
        .onDisappear {
            relaxTask?.cancel()
            script?.cancel()
        }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
    }

    private var swing: Animation {
        .spring(response: 0.45, dampingFraction: ctx["damping"])
    }

    private func lagAngle(forVelocity vx: CGFloat) -> Double {
        let limit = ctx["maxAngle"]
        let raw = Double(vx) / 40 * ctx["sensitivity"]
        return raw.clamped(to: -limit...limit)
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
                drag = value.translation
                withAnimation(swing) { angle = lagAngle(forVelocity: value.velocity.width) }
                relaxWhenStill()
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: the badge swings home.
    private func endHold() {
        guard held else { return }
        held = false
        release(haptic: true)
    }

    private func relaxWhenStill() {
        relaxTask?.cancel()
        relaxTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.09))
            guard !Task.isCancelled, dragging else { return }
            withAnimation(swing) { angle = 0 }
        }
    }

    private func release(haptic: Bool) {
        relaxTask?.cancel()
        // Flying home to the left means the badge lags to the right, and vice versa.
        let kick = lagAngle(forVelocity: -drag.width * 6)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            drag = .zero
            dragging = false
        }
        withAnimation(swing) { angle = kick }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.18))
            withAnimation(swing) { angle = 0 }
        }
        if haptic && !ctx.isPreview { Haptics.tap(.soft) }
    }

    private func simulate() {
        guard !held else { return }
        let side: CGFloat = Bool.random() ? 1 : -1
        withAnimation(.easeInOut(duration: 0.5)) { drag = CGSize(width: side * 90, height: 14) }
        withAnimation(swing) {
            dragging = true
            angle = lagAngle(forVelocity: side * 900)
        }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.55))
            guard !Task.isCancelled else { return }
            withAnimation(swing) { angle = 0 }
            try? await Task.sleep(for: .seconds(0.45))
            guard !Task.isCancelled else { return }
            release(haptic: false)
        }
    }
}

private struct PendulumBadge: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.1))
                .frame(width: 34, height: 8)
                .padding(.top, 14)
            Circle()
                .fill(Palette.primary)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text(L("GUEST", "访客"), language)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Palette.violet)
            PlaceholderLines(count: 2)
                .padding(.horizontal, 22)
        }
        .frame(width: 150, height: 200, alignment: .top)
        .background(alignment: .top) {
            LinearGradient(colors: [Palette.violet.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 70)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .demoCard(cornerRadius: 22)
    }
}
