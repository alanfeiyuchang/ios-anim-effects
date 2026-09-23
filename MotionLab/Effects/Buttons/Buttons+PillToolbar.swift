import SwiftUI

extension Effect {
    static let buttonsPillToolbar = Effect(
        id: "buttons.pill-toolbar",
        category: .buttons,
        interaction: .tap,
        name: L("Pill Toolbar Expand", "胶囊工具栏展开"),
        summary: L("A round plus stretches sideways into a pill toolbar whose tools blur in one by one.", "圆形加号横向拉伸成胶囊工具栏，工具依次由模糊中浮现。"),
        prompt: L(
            "A photo-editing card with a 56 pt dark circular \"+\" button docked at its bottom-right. On tap the circle stretches leftward into a 280 pt pill on a spring (response 0.45 s, damping 0.78) while the plus rotates 45° into a close mark that stays pinned at the trailing end. Four tools (crop, adjust, filters, text) materialise inside the growing pill from right to left — each fades in from a 6 pt blur and 50% scale, 45 ms apart — so they appear to be unveiled by the expanding edge. Picking a tool bounces its glyph, lights it amber and shows its name above the photo. Closing reverses: tools blur out left-to-right and the pill retracts into the circle. A light haptic accompanies each change. Compact, tidy and fluid.",
            "一张修图卡片，右下角停靠着一枚 56pt 的深色圆形“+”按钮。点击后，圆形以弹簧（响应 0.45 秒、阻尼 0.78）向左拉伸成 280pt 的胶囊，加号旋转 45° 变为关闭符号并固定在尾端。四个工具（裁剪、调节、滤镜、文字）在不断变长的胶囊中从右到左依次浮现——每个都从 6pt 模糊、50% 缩放淡入，间隔 45 毫秒——仿佛被扩展的边缘逐一揭开。选中某个工具，图标会弹跳一下并亮起琥珀色，照片上方显示工具名称。收起时反向播放：工具从左到右模糊消失，胶囊缩回圆形。每次变化都有轻触感。紧凑、整洁、流畅。"
        ),
        implementation: L(
            "A trailing-aligned capsule animates its width with a spring; each tool reads the same open flag through its own delayed animation(_:value:) for blur, scale and opacity, with delays mirrored on close. Selection triggers symbolEffect(.bounce) and a blurReplace caption.",
            "尾端对齐的胶囊以弹簧动画改变宽度；每个工具读取同一个展开状态，并通过各自带延迟的 animation(_:value:) 驱动模糊、缩放与透明度，收起时延迟顺序镜像。选中工具时触发 symbolEffect(.bounce) 与 blurReplace 标题。"
        ),
        apis: ["animation(_:value:)", "blur(radius:)", "rotationEffect", "symbolEffect(.bounce)", "transition(.blurReplace)"],
        tags: ["toolbar", "expand", "fab", "tools", "工具栏", "展开", "悬浮按钮", "编辑"],
        params: [
            .slider("width", L("Expanded width", "展开宽度"), 220...300, default: 280, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.12, default: 0.045, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.78),
        ]
    ) { ctx in
        ButtonPillToolbarDemo(ctx: ctx)
    }
}

private struct ButtonToolbarTool {
    let symbol: String
    let name: LocalizedText
}

private struct ButtonPillToolbarDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var selected: Int?
    @State private var bounces: [Int] = [0, 0, 0, 0]
    @State private var step = 0

    private static let tools: [ButtonToolbarTool] = [
        ButtonToolbarTool(symbol: "crop.rotate", name: L("Crop", "裁剪")),
        ButtonToolbarTool(symbol: "slider.horizontal.3", name: L("Adjust", "调节")),
        ButtonToolbarTool(symbol: "camera.filters", name: L("Filters", "滤镜")),
        ButtonToolbarTool(symbol: "textformat", name: L("Text", "文字")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Tap +, then pick a tool", "点击加号，再选一个工具"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.4) { previewStep() }
    }

    private var card: some View {
        ZStack(alignment: .bottomTrailing) {
            LandscapeArt(seed: 2)
            VStack {
                caption
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            toolbar
                .padding(14)
        }
        .frame(width: 310, height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
    }

    @ViewBuilder
    private var caption: some View {
        ZStack {
            if let selected, open {
                Text(Self.tools[selected].name, ctx.language)
                    .id(selected)
                    .transition(.blurReplace)
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(selected != nil && open ? 0.35 : 0), in: Capsule())
    }

    private var toolbar: some View {
        let expanded = ctx.cg("width")
        return ZStack(alignment: .trailing) {
            Capsule()
                .fill(Color(hex: 0x16161A).opacity(0.92))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
                .frame(width: open ? expanded : 56, height: 56)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            HStack(spacing: 0) {
                ForEach(Self.tools.indices, id: \.self) { index in
                    toolButton(index)
                }
            }
            .frame(width: expanded - 56, alignment: .trailing)
            .padding(.trailing, 56)
            .allowsHitTesting(open)
            plusButton
        }
        .frame(width: expanded, height: 56, alignment: .trailing)
        .animation(.spring(response: 0.45, dampingFraction: ctx["damping"]), value: open)
    }

    private func toolButton(_ index: Int) -> some View {
        let count = Self.tools.count
        let stagger = ctx["stagger"]
        // Right-to-left on open (nearest the plus first), left-to-right on close.
        let order = open ? count - 1 - index : index
        let delay = Double(order) * stagger + (open ? 0.06 : 0)
        let isSelected = selected == index
        return Button { pick(index) } label: {
            Image(systemName: Self.tools[index].symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Palette.amber : Color.white.opacity(0.85))
                .symbolEffect(.bounce, value: bounces[index])
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(Self.tools[index].name, ctx.language))
        .blur(radius: open ? 0 : 6)
        .scaleEffect(open ? 1 : 0.5)
        .opacity(open ? 1 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(delay), value: open)
    }

    private var plusButton: some View {
        Button(action: toggle) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(open ? 45 : 0))
                .frame(width: 56, height: 56)
                .background(Palette.primary, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(SportPressStyle(scale: 0.9, dim: 0.05))
        .accessibilityLabel(Text(open ? L("Close tools", "收起工具") : L("Show tools", "展开工具"), ctx.language))
    }

    private func toggle() {
        open.toggle()
        if !open { selected = nil }
        Haptics.tap()
    }

    private func pick(_ index: Int) {
        guard open else { return }
        withAnimation(.smooth(duration: 0.25)) { selected = index }
        bounces[index] += 1
        Haptics.tap()
    }

    private func previewStep() {
        switch step % 4 {
        case 0: toggle()
        case 1: pick(1)
        case 2: pick(3)
        default: toggle()
        }
        step += 1
    }
}
