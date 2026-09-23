import SwiftUI

extension Effect {
    static let buttonsElasticBlob = Effect(
        id: "buttons.elastic-blob",
        category: .buttons,
        interaction: .gesture,
        name: L("Elastic Button Bar", "弹性按钮条"),
        summary: L("A liquid highlight chases the finger across a button bar, stretching with speed.", "液态高光在按钮条上追随手指，速度越快拉得越长。"),
        prompt: L(
            "A 288 × 64 pt frosted capsule holds four icon buttons (home, search, camera, profile). Wherever the finger slides, a 60 × 48 pt violet-tinted highlight blob follows it on a spring (response 0.28 s, damping 0.62). Its width stretches with the finger's horizontal speed — up to +80% at ~1500 pt/s — while its height slims by up to 25%, and the stretch is anchored on the leading edge of travel so the blob trails like a droplet; when the finger stops for 120 ms it relaxes back into a pill. The icon under the blob tints and grows to 112%. On release the blob snaps to the nearest button with a bouncy settle, that icon bounces and a selection haptic ticks. Fluid, gooey and very finger-aware.",
            "288 × 64pt 的磨砂胶囊按钮条里排着四个图标（首页、搜索、相机、个人）。一团 60 × 48pt 的淡紫色高光以弹簧（响应 0.28 秒、阻尼 0.62）追随手指：宽度随水平速度拉伸，约 1500pt/秒时加宽 80%，高度同时收窄至多 25%，并以运动前沿为锚，拖出水滴般的尾巴；手指停住 120 毫秒后缩回胶囊形。高光下的图标变色并放大到 112%。松手后高光吸附到最近的按钮、弹性落定，该图标跳一下并触发选择触感。黏稠流动，处处跟手。"
        ),
        implementation: L(
            "A DragGesture feeds location and value.velocity into a spring: position follows the finger, while scaleEffect(x:y:anchor:), anchored at the front edge of the motion, stretches the blob backwards. A generation-tagged Task relaxes the stretch once the finger rests; onEnded snaps to the nearest slot.",
            "DragGesture 把位置与 value.velocity 送入弹簧：位置跟随手指，以运动前沿为锚点的 scaleEffect(x:y:anchor:) 把高光向后拉伸。带代号的 Task 在手指停住后让拉伸复原；onEnded 吸附到最近的按钮位。"
        ),
        apis: ["DragGesture.Value.velocity", "scaleEffect(x:y:anchor:)", "spring(response:dampingFraction:)", "symbolEffect(.bounce)", "Material"],
        tags: ["blob", "elastic", "liquid", "velocity", "弹性", "液态", "速度", "高光"],
        params: [
            .slider("stretch", L("Max stretch", "最大拉伸"), 0.2...1.2, default: 0.8),
            .slider("response", L("Spring response", "弹簧响应"), 0.15...0.6, default: 0.28, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.62),
        ]
    ) { ctx in
        ButtonElasticBlobDemo(ctx: ctx)
    }
}

private struct ButtonElasticBlobDemo: View {
    let ctx: DemoContext
    @State private var blobX: CGFloat = 36
    @State private var stretch: CGFloat = 0
    @State private var leftward = false
    @State private var selected = 0
    @State private var bounces: [Int] = [0, 0, 0, 0]
    @State private var generation = 0
    @State private var step = 0
    /// One debounced relax task for the whole drag instead of one Task per touch event.
    @State private var relaxTask: Task<Void, Never>?
    /// A real finger is sliding (set on the first change, cleared on lift or cancel).
    @State private var dragging = false
    /// Resets on system cancellation too (Control Center pull, incoming call), so a cancelled touch still releases.
    @GestureState private var touching = false

    private let size = CGSize(width: 288, height: 64)
    private static let symbols = ["house.fill", "magnifyingglass", "camera.fill", "person.crop.circle.fill"]
    private static let previewOrder = [2, 0, 3, 1]

    private var slotWidth: CGFloat { size.width / 4 }
    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            bar
            Spacer()
            DemoHint(text: L("Slide along the bar, then let go", "沿按钮条滑动后松手"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { blobX = center(of: selected) }
        .autoplay(ctx.isPreview, every: 1.0, delay: 0.3) { previewStep() }
    }

    private var bar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(LinearGradient(colors: [Palette.indigo.opacity(0.9), Palette.violet.opacity(0.9)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 60, height: 48)
                .scaleEffect(x: 1 + stretch, y: 1 - stretch * 0.3, anchor: leftward ? .leading : .trailing)
                .offset(x: blobX - 30)
                .shadow(color: Palette.violet.opacity(0.4), radius: 10, y: 4)
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    icon(index)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($touching) { _, state, _ in state = true }
                .onChanged { value in
                    dragging = true
                    track(x: value.location.x, velocity: value.velocity.width)
                }
                .onEnded { value in
                    dragging = false
                    snap(to: value.location.x)
                }
        )
        .onChange(of: touching) { _, isTouching in
            if !isTouching { cancelDrag() }
        }
    }

    private func icon(_ index: Int) -> some View {
        let hovered = abs(blobX - center(of: index)) < slotWidth / 2
        return Image(systemName: Self.symbols[index])
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(hovered ? Color.white : Color.secondary)
            .scaleEffect(hovered ? 1.12 : 1)
            .symbolEffect(.bounce, value: bounces[index])
            .frame(width: slotWidth, height: size.height)
            .animation(.snappy(duration: 0.2), value: hovered)
    }

    private func center(of index: Int) -> CGFloat {
        slotWidth * (CGFloat(index) + 0.5)
    }

    private func track(x: CGFloat, velocity: CGFloat) {
        let clampedX = x.clamped(to: 30...(size.width - 30))
        let amount = min(abs(velocity) / 1500, 1) * ctx.cg("stretch")
        generation += 1
        let tag = generation
        withAnimation(spring) {
            blobX = clampedX
            stretch = amount
            if abs(velocity) > 40 { leftward = velocity < 0 }
        }
        relaxTask?.cancel()
        relaxTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled, tag == generation else { return }
            withAnimation(spring) { stretch = 0 }
        }
    }

    private func snap(to x: CGFloat) {
        let index = Int((x / slotWidth).rounded(.down)).clamped(to: 0...3)
        relaxTask?.cancel()
        relaxTask = nil
        generation += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            blobX = center(of: index)
            stretch = 0
        }
        bounces[index] += 1
        selected = index
        Haptics.selection()
    }

    /// A cancelled slide (no `onEnded`) glides the blob home to the current selection without picking anything.
    private func cancelDrag() {
        guard dragging else { return }
        dragging = false
        relaxTask?.cancel()
        relaxTask = nil
        generation += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            blobX = center(of: selected)
            stretch = 0
        }
    }

    private func previewStep() {
        let target = Self.previewOrder[step % Self.previewOrder.count]
        step += 1
        let from = blobX
        let to = center(of: target)
        leftward = to < from
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            stretch = ctx.cg("stretch") * 0.7
            blobX = to
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { stretch = 0 }
            bounces[target] += 1
            selected = target
        }
    }
}
