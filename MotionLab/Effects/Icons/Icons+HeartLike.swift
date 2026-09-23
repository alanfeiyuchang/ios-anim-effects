import SwiftUI

extension Effect {
    static let iconsHeartLike = Effect(
        id: "icons.heart-like",
        category: .icons,
        interaction: .tap,
        name: L("Heart Like Burst", "点赞爱心迸发"),
        summary: L("The heart squashes, fills and bursts with a ring of particles.", "爱心先压缩再填色，伴随一圈粒子迸发。"),
        prompt: L(
            "An outlined heart with a like count beside it. On like, the heart anticipates by squashing to 70%, then springs to 125% as it swaps to a filled red glyph and settles at 100% (≈0.6 s total). At the peak a thin ring expands from the centre to ~2× and fades, and ten small multicoloured dots shoot radially outwards ~56 pt, shrinking and fading on an ease-out, while the count rolls up by one with a medium haptic. Unliking simply replaces back to the outline glyph and the count rolls down with a selection tick. Joyful, rewarding and snappy — the signature social micro-interaction.",
            "描边爱心旁显示点赞数。点赞时，爱心先预备性压缩到 70%，再弹到 125% 并替换为实心红色，随后回到 100%（全程约 0.6 秒）。在最高点，一道细圆环从中心扩散到约 2 倍并淡出，十颗彩色小圆点沿径向向外射出约 56pt，以缓出曲线缩小并消失，同时点赞数向上滚动加一，伴随中等强度触感。取消点赞时直接替换回描边样式，数字向下滚动，并伴随一次选择触感。欢快、有回报感、干脆利落——社交产品的招牌微交互。"
        ),
        implementation: L(
            "keyframeAnimator drives heart scale and a 0→1 burst progress (ring + radial dots are invisible at both ends); the glyph swaps via symbolEffect replace and the count uses numericText.",
            "keyframeAnimator 驱动爱心缩放以及 0→1 的迸发进度（圆环与径向粒子在两端都不可见）；图标通过 symbolEffect 替换切换，数字使用 numericText。"
        ),
        apis: ["keyframeAnimator", "contentTransition(.symbolEffect(.replace))", "contentTransition(.numericText(value:))", "KeyframeTrack"],
        tags: ["like", "heart", "burst", "particles", "点赞", "爱心", "粒子", "喜欢"],
        params: [
            .slider("radius", L("Burst radius", "迸发半径"), 30...90, default: 56, decimals: 0, unit: "pt"),
            .slider("count", L("Particles", "粒子数"), 6...16, default: 10, step: 1, decimals: 0),
            .choice("color", L("Color", "颜色"), [L("Red", "红"), L("Pink", "粉"), L("Violet", "紫")], default: 0),
        ]
    ) { ctx in
        HeartLikeDemo(ctx: ctx)
    }
}

private struct HeartValues {
    var scale: Double = 1
    var burst: Double = 0
}

private struct HeartLikeDemo: View {
    let ctx: DemoContext
    @State private var liked = false
    @State private var count = 1_284
    @State private var bursts = 0

    private var tint: Color {
        switch ctx.int("color") {
        case 1: return Palette.pink
        case 2: return Palette.violet
        default: return Palette.red
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                heart
                Text(verbatim: count.formatted(.number))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(count)))
                    .foregroundStyle(liked ? tint : Color.primary)
            }
            DemoHint(text: L("Tap the heart", "点击爱心"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) { toggle() }
    }

    private var heart: some View {
        let liked = self.liked
        let tint = self.tint
        let radius = ctx.cg("radius")
        let particles = ctx.int("count")
        return Button { toggle() } label: {
            Color.clear
                .frame(width: 80, height: 80)
                .keyframeAnimator(initialValue: HeartValues(), trigger: bursts) { content, value in
                    content.overlay {
                        HeartFace(
                            liked: liked,
                            value: value,
                            tint: tint,
                            radius: radius,
                            particles: particles
                        )
                    }
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(0.7, duration: 0.1)
                        SpringKeyframe(1.25, duration: 0.15, spring: .snappy)
                        SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
                    }
                    KeyframeTrack(\.burst) {
                        LinearKeyframe(0, duration: 0.1)
                        CubicKeyframe(1, duration: 0.55)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            liked.toggle()
            count += liked ? 1 : -1
        }
        if liked {
            bursts += 1
            if !ctx.isPreview { Haptics.tap(.medium) }
        } else if !ctx.isPreview {
            Haptics.selection()
        }
    }
}

private struct HeartFace: View {
    let liked: Bool
    let value: HeartValues
    let tint: Color
    let radius: CGFloat
    let particles: Int

    var body: some View {
        let p = value.burst
        let fade = p > 0 && p < 1 ? sin(p * .pi) : 0
        ZStack {
            Circle()
                .stroke(tint.opacity(0.6 * (1 - p)), lineWidth: CGFloat(3 * (1 - p)) + 0.5)
                .frame(width: 60, height: 60)
                .scaleEffect(CGFloat(0.4 + p * 1.6))
                .opacity(p > 0 && p < 1 ? 1 : 0)
            ForEach(0..<max(particles, 1), id: \.self) { i in
                particle(i, progress: p)
                    .opacity(fade)
            }
            Image(systemName: liked ? "heart.fill" : "heart")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(liked ? tint : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
                .scaleEffect(CGFloat(value.scale))
        }
    }

    private func particle(_ i: Int, progress p: Double) -> some View {
        let angle = Double(i) / Double(max(particles, 1)) * 2 * .pi - .pi / 2
        let distance = CGFloat(18 + p * Double(radius))
        let size = CGFloat(8 * (1 - p) + 2)
        let color = Palette.spectrum[i % Palette.spectrum.count]
        return Circle()
            .fill(i.isMultiple(of: 2) ? tint : color)
            .frame(width: size, height: size)
            .offset(x: CGFloat(cos(angle)) * distance, y: CGFloat(sin(angle)) * distance)
    }
}
