import SwiftUI

extension Effect {
    static let morphIslandExpand = Effect(
        id: "morph.island-expand",
        category: .morph,
        interaction: .tap,
        name: L("Island Expand", "灵动岛展开"),
        summary: L(
            "A black status pill stretches sideways first, then drops down into a live-activity card.",
            "黑色状态胶囊先横向拉宽、再向下展开为实时活动卡片。"
        ),
        prompt: L(
            "A 126 × 37 pt black capsule sits at the top of the screen showing a compact ride status (car glyph, \"4m\"). A tap expands it on two axes in sequence: the width springs out to 300 pt first (response ≈0.42 s, damping 0.72, a small sideways overshoot), then ≈90 ms later the height drops to 156 pt on a slightly softer spring while the corner radius grows from 18.5 to 42 pt. At ≈0.23 s (two stagger steps) the compact glyphs cross-fade out over 0.3 s as the expanded content — driver row, a large \"4 min\" and a progress track — fades in with an 8 pt blur-to-sharp and a 90% → 100% scale anchored at the top. Collapsing runs in reverse. One elastic piece of hardware, not a view swap.",
            "屏幕顶部一枚 126 × 37pt 的黑色胶囊，显示紧凑的行程状态（车辆图标与「4m」）。点击后按两个轴依次展开：宽度先以弹簧（响应约 0.42 秒、阻尼 0.72，带一点横向过冲）拉到 300pt，约 90 毫秒后高度再以稍柔的弹簧下拉到 156pt，圆角同时从 18.5pt 增至 42pt。约 0.23 秒后，紧凑图标用 0.3 秒交叉淡出，展开内容（司机信息行、大号「4 分钟」与进度条）同时出现，带 8pt 模糊到清晰、以顶部为锚点 90% → 100% 的缩放。收起时顺序相反。整体像一块有弹性的硬件，而非视图替换。"
        ),
        implementation: L(
            "Three booleans (wide, tall, content) are each flipped in their own withAnimation with increasing delays; the capsule is a RoundedRectangle whose frame and corner radius follow them, clipping two content layers that cross-fade with blur and scale.",
            "三个布尔值（宽、高、内容）分别在各自带递增延迟的 withAnimation 中切换；胶囊是一个 RoundedRectangle，其尺寸与圆角随之变化，并裁切两层以模糊和缩放交叉淡入的内容。"
        ),
        apis: ["withAnimation", "spring(response:dampingFraction:)", "RoundedRectangle", "clipShape", "blur(radius:)"],
        tags: ["dynamic island", "live activity", "expand", "morph", "灵动岛", "实时活动", "展开", "形变"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.72),
            .slider("stagger", L("Axis stagger", "轴向错峰"), 0.0...0.25, default: 0.09, unit: "s"),
        ]
    ) { ctx in
        IslandExpandDemo(ctx: ctx)
    }
}

private struct IslandExpandDemo: View {
    let ctx: DemoContext
    @State private var wide = false
    @State private var tall = false
    @State private var showContent = false

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still thumbnail: the expanded live-activity card rather than a bare pill on an empty canvas.
        let seeded: Bool = ctx.isStill
        _wide = State(initialValue: seeded)
        _tall = State(initialValue: seeded)
        _showContent = State(initialValue: seeded)
    }

    var body: some View {
        VStack(spacing: 0) {
            island
                .padding(.top, 30)
            Spacer(minLength: 0)
            DemoHint(text: L("Tap the island", "点击灵动岛"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.9) { toggle() }
    }

    private var island: some View {
        let width: CGFloat = wide ? 300 : 126
        let height: CGFloat = tall ? 156 : 37
        let radius: CGFloat = tall ? 42 : 18.5
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return ZStack(alignment: .top) {
            shape.fill(Color.black)
            compact
                .frame(width: width, height: 37)
                .opacity(showContent ? 0 : 1)
            expanded
                .frame(width: 300, height: 156)
                .opacity(showContent ? 1 : 0)
                .blur(radius: showContent ? 0 : 8)
                .scaleEffect(showContent ? 1 : 0.9, anchor: .top)
        }
        .frame(width: width, height: height, alignment: .top)
        .clipShape(shape)
        .shadow(color: .black.opacity(0.25), radius: tall ? 18 : 6, y: tall ? 10 : 3)
        .contentShape(shape)
        .onTapGesture { toggle() }
    }

    private var compact: some View {
        HStack {
            Image(systemName: "car.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.green)
            Spacer()
            Text(verbatim: "4m")
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Palette.green)
        }
        .padding(.horizontal, 14)
    }

    private var expanded: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Palette.green.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Arriving in", "即将到达"), ctx.language)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(L("Grey sedan · 7KD 214", "灰色轿车 · 7KD 214"), ctx.language)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(L("4 min", "4 分钟"), ctx.language)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Palette.green)
            }
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule().fill(Palette.green).frame(width: 170)
            }
            .frame(height: 6)
            HStack {
                Text(L("Pickup at Main St.", "在主街上车"), ctx.language)
                Spacer()
                Image(systemName: "phone.fill")
                Image(systemName: "message.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func toggle() {
        let response = ctx["response"]
        let damping = ctx["damping"]
        let lag = ctx["stagger"]
        if !ctx.isPreview { Haptics.tap(wide ? .light : .medium) }
        if !wide {
            withAnimation(.spring(response: response, dampingFraction: damping)) { wide = true }
            withAnimation(.spring(response: response * 1.1, dampingFraction: min(damping + 0.06, 1)).delay(lag)) { tall = true }
            withAnimation(.easeOut(duration: 0.3).delay(lag * 2 + 0.05)) { showContent = true }
        } else {
            withAnimation(.easeIn(duration: 0.14)) { showContent = false }
            withAnimation(.spring(response: response, dampingFraction: 0.86).delay(0.05)) { tall = false }
            withAnimation(.spring(response: response, dampingFraction: damping).delay(0.05 + lag)) { wide = false }
        }
    }
}
