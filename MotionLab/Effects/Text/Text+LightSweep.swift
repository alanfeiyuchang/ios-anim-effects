import SwiftUI

extension Effect {
    static let textLightSweep = Effect(
        id: "text.light-sweep",
        category: .text,
        interaction: .tap,
        name: L("Light-Sweep Reveal", "光扫揭示"),
        summary: L("A soft diagonal edge wipes the headline in, led by a glowing band of colour.", "一道柔和的斜向边缘把标题擦出来，前端带着一条发光色带。"),
        prompt: L(
            "A bold two-line headline is hidden behind a diagonal mask. On trigger the mask's feathered edge, 18% of the width, sweeps from top-left to bottom-right over 1.3 s on an ease-in-out curve, revealing the text. Riding that edge is a narrow glowing band, a sunset-gradient copy of the same letters visible only inside the band and haloed by a 6 pt blur, so each glyph flashes warm as the light passes and then cools to the regular label colour. A caption springs up 150 ms after the sweep ends, and replaying hides everything in 250 ms. Cinematic, like a title card catching a studio light.",
            "一段粗体两行标题藏在一张斜向遮罩后面。触发后，遮罩的羽化边缘（宽度的 18%）以缓入缓出曲线在 1.3 秒内从左上扫到右下，把文字揭开。这道边缘上骑着一条窄窄的发光带：同一段文字的日落渐变副本，只在光带内可见，外加 6 pt 模糊光晕，于是光扫过时每个字先亮起暖色，再冷却成普通文字颜色。光扫结束 150 毫秒后说明文字弹起，重播时所有内容在 250 毫秒内隐去。电影感十足，像片头字幕被影棚灯光扫过。"
        ),
        implementation: L(
            "An Animatable view turns one progress value into gradient stops: a LinearGradient mask reveals the text behind the edge, and a second gradient mask confines a gradient-filled, blurred copy of the text to a narrow band at the edge.",
            "Animatable 视图把一个进度值换算成渐变色标：一层 LinearGradient 遮罩揭示边缘后方的文字，另一层渐变遮罩把填充了渐变并模糊的文字副本限制在边缘处的窄带内。"
        ),
        apis: ["Animatable", "mask(alignment:_:)", "LinearGradient(stops:)", "Gradient.Stop", "blur(radius:)"],
        tags: ["reveal", "wipe", "light sweep", "mask", "揭示", "擦除", "光扫", "遮罩"],
        params: [
            .slider("duration", L("Sweep duration", "扫过时长"), 0.5...3.0, default: 1.3, unit: "s"),
            .slider("softness", L("Edge softness", "边缘柔和度"), 0.02...0.4, default: 0.18),
            .toggle("glow", L("Glowing band", "发光色带"), default: true),
        ]
    ) { ctx in
        LightSweepDemo(ctx: ctx)
    }
}

private struct LightSweepDemo: View {
    let ctx: DemoContext
    @State private var progress: Double = 1
    @State private var captionShown = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LightSweepText(
                progress: progress,
                softness: ctx["softness"],
                glow: ctx.bool("glow"),
                text: L("Designed\nto move you.", "为触动\n而设计。")(ctx.language)
            )
            Text(L("Motion Lexicon · Autumn collection", "动效词典 · 秋季合集"), ctx.language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .opacity(captionShown ? 1 : 0)
                .offset(y: captionShown ? 0 : 8)
            DemoHint(text: L("Tap to replay", "点击重播"), ctx: ctx)
                .padding(.top, 10)
        }
        .frame(width: 290, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { replay() }
        .autoplay(ctx.isPreview, every: ctx["duration"] + 1.6) { replay() }
    }

    private func replay() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(.easeOut(duration: 0.25)) {
            progress = 0
            captionShown = false
        }
        let duration: Double = ctx["duration"]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: duration)) {
                progress = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(duration + 0.15)) {
                captionShown = true
            }
        }
    }
}

/// `progress` 0 → 1 moves the reveal edge across the block (and slightly past it so it ends fully visible).
private struct LightSweepText: View, Animatable {
    var progress: Double
    let softness: Double
    let glow: Bool
    let text: String

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Position of the edge in gradient space, running from -softness to 1 + softness.
    private var edge: Double {
        let span: Double = 1 + softness * 2
        return -softness + progress * span
    }

    var body: some View {
        let bandOpacity: Double = min(max((1 - progress) * 8, 0), 1)
        return label(.primary)
            .mask { revealMask }
            .overlay {
                if glow {
                    label(Palette.sunset)
                        .shadow(color: Palette.coral.opacity(0.8), radius: 6)
                        .mask { bandMask }
                        .opacity(bandOpacity)
                        .allowsHitTesting(false)
                }
            }
    }

    private func label<S: ShapeStyle>(_ style: S) -> some View {
        Text(verbatim: text)
            .font(.system(size: 44, weight: .black))
            .foregroundStyle(style)
            .fixedSize()
    }

    private func clamp(_ x: Double) -> CGFloat {
        CGFloat(min(max(x, 0), 1))
    }

    private var revealMask: some View {
        let stops: [Gradient.Stop] = [
            .init(color: .black, location: clamp(edge - softness)),
            .init(color: .clear, location: clamp(edge)),
        ]
        return LinearGradient(stops: stops, startPoint: UnitPoint(x: 0, y: 0.1), endPoint: UnitPoint(x: 1, y: 0.9))
    }

    private var bandMask: some View {
        let half: Double = softness * 0.5
        let stops: [Gradient.Stop] = [
            .init(color: .clear, location: clamp(edge - softness - half)),
            .init(color: .black, location: clamp(edge - softness * 0.5)),
            .init(color: .clear, location: clamp(edge + half * 0.2)),
        ]
        return LinearGradient(stops: stops, startPoint: UnitPoint(x: 0, y: 0.1), endPoint: UnitPoint(x: 1, y: 0.9))
    }
}
