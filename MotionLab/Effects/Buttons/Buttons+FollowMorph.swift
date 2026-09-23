import SwiftUI

extension Effect {
    static let buttonsFollowMorph = Effect(
        id: "buttons.follow-morph",
        category: .buttons,
        interaction: .tap,
        name: L("Follow Morph", "关注形变"),
        summary: L("A filled Follow pill reshapes into a quiet Following state.", "实心“关注”胶囊弹性形变为低调的“已关注”状态。"),
        prompt: L(
            "A profile card with a gradient avatar, name, handle and follower stats, and a compact indigo-violet \"Follow\" pill with a plus glyph. On tap the pill springs (response 0.4 s, damping 0.7) into a wider, tonal \"Following\" capsule: the fill drains to a 8% neutral tint with a hairline border, the plus is replaced by a checkmark via a symbol replace, and the label blur-replaces. In parallel a ring pulses out of the avatar (scale 1 → 1.35, fading over 600 ms), a small verified badge pops onto it with a bouncy overshoot, and the follower count rolls up by one. A medium haptic confirms. Unfollowing reverses everything quietly with a light tick. Social, confident and never shouty.",
            "个人资料卡片：渐变头像、昵称、账号与粉丝数据，右侧是一枚靛紫渐变的紧凑“关注”胶囊，带加号。点击后，胶囊以弹簧（响应 0.4 秒、阻尼 0.7）变宽、转为低调的“已关注”：填充褪为 8% 的中性色并加一圈细描边，加号通过符号替换变为对勾，文字模糊替换。同时头像向外脉冲出一圈光环（缩放 1 → 1.35，600 毫秒内淡出），一枚认证小徽章带着弹性过冲弹到头像上，粉丝数向上滚动加一，并触发中等触觉。取消关注时一切安静地反向播放，仅有一次轻触感。社交感十足，自信而不张扬。"
        ),
        implementation: L(
            "One following flag drives the pill's fill, border and label inside a spring withAnimation; the glyph uses contentTransition(.symbolEffect(.replace)), the label an id-keyed blurReplace transition, the avatar ring a keyframeAnimator and the count numericText.",
            "单个关注状态在弹簧 withAnimation 中驱动胶囊的填充、描边与文字；图标使用 contentTransition(.symbolEffect(.replace))，文字用以 id 区分的 blurReplace 过渡，头像光环由 keyframeAnimator 驱动，粉丝数使用 numericText。"
        ),
        apis: ["contentTransition(.symbolEffect(.replace))", "transition(.blurReplace)", "keyframeAnimator", "numericText", "spring(response:dampingFraction:)"],
        tags: ["follow", "subscribe", "social", "toggle", "关注", "订阅", "社交", "状态切换"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.4...1.0, default: 0.7),
            .toggle("badge", L("Avatar badge", "头像徽章"), default: true),
        ]
    ) { ctx in
        ButtonFollowMorphDemo(ctx: ctx)
    }
}

private struct ButtonFollowMorphDemo: View {
    let ctx: DemoContext
    @State private var following = false
    @State private var followers = 12_480
    @State private var pulses = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap Follow", "点击关注"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.5) { toggle() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ButtonFollowAvatar(pulses: pulses, verified: following && ctx.bool("badge"))
                VStack(alignment: .leading, spacing: 3) {
                    Text(ctx.language == .zh ? "林墨" : "Mira Lin")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(ctx.language == .zh ? "@linmo · 动效设计师" : "@miralin · Motion designer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            HStack(alignment: .center, spacing: 18) {
                stat(value: Text(followers, format: .number), label: L("Followers", "粉丝"))
                    .contentTransition(.numericText(value: Double(followers)))
                stat(value: Text(verbatim: "86"), label: L("Posts", "作品"))
                Spacer(minLength: 0)
                followButton
            }
        }
        .padding(18)
        .frame(width: 300)
        .demoCard(cornerRadius: 24)
    }

    private func stat(value: Text, label: LocalizedText) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            value
                .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
            Text(label, ctx.language)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var followButton: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                Image(systemName: following ? "checkmark" : "plus")
                    .font(.system(size: 13, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                ZStack {
                    if following {
                        Text(ctx.language == .zh ? "已关注" : "Following")
                            .transition(.blurReplace)
                    } else {
                        Text(ctx.language == .zh ? "关注" : "Follow")
                            .transition(.blurReplace)
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(following ? Color.primary : Color.white)
            .padding(.horizontal, following ? 16 : 18)
            .frame(height: 38)
            .background {
                Capsule()
                    .fill(following ? AnyShapeStyle(Color.primary.opacity(0.08)) : AnyShapeStyle(Palette.primary))
            }
            .overlay {
                Capsule()
                    .strokeBorder(following ? Color.primary.opacity(0.14) : Color.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: Palette.indigo.opacity(following ? 0 : 0.35), radius: 10, y: 5)
        }
        .buttonStyle(ButtonFollowPressStyle())
    }

    private func toggle() {
        let becomingFollower = !following
        if !ctx.isPreview { Haptics.tap(becomingFollower ? .medium : .light) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            following = becomingFollower
            followers += becomingFollower ? 1 : -1
        }
        if becomingFollower { pulses += 1 }
    }
}

private struct ButtonFollowAvatar: View {
    let pulses: Int
    let verified: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.primary, lineWidth: 2)
                .frame(width: 56, height: 56)
                .keyframeAnimator(initialValue: ButtonFollowRing(), trigger: pulses) { content, ring in
                    content
                        .scaleEffect(ring.scale)
                        .opacity(ring.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        MoveKeyframe(1)
                        CubicKeyframe(1.35, duration: 0.6)
                    }
                    KeyframeTrack(\.opacity) {
                        MoveKeyframe(0.9)
                        CubicKeyframe(0, duration: 0.6)
                    }
                }
            Circle()
                .fill(LinearGradient(colors: [Palette.sky, Palette.violet, Palette.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 56, height: 56)
                .overlay {
                    Text(verbatim: "ML")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .semibold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Palette.blue)
                .background(Circle().fill(Palette.elevated).padding(2))
                .scaleEffect(verified ? 1 : 0.2)
                .opacity(verified ? 1 : 0)
                .offset(x: 3, y: 3)
                .animation(.spring(response: 0.35, dampingFraction: 0.5).delay(verified ? 0.12 : 0), value: verified)
        }
    }
}

private struct ButtonFollowRing {
    var scale: Double = 1
    var opacity: Double = 0
}

private struct ButtonFollowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
