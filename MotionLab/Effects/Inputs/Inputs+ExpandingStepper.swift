import SwiftUI

extension Effect {
    static let inputsExpandingStepper = Effect(
        id: "inputs.expanding-stepper",
        category: .inputs,
        interaction: .tap,
        name: L("Expanding Quantity Stepper", "展开式数量步进器"),
        summary: L("A plus button unfurls into a full stepper, then tucks back into a count badge when idle.", "加号按钮展开成完整步进器，闲置后又收回成数量角标。"),
        prompt: L(
            "A menu row (Oat Latte, price, thumbnail) ending in a 38 pt circular + button. Tapping it adds one item and unfurls the button leftward into a 120 pt capsule stepper — minus, count, plus — on a spring (response 0.42 s, damping 0.72); the minus and the number slide in from the right edge and fade up, trailing the growing capsule. Further taps roll the digits vertically. After 2 s without interaction the capsule retracts into a 38 pt filled circle that shows only the count, which pops in with a quick scale overshoot; tapping the badge reopens the stepper. Decrementing to zero collapses straight back to the + button. Space-saving, discoverable and fluid, like modern delivery apps.",
            "一条菜单项（燕麦拿铁、价格、缩略图）末尾是一个 38pt 的圆形 + 按钮。点击会加入一件商品，并让按钮以弹簧（响应 0.42 秒、阻尼 0.72）向左展开成 120pt 的胶囊步进器——减号、数量、加号；减号与数字从右侧边缘滑入并淡出显现，紧随不断变宽的胶囊。之后的点击会让数字纵向滚动。闲置 2 秒后，胶囊收缩为一个 38pt 的实心圆，只显示数量，数字以快速过冲的缩放弹出；点击角标即可再次展开。减到 0 时直接收回为 + 按钮。节省空间、易于发现、流畅自然，就像现代外卖应用。"
        ),
        implementation: L(
            "One capsule's frame width animates between collapsed and expanded states on a spring; the minus and count use a combined move(edge: .trailing) + opacity transition, and a generation-stamped Task collapses it after the idle delay.",
            "一个胶囊的宽度在收起与展开之间以弹簧动画切换；减号与数量使用 move(edge: .trailing) 与透明度组合过渡，带代次标记的 Task 在闲置延迟后将其收起。"
        ),
        apis: ["frame(width:)", "transition(.move(edge:).combined(with:))", "contentTransition(.numericText)", "Task.sleep"],
        tags: ["stepper", "quantity", "cart", "expand", "步进器", "数量", "购物车", "展开"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Spring damping", "弹簧阻尼"), 0.4...1.0, default: 0.72),
            .slider("idle", L("Collapse after", "闲置收起"), 0.8...4, default: 2, unit: "s"),
        ]
    ) { ctx in
        ExpandingStepperDemo(ctx: ctx)
    }
}

private struct ExpandingStepperDemo: View {
    let ctx: DemoContext
    @State private var count = 0
    @State private var expanded = false
    @State private var generation = 0
    @State private var step = 0

    private let collapsedSize: CGFloat = 38
    private let expandedWidth: CGFloat = 120
    private static let script: [Int] = [1, 1, 1, 0, 0, 0, 0, 2, 0, -1, -1, -1, 0, 0]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap +, then wait", "点击 +，然后稍等"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.6, delay: 0.4) { previewTick() }
    }

    private var spring: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    private var card: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xC89B6D), Color(hex: 0x8A5A3B)], startPoint: .top, endPoint: .bottom))
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "cup.and.saucer.fill").foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 3) {
                Text(L("Oat Latte", "燕麦拿铁"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(verbatim: ctx.language == .zh ? "¥28" : "$4.80")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            stepper
        }
        .padding(16)
        .frame(width: 316)
        .demoCard(cornerRadius: 24)
    }

    private var stepper: some View {
        let width: CGFloat = expanded ? expandedWidth : collapsedSize
        return ZStack(alignment: .trailing) {
            Capsule()
                .fill(expanded ? AnyShapeStyle(Palette.indigo.opacity(0.12)) : AnyShapeStyle(Palette.primary))
            HStack(spacing: 0) {
                if expanded {
                    roundButton("minus", filled: false) { change(-1) }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    Text("\(count)")
                        .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(value: Double(count)))
                        .frame(maxWidth: .infinity)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    roundButton("plus", filled: true) { change(1) }
                } else if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: collapsedSize, height: collapsedSize)
                        .contentShape(Circle())
                        .onTapGesture { reopen() }
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: collapsedSize, height: collapsedSize)
                        .contentShape(Circle())
                        .onTapGesture { change(1) }
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
        }
        .frame(width: width, height: collapsedSize)
        .clipShape(Capsule())
        .shadow(color: Palette.indigo.opacity(expanded ? 0 : 0.3), radius: 8, y: 4)
    }

    private func roundButton(_ symbol: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(filled ? Color.white : Palette.indigo)
                .frame(width: 30, height: 30)
                .background {
                    Circle().fill(filled ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Color.clear))
                }
                .frame(width: collapsedSize, height: collapsedSize)
                .contentShape(Circle())
        }
        .buttonStyle(ExpandingStepperPressStyle())
    }

    private func change(_ delta: Int) {
        let target = max(count + delta, 0)
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(spring) {
            count = target
            expanded = target > 0
        }
        scheduleCollapse()
    }

    private func reopen() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(spring) { expanded = true }
        scheduleCollapse()
    }

    private func scheduleCollapse() {
        generation += 1
        let current = generation
        let idle = ctx["idle"]
        Task {
            try? await Task.sleep(for: .seconds(idle))
            guard current == generation else { return }
            withAnimation(spring) { expanded = false }
        }
    }

    private func previewTick() {
        let action = Self.script[step % Self.script.count]
        step += 1
        switch action {
        case 1: change(1)
        case -1: if count > 0 { change(-1) }
        case 2: if count > 0 { reopen() }
        default: break
        }
    }
}

private struct ExpandingStepperPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
