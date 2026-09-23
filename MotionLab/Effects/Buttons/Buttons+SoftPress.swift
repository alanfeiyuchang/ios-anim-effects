import SwiftUI

extension Effect {
    static let buttonsSoftPress = Effect(
        id: "buttons.soft-press",
        category: .buttons,
        interaction: .tap,
        name: L("Soft UI Press", "新拟态按压"),
        summary: L("Raised soft-plastic keys whose light and shadow flip inward when pressed.", "柔软塑料质感的凸起按键，按下时光影翻转为内凹。"),
        prompt: L(
            "A neumorphic control panel in one matte colour: a 116 pt round power key and a row of three 58 pt rounded-square keys (Wi-Fi, Bluetooth, Focus). At rest each key is extruded by two outer shadows — a pale highlight 9 pt up-left and a cool shade 9 pt down-right. On press the lighting inverts: the outer shadows cross-fade (~250 ms spring, damping 0.75) into inner shadows, so the key reads as moulded into the panel, and the key shrinks to 97%. Tapped keys latch in that sunken state and their glyph lights up in the accent gradient with a small bounce; tapping again pops them back out. A soft haptic accompanies every press. Material-first, calm and tactile, like pressing silicone.",
            "单一哑光色的新拟态控制面板：一枚 116pt 的圆形电源键，下方一排三枚 58pt 的圆角方键（无线局域网、蓝牙、专注模式）。静止时每个按键由两道外投影“挤出”——左上 9pt 的浅色高光与右下 9pt 的冷色暗影。按下时光照翻转：外投影以约 250 毫秒的弹簧（阻尼 0.75）淡变为内阴影，按键仿佛被压进面板里，并缩小到 97%。点亮的按键会保持内凹，图标变为强调色渐变并轻轻一弹；再次点击则重新鼓起。每次按压都有柔和触感。以材质为先，安静而有触感，像按在硅胶上。"
        ),
        implementation: L(
            "A ButtonStyle stacks two copies of the key shape: one filled with a colour carrying two drop shadows and one filled with color.shadow(.inner(…)).shadow(.inner(…)); isPressed or the latched state cross-fades their opacity through a spring.",
            "ButtonStyle 叠放两层同形状：一层带两道外投影，另一层用 color.shadow(.inner(…)).shadow(.inner(…)) 填充内阴影；按压或锁定状态通过弹簧交叉淡变两层的透明度。"
        ),
        apis: ["ButtonStyle", "ShadowStyle.inner", "ShapeStyle.shadow", "symbolEffect(.bounce)", "Color.adaptive"],
        tags: ["neumorphism", "soft ui", "inner shadow", "toggle", "新拟态", "内阴影", "拟物", "按压"],
        params: [
            .slider("depth", L("Extrusion depth", "凸起深度"), 4...14, default: 9, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.1...0.6, default: 0.25, unit: "s"),
            .choice("accent", L("Accent", "强调色"), [L("Indigo", "靛蓝"), L("Coral", "珊瑚"), L("Mint", "薄荷")], default: 0),
        ]
    ) { ctx in
        ButtonSoftPressDemo(ctx: ctx)
    }
}

private enum ButtonSoftTone {
    static let base = Color.adaptive(light: 0xE3E7EE, dark: 0x2A2D34)
    static let highlight = Color.adaptive(light: 0xFFFFFF, dark: 0x3A3E47)
    static let shade = Color.adaptive(light: 0xA7B3C6, dark: 0x121418)
}

private struct ButtonSoftPressDemo: View {
    let ctx: DemoContext
    @State private var on: [Bool] = [false, true, false, false]
    @State private var bounces: [Int] = [0, 0, 0, 0]
    @State private var step = 0

    private static let symbols = ["power", "wifi", "dot.radiowaves.left.and.right", "moon.fill"]

    private var accent: LinearGradient {
        let colors: [Color]
        switch ctx.int("accent") {
        case 1: colors = [Palette.amber, Palette.coral]
        case 2: colors = [Palette.mint, Palette.sky]
        default: colors = [Palette.indigo, Palette.violet]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            panel
            Spacer()
            DemoHint(text: L("Tap the keys", "点击按键"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.9, delay: 0.3) {
            toggle(step % 4)
            step += 1
        }
    }

    private var panel: some View {
        VStack(spacing: 26) {
            key(0, size: 116, corner: 58, glyph: 38)
            HStack(spacing: 22) {
                key(1, size: 58, corner: 18, glyph: 20)
                key(2, size: 58, corner: 18, glyph: 20)
                key(3, size: 58, corner: 18, glyph: 20)
            }
        }
        .padding(.vertical, 30)
        .frame(width: 290)
        .background(ButtonSoftTone.base, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
    }

    private func key(_ index: Int, size: CGFloat, corner: CGFloat, glyph: CGFloat) -> some View {
        let lit = on[index]
        return Button { toggle(index) } label: {
            Image(systemName: Self.symbols[index])
                .font(.system(size: glyph, weight: .semibold))
                .foregroundStyle(lit ? AnyShapeStyle(accent) : AnyShapeStyle(Color.secondary))
                .symbolEffect(.bounce, value: bounces[index])
        }
        .buttonStyle(
            ButtonSoftStyle(
                latched: lit,
                size: size,
                corner: corner,
                depth: ctx.cg("depth"),
                response: ctx["response"]
            )
        )
    }

    private func toggle(_ index: Int) {
        Haptics.tap(.soft)
        on[index].toggle()
        if on[index] { bounces[index] += 1 }
    }
}

private struct ButtonSoftStyle: ButtonStyle {
    let latched: Bool
    let size: CGFloat
    let corner: CGFloat
    let depth: CGFloat
    let response: Double

    func makeBody(configuration: Configuration) -> some View {
        let inset = configuration.isPressed || latched
        return configuration.label
            .frame(width: size, height: size)
            .background {
                ButtonSoftSurface(inset: inset, corner: corner, depth: depth)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: response, dampingFraction: 0.75), value: inset)
            .animation(.spring(response: response, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

private struct ButtonSoftSurface: View {
    let inset: Bool
    let corner: CGFloat
    let depth: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        let half = depth / 2
        ZStack {
            shape
                .fill(ButtonSoftTone.base)
                .shadow(color: ButtonSoftTone.shade.opacity(0.8), radius: depth, x: half, y: half)
                .shadow(color: ButtonSoftTone.highlight, radius: depth, x: -half, y: -half)
                .opacity(inset ? 0 : 1)
            shape
                .fill(
                    ButtonSoftTone.base
                        .shadow(.inner(color: ButtonSoftTone.shade.opacity(0.9), radius: depth * 0.6, x: half * 0.7, y: half * 0.7))
                        .shadow(.inner(color: ButtonSoftTone.highlight, radius: depth * 0.6, x: -half * 0.7, y: -half * 0.7))
                )
                .opacity(inset ? 1 : 0)
        }
    }
}
