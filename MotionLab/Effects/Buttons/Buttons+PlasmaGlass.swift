import SwiftUI

extension Effect {
    static let buttonsPlasmaGlass = Effect(
        id: "buttons.plasma-glass",
        category: .buttons,
        interaction: .loop,
        name: L("Plasma Glass", "等离子玻璃"),
        summary: L("Soft colour blobs swirl inside a glass capsule and bleed a matching halo.", "柔和色团在玻璃胶囊内缓缓游动，并向外晕出同色光晕。"),
        prompt: L(
            "A 230 × 64 pt glass capsule labelled \"Ask anything\". Inside it, four heavily blurred colour blobs (violet, pink, sky, mint; ~70 pt, blur 18 pt) drift on slow independent Lissajous orbits — periods between 5 and 9 s — so the fill is a living, never-repeating gradient. A glossy white top highlight, a hairline rim and a 20% white wash sell the glass. Behind it, a copy of the blob layer, blurred 26 pt more and unclipped, leaks out as a soft halo that shifts colour with the blobs. On tap the button dips to 96% on a spring, the blobs swell 35% and brighten for ~0.9 s before easing back, with a soft haptic. Dreamy, intelligent and premium — the feel of an AI entry point.",
            "一枚 230 × 64pt 的玻璃胶囊“随便问问”。胶囊内四团高度模糊的色团（紫罗兰、粉、天蓝、薄荷；约 70pt，模糊 18pt）各自沿缓慢的利萨如轨迹漂移，周期 5–9 秒，让填充成为永不重复的流动渐变。顶部白色光泽、细描边与 20% 白色蒙层塑造玻璃感。后方一份未裁切、再模糊 26pt 的色团副本外溢成柔和光晕，颜色随之变化。点击时按钮以弹簧下沉到 96%，色团膨胀 35% 并变亮，约 0.9 秒后缓缓恢复，伴随柔和触感。梦幻、聪明，很有 AI 入口的气质。"
        ),
        implementation: L(
            "A TimelineView(.animation) offsets four blurred circles along sine/cosine orbits inside a capsule clip, flattened with drawingGroup; the same layer, blurred further and unclipped, forms the halo. A tap drives a keyframeAnimator that scales the blobs and brightness.",
            "TimelineView(.animation) 让四个模糊圆沿正弦/余弦轨迹在胶囊裁切内偏移，并用 drawingGroup 合成；同一图层进一步模糊且不裁切，形成外部光晕。点击触发 keyframeAnimator，放大色团并提高亮度。"
        ),
        apis: ["TimelineView", "blur(radius:)", "drawingGroup", "keyframeAnimator", "clipShape"],
        tags: ["plasma", "glass", "ai", "gradient", "等离子", "玻璃", "渐变", "光晕"],
        params: [
            .slider("speed", L("Drift speed", "漂移速度"), 0.3...2.0, default: 1.0),
            .slider("blur", L("Blob blur", "色团模糊"), 10...30, default: 18, decimals: 0, unit: "pt"),
            .toggle("halo", L("Outer halo", "外部光晕"), default: true),
        ]
    ) { ctx in
        ButtonPlasmaGlassDemo(ctx: ctx)
    }
}

private struct ButtonPlasmaBlob {
    let color: Color
    let periodX: Double
    let periodY: Double
    let phase: Double
}

private struct ButtonPlasmaGlassDemo: View {
    let ctx: DemoContext
    @State private var taps = 0

    private let size = CGSize(width: 230, height: 64)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 26) {
                Text(L("What should we plan today?", "今天想计划点什么？"), ctx.language)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                button
            }
            Spacer()
            DemoHint(text: L("Tap the glass button", "点击玻璃按钮"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.4, delay: 0.8) { tap() }
    }

    private var button: some View {
        Button(action: tap) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let t: Double = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600) * ctx["speed"]
                ButtonPlasmaBody(time: t, size: size, blur: ctx.cg("blur"), halo: ctx.bool("halo"), taps: taps, language: ctx.language)
            }
        }
        .buttonStyle(ButtonPlasmaPressStyle())
    }

    private func tap() {
        taps += 1
        Haptics.tap(.soft)
    }
}

private struct ButtonPlasmaBody: View {
    let time: Double
    let size: CGSize
    let blur: CGFloat
    let halo: Bool
    let taps: Int
    let language: AppLanguage

    private static let blobs: [ButtonPlasmaBlob] = [
        ButtonPlasmaBlob(color: Palette.violet, periodX: 7, periodY: 5, phase: 0),
        ButtonPlasmaBlob(color: Palette.pink, periodX: 9, periodY: 6, phase: 1.7),
        ButtonPlasmaBlob(color: Palette.sky, periodX: 6, periodY: 8, phase: 3.4),
        ButtonPlasmaBlob(color: Palette.mint, periodX: 8, periodY: 7, phase: 5.1),
    ]

    var body: some View {
        ZStack {
            if halo {
                blobLayer
                    .blur(radius: 26)
                    .opacity(0.7)
                    .allowsHitTesting(false)
            }
            ZStack {
                blobLayer
                Capsule().fill(Color.white.opacity(0.2))
                Capsule()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.5), .clear], startPoint: .top, endPoint: .center))
                    .padding(2)
                label
            }
            .frame(width: size.width, height: size.height)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.45), lineWidth: 1))
        }
        .frame(width: size.width, height: size.height)
    }

    private var label: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text(language == .zh ? "随便问问" : "Ask anything")
        }
        .font(.headline)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
    }

    private var blobLayer: some View {
        ZStack {
            ForEach(Self.blobs.indices, id: \.self) { index in
                blob(Self.blobs[index])
            }
        }
        .frame(width: size.width, height: size.height)
        .keyframeAnimator(initialValue: ButtonPlasmaPulse(), trigger: taps) { content, pulse in
            content
                .scaleEffect(pulse.scale)
                .brightness(pulse.glow)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                SpringKeyframe(1.35, duration: 0.25, spring: .snappy)
                CubicKeyframe(1.35, duration: 0.25)
                SpringKeyframe(1, duration: 0.6, spring: .smooth)
            }
            KeyframeTrack(\.glow) {
                CubicKeyframe(0.15, duration: 0.2)
                CubicKeyframe(0.15, duration: 0.3)
                CubicKeyframe(0, duration: 0.5)
            }
        }
        .drawingGroup()
    }

    private func blob(_ blob: ButtonPlasmaBlob) -> some View {
        let angleX: Double = time * 2 * Double.pi / blob.periodX + blob.phase
        let angleY: Double = time * 2 * Double.pi / blob.periodY + blob.phase * 0.7
        let x = CGFloat(cos(angleX)) * size.width * 0.38
        let y = CGFloat(sin(angleY)) * size.height * 0.45
        return Circle()
            .fill(blob.color)
            .frame(width: 70, height: 70)
            .blur(radius: blur)
            .offset(x: x, y: y)
    }
}

private struct ButtonPlasmaPulse {
    var scale: CGFloat = 1
    var glow: Double = 0
}

private struct ButtonPlasmaPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
