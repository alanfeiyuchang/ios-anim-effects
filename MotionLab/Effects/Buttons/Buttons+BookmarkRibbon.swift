import SwiftUI

extension Effect {
    static let buttonsBookmarkRibbon = Effect(
        id: "buttons.bookmark-ribbon",
        category: .buttons,
        interaction: .tap,
        name: L("Ribbon Save", "书签丝带收藏"),
        summary: L("Saving drops a ribbon over the card's edge that swings like fabric.", "点击收藏，一条书签丝带从卡片顶边垂下并像布料一样摆动。"),
        prompt: L(
            "An article card with a thumbnail, headline and a compact \"Save\" pill in its footer. On tap a violet ribbon bookmark (26 pt wide, V-notched tail) unrolls from the card's top edge near the right corner: its length springs from 0 to 46 pt with a visible overshoot (response 0.45 s, damping 0.55), then it swings like hanging fabric around its top edge — 7°, −4°, 2°, 0° over ~0.8 s. Meanwhile the pill morphs into a wider tonal \"Saved\" state: the outline bookmark glyph replaces with a filled one and the label blur-replaces, and a medium haptic fires. Unsaving rolls the ribbon back up quickly (0.25 s, no bounce) with a light tick. Crafted, editorial and tactile.",
            "文章卡片带缩略图和标题，底部是紧凑的“收藏”胶囊。点击后，一条紫罗兰色书签丝带（宽 26pt，末端 V 形缺口）从卡片顶边靠右垂下：长度以明显过冲的弹簧（响应 0.45 秒、阻尼 0.55）从 0 伸到 46pt，随后以顶边为轴像布料一样摆动，约 0.8 秒内依次摆到 7°、−4°、2°、0°。胶囊同时变宽为低饱和的“已收藏”：空心书签换成实心，文字模糊替换，伴随中等触感。取消收藏时丝带 0.25 秒内无回弹地卷回，并轻触一下。精致而有手作感。"
        ),
        implementation: L(
            "A custom notched-ribbon Shape hangs from a topTrailing overlay; its frame height springs between 0 and the ribbon length, and a keyframeAnimator on a save counter rotates it around its .top anchor. The pill uses symbol replace and blurReplace transitions inside the same spring.",
            "自定义的缺口丝带 Shape 挂在 topTrailing 叠层上；其高度在 0 与丝带长度之间做弹簧动画，以收藏计数触发的 keyframeAnimator 让它绕 .top 锚点摆动。胶囊在同一个弹簧中使用符号替换与 blurReplace 过渡。"
        ),
        apis: ["Shape", "keyframeAnimator", "rotationEffect(_:anchor:)", "contentTransition(.symbolEffect(.replace))", "transition(.blurReplace)"],
        tags: ["bookmark", "save", "ribbon", "swing", "收藏", "书签", "丝带", "摆动"],
        params: [
            .slider("length", L("Ribbon length", "丝带长度"), 24...70, default: 46, decimals: 0, unit: "pt"),
            .slider("swing", L("Swing angle", "摆动角度"), 0...14, default: 7, decimals: 0, unit: "°"),
            .slider("damping", L("Drop damping", "垂落阻尼"), 0.3...1.0, default: 0.55),
        ]
    ) { ctx in
        ButtonBookmarkRibbonDemo(ctx: ctx)
    }
}

private struct ButtonRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let notch = min(rect.width * 0.4, rect.height)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ButtonBookmarkRibbonDemo: View {
    let ctx: DemoContext
    @State private var saved = false
    @State private var saves = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap Save", "点击收藏"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7, delay: 0.4) { toggle() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            LandscapeArt(seed: 3)
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(L("TRAVEL · 6 MIN", "旅行 · 6 分钟"), ctx.language)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(L("Chasing light across the dunes", "追逐沙丘上的光"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            HStack {
                Text(L("by Lena Ortiz", "作者 Lena Ortiz"), ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                pill
            }
        }
        .padding(16)
        .frame(width: 290)
        .demoCard(cornerRadius: 24)
        .overlay(alignment: .topTrailing) {
            ribbon
                .padding(.trailing, 30)
        }
    }

    private var ribbon: some View {
        let length = ctx.cg("length")
        let swing = ctx["swing"]
        return ButtonRibbonShape()
            .fill(LinearGradient(colors: [Palette.violet, Palette.indigo], startPoint: .top, endPoint: .bottom))
            .frame(width: 26, height: saved ? length : 0)
            .shadow(color: Palette.indigo.opacity(0.35), radius: 4, y: 3)
            .keyframeAnimator(initialValue: 0.0, trigger: saves) { content, angle in
                content.rotationEffect(.degrees(angle), anchor: .top)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(0, duration: 0.12)
                    CubicKeyframe(swing, duration: 0.2)
                    CubicKeyframe(-swing * 0.57, duration: 0.2)
                    CubicKeyframe(swing * 0.28, duration: 0.18)
                    SpringKeyframe(0, duration: 0.3, spring: .smooth)
                }
            }
            .allowsHitTesting(false)
    }

    private var pill: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .contentTransition(.symbolEffect(.replace))
                ZStack {
                    if saved {
                        Text(L("Saved", "已收藏"), ctx.language)
                            .transition(.blurReplace)
                    } else {
                        Text(L("Save", "收藏"), ctx.language)
                            .transition(.blurReplace)
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(saved ? Palette.violet : Color.white)
            .padding(.horizontal, saved ? 16 : 14)
            .frame(height: 36)
            .background {
                Capsule()
                    .fill(saved ? AnyShapeStyle(Palette.violet.opacity(0.14)) : AnyShapeStyle(Palette.primary))
            }
        }
        .buttonStyle(SportPressStyle(scale: 0.94, dim: 0.04))
    }

    private func toggle() {
        let becomingSaved = !saved
        if becomingSaved {
            withAnimation(.spring(response: 0.45, dampingFraction: ctx["damping"])) { saved = true }
            saves += 1
            Haptics.tap(.medium)
        } else {
            withAnimation(.easeIn(duration: 0.25)) { saved = false }
            Haptics.tap()
        }
    }
}
