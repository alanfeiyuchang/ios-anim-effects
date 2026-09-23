import SwiftUI

extension Effect {
    static let inputsFillRating = Effect(
        id: "inputs.fill-rating",
        category: .inputs,
        interaction: .gesture,
        name: L("Precision Fill Rating", "精细填充评分"),
        summary: L("Scrub across hearts to fill them continuously; the one under your finger magnifies, then it snaps to halves.", "划过爱心即可连续填充，指尖下的那颗会放大，松手吸附到半颗。"),
        prompt: L(
            "A recipe-rating row of five 40 pt hearts with a large score readout. Dragging across them fills continuously — each heart is clipped by a pink-to-coral fill whose width tracks the finger to the point — and the heart under the finger magnifies to 125% like a loupe while its neighbours ease to 108%, all on a quick interactive spring. Releasing snaps the score to the nearest half on a spring (response 0.4 s, damping 0.7), so partial fills glide to half or whole hearts, the magnification settles back, and the score (\"3.5\") rolls with numeric digits. Any heart that becomes completely full gives a single heartbeat (100 → 118 → 100% over 350 ms) and a selection haptic. Fine-grained and honest, yet still playful.",
            "菜谱评分行：五颗 40pt 爱心与大号分数。横向拖动连续填充——每颗爱心被一层粉到珊瑚色的填充裁剪，宽度精确跟随手指；指下爱心像放大镜般放大到 125%，相邻爱心放大到 108%，均由快速交互弹簧驱动。松手后分数以弹簧（响应 0.4 秒、阻尼 0.7）吸附到最近的半分，残缺填充滑到半颗或整颗，放大回落，分数（“3.5”）滚动更新。每当一颗爱心被填满，就“心跳”一次（350 毫秒内 100 → 118 → 100%）并触发选择触觉。细腻又俏皮。"
        ),
        implementation: L(
            "Each heart overlays a filled symbol masked by a leading-aligned Rectangle whose width is clamp(rating − index, 0, 1); magnification is derived from the finger's distance, and a per-heart keyframeAnimator keyed on a fill counter produces the heartbeat.",
            "每颗爱心在底图上叠加一层填充符号，并以前缘对齐、宽度为 clamp(评分 − 序号, 0, 1) 的 Rectangle 作遮罩；放大量由手指距离推导，每颗爱心以填满计数为触发的 keyframeAnimator 产生心跳。"
        ),
        apis: ["mask", "DragGesture", "interactiveSpring", "keyframeAnimator", "contentTransition(.numericText)"],
        tags: ["rating", "hearts", "half star", "precision", "评分", "爱心", "半星", "精细"],
        params: [
            .choice("step", L("Snap step", "吸附步长"), [L("½", "½"), L("1", "1"), L("0.1", "0.1")], default: 0),
            .slider("magnify", L("Loupe scale", "放大倍数"), 1.0...1.5, default: 1.25),
            .slider("response", L("Snap response", "吸附响应"), 0.2...0.8, default: 0.4, unit: "s"),
        ]
    ) { ctx in
        FillRatingDemo(ctx: ctx)
    }
}

private struct FillRatingDemo: View {
    let ctx: DemoContext
    @State private var rating: Double = 3.5
    @State private var fingerX: CGFloat?
    @State private var beats: [Int] = Array(repeating: 0, count: 5)
    @State private var step = 0

    private let heart: CGFloat = 40
    private let spacing: CGFloat = 10
    private var rowWidth: CGFloat { heart * 5 + spacing * 4 }
    private static let previewRatings: [Double] = [4.5, 2, 3.5, 5, 1.5]

    private var snapStep: Double {
        switch ctx.int("step") {
        case 1: return 1
        case 2: return 0.1
        default: return 0.5
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Drag slowly across the hearts", "在爱心上慢慢横向拖动"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.3) { previewTick() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Rate this recipe", "给这道菜谱打分"), ctx.language)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(L("Miso Ramen", "味噌拉面"), ctx.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Palette.pink)
                    .contentTransition(.numericText(value: rating))
                    .animation(.snappy, value: rating)
            }
            hearts
        }
        .padding(18)
        .frame(width: rowWidth + 36)
        .demoCard(cornerRadius: 24)
    }

    private var hearts: some View {
        HStack(spacing: spacing) {
            ForEach(0..<5, id: \.self) { index in
                heartView(index)
            }
        }
        .frame(height: heart * 1.4)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let x: CGFloat = value.location.x.clamped(to: 0...rowWidth)
                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                        fingerX = x
                        setRating(ratingAt(x))
                    }
                }
                .onEnded { _ in release() }
        )
    }

    private func ratingAt(_ x: CGFloat) -> Double {
        let cell: CGFloat = heart + spacing
        let index: CGFloat = (x / cell).rounded(.down)
        let within: CGFloat = min((x - index * cell) / heart, 1)
        return Double(index + within).clamped(to: 0...5)
    }

    private func scale(for index: Int) -> CGFloat {
        guard let fingerX else { return 1 }
        let center: CGFloat = CGFloat(index) * (heart + spacing) + heart / 2
        let distance: CGFloat = abs(fingerX - center) / (heart + spacing)
        let extra: CGFloat = ctx.cg("magnify") - 1
        if distance < 0.5 { return 1 + extra }
        if distance < 1.5 { return 1 + extra * 0.32 }
        return 1
    }

    private func heartView(_ index: Int) -> some View {
        let fill: CGFloat = CGFloat((rating - Double(index)).clamped(to: 0...1))
        return ZStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(Color.primary.opacity(0.12))
            Image(systemName: "heart.fill")
                .foregroundStyle(LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .top, endPoint: .bottom))
                .mask(alignment: .leading) {
                    Rectangle().frame(width: heart * fill)
                }
        }
        .font(.system(size: heart * 0.86, weight: .semibold))
        .frame(width: heart, height: heart)
        .scaleEffect(scale(for: index))
        .keyframeAnimator(initialValue: 1.0, trigger: beats[index]) { content, beat in
            content.scaleEffect(beat)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                CubicKeyframe(1.18, duration: 0.12)
                SpringKeyframe(1, duration: 0.23, spring: .bouncy)
            }
        }
    }

    private func setRating(_ newValue: Double) {
        let oldFull = Int(rating.rounded(.down))
        rating = newValue
        let newFull = Int(newValue.rounded(.down))
        if newFull > oldFull {
            for index in oldFull..<newFull where index < 5 {
                beats[index] += 1
            }
            if !ctx.isPreview { Haptics.selection() }
        }
    }

    private func release() {
        let snapped = ((rating / snapStep).rounded() * snapStep).clamped(to: 0...5)
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.7)) {
            fingerX = nil
            setRating(snapped)
        }
    }

    private func previewTick() {
        let target = Self.previewRatings[step % Self.previewRatings.count]
        step += 1
        let x: CGFloat = CGFloat(target) * (heart + spacing) - spacing / 2
        withAnimation(.smooth(duration: 0.6)) {
            fingerX = x
            setRating(target - 0.2)
        }
        Task {
            try? await Task.sleep(for: .seconds(0.75))
            release()
        }
    }
}
