import SwiftUI

extension Effect {
    static let inputsSwatchPicker = Effect(
        id: "inputs.swatch-picker",
        category: .inputs,
        interaction: .tap,
        name: L("Color Swatch Picker", "色板选择器"),
        summary: L("A selection ring glides between swatches as the preview card re-tints.", "选中圆环在色块间滑行，预览卡片随之换色。"),
        prompt: L(
            "A card-colour picker: a 250 × 150 pt payment-card preview above a row of six 34 pt colour swatches and the colour's name. Tapping a swatch sends a 44 pt outline ring gliding to it on a spring (response 0.4 s, damping 0.72) via shared geometry, while the chosen dot grows from 82% to 100% and reveals a small checkmark. The preview card cross-fades to the new two-tone gradient over 350 ms and gives a tactile flick — rotating 10° around its vertical axis and dipping to 97% before springing back — its glossy diagonal highlight catching the light as it turns. The colour name swaps with a push from the side the ring came from. A selection haptic ticks on each change. Precise, satisfying and very Apple Store.",
            "银行卡配色选择器：上方是一张 250 × 150pt 的卡片预览，下方一排六个 34pt 色块和当前颜色名称。点击某个色块，一圈 44pt 的描边选中圆环借助共享几何，以弹簧（响应 0.4 秒、阻尼 0.72）滑行到该色块；被选中的色点从 82% 放大到 100%，并浮现一个小对勾。预览卡片在 350 毫秒内交叉渐变为新的双色渐变，同时像被指尖轻弹一下——绕纵轴转 10°、缩到 97% 后弹回，斜向高光随之转动、映出光泽。颜色名称从圆环移来的方向推入切换。每次切换伴随一次选择触觉。精准、满足，颇有 Apple Store 选配的味道。"
        ),
        implementation: L(
            "The ring is a single Circle with matchedGeometryEffect rendered only behind the selected swatch; the card stacks one gradient layer per colour and fades opacities, while a keyframeAnimator keyed on the selection runs the rotation3DEffect flick.",
            "选中圆环是一枚使用 matchedGeometryEffect 的 Circle，只绘制在当前选中色块背后；卡片为每种颜色叠放一层渐变并切换透明度，由以选中项为触发器的 keyframeAnimator 驱动 rotation3DEffect 的轻弹。"
        ),
        apis: ["matchedGeometryEffect", "keyframeAnimator", "rotation3DEffect", "transition(.push(from:))", "sensoryFeedback"],
        tags: ["color picker", "swatch", "selection", "customize", "颜色选择", "色板", "选配", "选中"],
        params: [
            .slider("response", L("Ring response", "圆环响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Ring damping", "圆环阻尼"), 0.4...1.0, default: 0.72),
            .toggle("flick", L("Card flick", "卡片轻弹"), default: true),
        ]
    ) { ctx in
        InputSwatchPickerDemo(ctx: ctx)
    }
}

private struct InputSwatch {
    let name: LocalizedText
    let light: Color
    let dark: Color
}

private struct InputSwatchPickerDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var previous = 0
    @State private var flicks = 0
    @Namespace private var ns

    private static let swatches: [InputSwatch] = [
        InputSwatch(name: L("Midnight", "午夜蓝"), light: Color(hex: 0x3A3F6B), dark: Color(hex: 0x14172E)),
        InputSwatch(name: L("Indigo", "靛蓝"), light: Palette.indigo, dark: Color(hex: 0x3B3FA8)),
        InputSwatch(name: L("Lagoon", "泻湖青"), light: Palette.mint, dark: Color(hex: 0x0E7D8C)),
        InputSwatch(name: L("Sunset", "落日橙"), light: Palette.amber, dark: Palette.coral),
        InputSwatch(name: L("Rose", "玫瑰粉"), light: Palette.pink, dark: Color(hex: 0xB0306A)),
        InputSwatch(name: L("Graphite", "石墨灰"), light: Color(hex: 0x9A9AA3), dark: Color(hex: 0x3C3C43)),
    ]

    private static let previewOrder = [3, 1, 4, 2, 0, 5]

    var body: some View {
        VStack(spacing: 22) {
            card
            swatchRow
            nameLabel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: ctx.isPreview ? 0 : selected)
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.4) {
            select(Self.previewOrder[flicks % Self.previewOrder.count])
        }
    }

    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return ZStack(alignment: .topLeading) {
            ForEach(Self.swatches.indices, id: \.self) { index in
                let swatch = Self.swatches[index]
                LinearGradient(colors: [swatch.light, swatch.dark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(index == selected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.35), value: selected)
            }
            LinearGradient(colors: [Color.white.opacity(0.28), .clear, Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading) {
                HStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xF5D98B), Color(hex: 0xC9A24A)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 36, height: 27)
                    Spacer(minLength: 0)
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                Text(verbatim: "••••  4821")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(verbatim: "MOTION LEXICON")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .padding(18)
        }
        .frame(width: 250, height: 150)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
        .shadow(color: Self.swatches[selected].dark.opacity(0.4), radius: 18, y: 12)
        .keyframeAnimator(initialValue: InputSwatchFlick(), trigger: flicks) { content, flick in
            content
                .rotation3DEffect(.degrees(flick.angle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .scaleEffect(flick.scale)
        } keyframes: { _ in
            KeyframeTrack(\.angle) {
                CubicKeyframe(ctx.bool("flick") ? 10 : 0, duration: 0.12)
                SpringKeyframe(0, duration: 0.55, spring: .bouncy)
            }
            KeyframeTrack(\.scale) {
                CubicKeyframe(ctx.bool("flick") ? 0.97 : 1, duration: 0.12)
                SpringKeyframe(1, duration: 0.5, spring: .bouncy)
            }
        }
    }

    private var swatchRow: some View {
        HStack(spacing: 8) {
            ForEach(Self.swatches.indices, id: \.self) { index in
                swatchButton(index)
            }
        }
    }

    private func swatchButton(_ index: Int) -> some View {
        let swatch = Self.swatches[index]
        let isSelected = index == selected
        return Button {
            select(index)
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.75), lineWidth: 2)
                        .matchedGeometryEffect(id: "ring", in: ns)
                }
                Circle()
                    .fill(LinearGradient(colors: [swatch.light, swatch.dark], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    .frame(width: 34, height: 34)
                    .scaleEffect(isSelected ? 1 : 0.82)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
                    .scaleEffect(isSelected ? 1 : 0.3)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var nameLabel: some View {
        ZStack {
            Text(Self.swatches[selected].name, ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .id(selected)
                .transition(.push(from: selected >= previous ? .trailing : .leading))
        }
        .frame(width: 200, height: 22)
        .clipped()
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        previous = selected
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            selected = index
        }
        flicks += 1
    }
}

private struct InputSwatchFlick {
    var angle: Double = 0
    var scale: Double = 1
}
