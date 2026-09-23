import SwiftUI

extension Effect {
    static let iconsHeartLike = Effect(
        id: "icons.heart-like",
        category: .icons,
        interaction: .tap,
        name: L("Heart Like Burst", "点赞爱心迸发"),
        summary: L("Tap or double-tap a post: the heart squashes, fills and bursts into particles.", "点击或双击动态：爱心压缩、填色并迸发粒子。"),
        prompt: L(
            "A photo post card has an outlined heart and a like count in its action bar. Liking, by tapping the heart or double-tapping the photo, first squashes the heart to 70% in anticipation, then springs it to 125% as it swaps to a filled red glyph and settles at 100% within about 0.6 s. At the peak a thin ring expands to about 2× and fades while ten multicoloured dots shoot 56 pt outward and shrink on an ease-out, and the count rolls up with a medium haptic. A double-tap also blooms a large white heart over the photo that springs to 115%, holds, then swells and fades; unliking swaps back to the outline and rolls the count down. Joyful and snappy.",
            "一张图片动态卡片，操作栏里有描边爱心和点赞数。点赞时（点爱心或双击图片），爱心先压到 70% 蓄力，再弹到 125% 并换成实心红色，约 0.6 秒内回到 100%。最高点处，一道细圆环扩散到约 2 倍后淡出，十颗彩色小圆点径向射出 56 pt、缓出缩小，点赞数向上滚动，伴随中等触感。双击时画面中央还会绽开一颗白色大爱心：弹到 115%，停一拍，再放大淡出；取消点赞则换回描边、数字回滚。欢快、有回报感、干脆利落。"
        ),
        implementation: L(
            "keyframeAnimator drives heart scale and a 0→1 burst progress (ring + radial dots are invisible at both ends); the glyph swaps via symbolEffect replace and the count uses numericText.",
            "keyframeAnimator 驱动爱心缩放以及 0→1 的迸发进度（圆环与径向粒子在两端都不可见）；图标通过 symbolEffect 替换切换，数字使用 numericText。"
        ),
        apis: ["keyframeAnimator", "contentTransition(.symbolEffect(.replace))", "contentTransition(.numericText(value:))", "KeyframeTrack"],
        tags: ["like", "heart", "burst", "double tap", "particles", "点赞", "爱心", "双击", "粒子", "喜欢"],
        params: [
            .slider("radius", L("Burst radius", "迸发半径"), 30...90, default: 56, decimals: 0, unit: "pt"),
            .slider("count", L("Particles", "粒子数"), 6...16, default: 10, step: 1, decimals: 0),
            .choice("color", L("Color", "颜色"), [L("Red", "红"), L("Pink", "粉"), L("Violet", "紫")], default: 0),
        ]
    ) { ctx in
        HeartLikeDemo(ctx: ctx)
    }
}

private struct HeartPopValues {
    var scale: Double = 0
    var opacity: Double = 0
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
    @State private var pops = 0

    private var tint: Color {
        switch ctx.int("color") {
        case 1: return Palette.pink
        case 2: return Palette.violet
        default: return Palette.red
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                photo
                actionRow
            }
            .frame(width: 280)
            .demoCard(cornerRadius: 24)
            DemoHint(text: L("Tap the heart or double-tap the photo", "点击爱心或双击图片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) { autoAdvance() }
    }

    private var photo: some View {
        LinearGradient(colors: [Palette.amber, Palette.coral, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(alignment: .bottomLeading) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 74))
                    .foregroundStyle(.white.opacity(0.35))
                    .offset(x: 18, y: 14)
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(.white.opacity(0.55))
                    .frame(width: 34, height: 34)
                    .blur(radius: 2)
                    .padding(22)
            }
            .overlay {
                Color.clear.keyframeAnimator(initialValue: HeartPopValues(), trigger: pops) { content, value in
                    content.overlay {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                            .scaleEffect(CGFloat(value.scale))
                            .opacity(value.opacity)
                    }
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        SpringKeyframe(1.15, duration: 0.22, spring: .bouncy)
                        SpringKeyframe(1.0, duration: 0.28, spring: .snappy)
                        LinearKeyframe(1.0, duration: 0.2)
                        CubicKeyframe(1.3, duration: 0.2)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(1, duration: 0.08)
                        LinearKeyframe(1, duration: 0.62)
                        CubicKeyframe(0, duration: 0.2)
                    }
                }
            }
            .frame(height: 158)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { doubleTap() }
    }

    private var actionRow: some View {
        HStack(spacing: 4) {
            heart
                .scaleEffect(0.72)
                .frame(width: 58, height: 58)
            Text(verbatim: count.formatted(.number))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(count)))
                .foregroundStyle(liked ? tint : Color.primary)
            Spacer(minLength: 0)
            Image(systemName: "bubble.right")
            Image(systemName: "paperplane")
                .padding(.leading, 14)
        }
        .font(.system(size: 19, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.leading, 4)
        .padding(.trailing, 18)
    }

    private func doubleTap() {
        pops += 1
        if !liked {
            toggle()
        } else if !ctx.isPreview {
            Haptics.tap(.soft)
        }
    }

    private func autoAdvance() {
        if liked { toggle() } else { doubleTap() }
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
