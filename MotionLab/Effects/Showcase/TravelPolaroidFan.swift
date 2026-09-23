import SwiftUI

extension Effect {
    static let showcasePolaroidFan = Effect(
        id: "showcase.polaroid-fan",
        category: .showcase,
        interaction: .tap,
        name: L("Polaroid Fan-out", "拍立得扇形展开"),
        summary: L(
            "A messy stack of trip polaroids fans out like a hand of cards; tap one to lift it into focus.",
            "一叠随意堆放的旅行拍立得像扑克牌一样扇形展开，点其中一张即可抬起聚焦。"
        ),
        prompt: L(
            "Four cream-framed polaroids with small italic serif captions (a jotted, handwritten feel) rest in a loose stack, each with a slight irregular tilt (−5° to 6°) and a 2 pt vertical offset. On tap they fan out like a hand of cards. Each photo rotates around its bottom edge to (i − 1.5) × 10° and slides out horizontally by (i − 1.5) × 44 pt, while the outer cards drop 8 pt per step to form an arc. The cards move one after another at 40 ms intervals on a spring (response 0.5 s, damping 0.72). Tapping one card lifts it to the front: it straightens, scales to 118% and rises 18 pt with a deeper shadow, while the others shrink to 90% and dim by 25%. Tapping it again gathers everything back into the stack. It feels nostalgic, tactile and personal.",
            "四张奶油白相框的拍立得，下方配着小号衬线体说明（中文为宋体、英文为斜体，带随手记录的手写感），随意堆成一叠，每张都有一点不规则的倾斜（−5° 到 6°）和 2pt 的纵向错位。点击后它们像一手扑克牌般扇形展开。每张照片以底边为轴旋转到 (i − 1.5) × 10°，横向滑出 (i − 1.5) × 44pt，越靠外下沉越多（每级 8pt），排成一道弧线。卡片以弹簧（响应 0.5 秒、阻尼 0.72）依次移动，每张间隔 40 毫秒。点击其中一张，它会被抬到最前：摆正、放大到 118%、上移 18pt，阴影加深；其余照片缩到 90% 并压暗 25%。再点一次，所有照片收拢回一叠。整体怀旧、有手感，也很私人。"
        ),
        implementation: L(
            "Each polaroid gets a ViewModifier computing rotation (bottom anchor), offset, scale and brightness from fanned/focused state, with per-card .animation(spring.delay(index × stagger), value: fanned) and zIndex lifting the focused card.",
            "每张拍立得通过 ViewModifier 根据展开/聚焦状态计算旋转（底部锚点）、偏移、缩放与亮度，并用逐张的 .animation(spring.delay(序号 × 错峰), value: fanned) 与 zIndex 抬起聚焦卡片。"
        ),
        apis: ["ViewModifier", "rotationEffect(_:anchor:)", "zIndex", "animation(_:value:)", "brightness"],
        tags: ["polaroid", "photos", "fan", "stack", "拍立得", "照片", "扇形", "堆叠"],
        params: [
            .slider("spread", L("Fan angle", "展开角度"), 4...24, default: 10, decimals: 0, unit: "°"),
            .slider("gap", L("Fan spacing", "展开间距"), 30...80, default: 44, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0...0.12, default: 0.04, decimals: 3, unit: "s"),
        ]
    ) { ctx in
        TravelPolaroidDemo(ctx: ctx)
    }
}

// MARK: - Demo

private struct TravelPolaroidDemo: View {
    let ctx: DemoContext
    @State private var fanned = false
    @State private var focused: Int?
    @State private var step = 0

    private static let seeds = [3, 1, 2, 0]
    private static let captions: [LocalizedText] = [
        L("Wadi Rum", "瓦迪拉姆"),
        L("Nice, 7pm", "尼斯 · 傍晚"),
        L("Braies", "布拉耶斯"),
        L("Tyrol", "蒂罗尔"),
    ]

    var body: some View {
        SignatureStage {
            VStack(spacing: 22) {
                Spacer(minLength: 0)
                stack
                label
                Spacer(minLength: 0)
                DemoHint(text: L("Tap to fan out, then tap a photo", "点击展开，再点一张照片"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: collapse)
        }
        .autoplay(ctx.isPreview, every: 1.6) { autoplayStep() }
    }

    private var stack: some View {
        ZStack {
            ForEach(0..<Self.seeds.count, id: \.self) { index in
                TravelPolaroid(seed: Self.seeds[index], caption: Self.captions[index](ctx.language))
                    .modifier(
                        TravelFanPlacement(
                            index: index,
                            count: Self.seeds.count,
                            fanned: fanned,
                            focused: focused,
                            spread: ctx["spread"],
                            gap: ctx.cg("gap")
                        )
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(Double(index) * ctx["stagger"]), value: fanned)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: focused)
                    .zIndex(focused == index ? 10 : Double(index))
                    .onTapGesture { tap(index) }
            }
        }
        .frame(height: 200)
    }

    private var label: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.stack.fill")
                .foregroundStyle(Signature.accent)
            Text(ctx.language == .zh ? "夏日旅行 · 4 张回忆" : "Summer trip · 4 memories")
                .foregroundStyle(Color.white)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .signatureCard(cornerRadius: 18)
    }

    private func tap(_ index: Int) {
        if !ctx.isPreview { Haptics.tap() }
        if !fanned {
            fanned = true
        } else if focused == index {
            focused = nil
            fanned = false
        } else {
            focused = index
        }
    }

    private func collapse() {
        guard fanned else { return }
        if !ctx.isPreview { Haptics.tap(.soft) }
        focused = nil
        fanned = false
    }

    private func autoplayStep() {
        switch step % 3 {
        case 0: fanned = true
        case 1: focused = 2
        default:
            focused = nil
            fanned = false
        }
        step += 1
    }
}

// MARK: - Placement

private struct TravelFanPlacement: ViewModifier {
    let index: Int
    let count: Int
    let fanned: Bool
    let focused: Int?
    let spread: Double
    let gap: CGFloat

    private static let restTilt: [Double] = [-5, 4, -2, 6]

    private var rel: Double { Double(index) - Double(count - 1) / 2 }
    private var isFocused: Bool { focused == index }
    private var isDimmed: Bool { focused != nil && !isFocused }

    private var angle: Double {
        if !fanned { return Self.restTilt[index % Self.restTilt.count] }
        return isFocused ? 0 : rel * spread
    }

    private var x: CGFloat {
        guard fanned, !isFocused else { return 0 }
        return CGFloat(rel) * gap
    }

    private var y: CGFloat {
        if !fanned { return CGFloat(index) * -2 }
        return isFocused ? -18 : CGFloat(abs(rel)) * 8
    }

    private var scale: CGFloat {
        if isFocused { return 1.18 }
        return isDimmed ? 0.9 : 1
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(angle), anchor: .bottom)
            .offset(x: x, y: y)
            .brightness(isDimmed ? -0.25 : 0)
            .shadow(color: Color.black.opacity(isFocused ? 0.55 : 0.3), radius: isFocused ? 22 : 10, y: isFocused ? 14 : 6)
    }
}

// MARK: - Polaroid

private struct TravelPolaroid: View {
    let seed: Int
    let caption: String

    var body: some View {
        VStack(spacing: 8) {
            LandscapeArt(seed: seed)
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            Text(caption)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(Signature.ink.opacity(0.75))
                .lineLimit(1)
        }
        .padding(8)
        .padding(.bottom, 6)
        .frame(width: 128)
        .background(Signature.paper, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
