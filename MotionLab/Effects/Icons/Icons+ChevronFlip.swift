import SwiftUI

extension Effect {
    static let iconsChevronFlip = Effect(
        id: "icons.chevron-flip",
        category: .icons,
        interaction: .tap,
        name: L("Chevron Arm Flip", "箭头折翼翻转"),
        summary: L("The chevron's arms fold through a flat line instead of spinning, as a row expands.", "箭头两翼穿过一条直线折向另一边，而不是整体旋转，同时列表行展开。"),
        prompt: L(
            "An order-details row shows a title, a subtitle and a 34 pt chevron disc. Tapping the row expands three detail lines below it, and the chevron morphs from pointing down to pointing up by folding its arms: the joint travels upward while the two arm tips move down, passing through a perfectly flat line at the midpoint, on a spring (response 0.42 s, damping 0.6) that slightly over-folds before settling. The detail lines drop in 40 ms apart with a fade and 8 pt slide, and collapse in reverse. The alternative Rotate style spins the whole chevron 180° for comparison. A light haptic marks each toggle. Folding reads as the arrow physically changing its mind — lighter and more organic than a spin.",
            "一行订单详情包含标题、副标题和一个 34 pt 的箭头圆钮。点击这一行，下方展开三行详情，同时箭头从朝下「折」成朝上：连接点向上移动、两个翼尖向下移动，在中点恰好成为一条水平直线，使用弹簧（响应 0.42 秒、阻尼 0.6），会略微折过头再稳住。详情行以 40 毫秒间隔淡入并下滑 8 pt，收起时倒序离场。可切换的「旋转」样式则把整个箭头转 180°，便于对比。每次切换伴随轻触感。折翼让箭头像是真的「改变了主意」——比整体旋转更轻盈、更有机。"
        ),
        implementation: L(
            "An Animatable Shape draws the chevron from a single bend value (1 = down, 0 = flat, −1 = up) and is stroked with round caps; the spring interpolates the bend, and the detail rows are inserted through a ForEach with staggered asymmetric transitions.",
            "Animatable Shape 根据一个弯折值（1 为朝下、0 为直线、−1 为朝上）绘制箭头，并以圆头描边；弹簧对弯折值插值，详情行经由 ForEach 插入，使用错开的非对称过渡。"
        ),
        apis: ["Shape", "animatableData", "StrokeStyle", "transition", "spring(response:dampingFraction:)"],
        tags: ["chevron", "disclosure", "accordion", "expand", "箭头", "折叠", "展开", "手风琴"],
        params: [
            .choice("style", L("Style", "样式"), [L("Fold arms", "折翼"), L("Rotate", "旋转")], default: 0),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.9, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.6),
        ]
    ) { ctx in
        ChevronFlipDemo(ctx: ctx)
    }
}

/// bend 1 = "∨", 0 = "—", −1 = "∧".
private struct ChevronShape: Shape {
    var bend: CGFloat

    var animatableData: CGFloat {
        get { bend }
        set { bend = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let depth: CGFloat = rect.height / 2 * bend
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - depth))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY + depth))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - depth))
        return path
    }
}

private struct ChevronFlipDemo: View {
    let ctx: DemoContext
    @State private var open = false

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

    private var details: [(LocalizedText, LocalizedText)] {
        [
            (L("Items", "商品"), L("2 × Trail runners", "2 × 越野跑鞋")),
            (L("Delivery", "配送"), L("Thu, 14:00–16:00", "周四 14:00–16:00")),
            (L("Total", "合计"), L("$248.00", "¥1,688.00")),
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                header
                    .padding(.bottom, 4)
                detailRows
            }
            .padding(16)
            .frame(width: 290, alignment: .top)
            .demoCard()
            .frame(height: 250, alignment: .top)
            DemoHint(text: L("Tap the row", "点击这一行"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { toggle() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Palette.coral.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(L("Order #4721", "订单 #4721"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                Text(L("Arriving Thursday", "预计周四送达"), ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            chevron
        }
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
    }

    private var chevron: some View {
        let rotate = ctx.int("style") == 1
        let bend: CGFloat = rotate ? 1 : (open ? -1 : 1)
        return ChevronShape(bend: bend)
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .frame(width: 13, height: 7)
            .rotationEffect(.degrees(rotate && open ? 180 : 0))
            .frame(width: 34, height: 34)
            .background(Color.primary.opacity(0.07), in: Circle())
            .animation(spring, value: open)
    }

    private var visibleRows: [Int] { open ? Array(details.indices) : [] }

    private var detailRows: some View {
        ForEach(visibleRows, id: \.self) { index in
            HStack {
                Text(details[index].0, ctx.language)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(details[index].1, ctx.language)
                    .fontWeight(.semibold)
            }
            .font(.footnote)
            .transition(rowTransition(index))
        }
    }

    private func rowTransition(_ index: Int) -> AnyTransition {
        let slide = AnyTransition.opacity.combined(with: .offset(y: -8))
        let inDelay: Double = Double(index) * 0.04
        let outDelay: Double = Double(details.count - 1 - index) * 0.04
        return .asymmetric(
            insertion: slide.animation(spring.delay(inDelay)),
            removal: slide.animation(.easeIn(duration: 0.15).delay(outDelay))
        )
    }

    private func toggle() {
        Haptics.tap(.light)
        withAnimation(spring) {
            open.toggle()
        }
    }
}
