import SwiftUI

extension Effect {
    static let navigationHopDotTab = Effect(
        id: "navigation.hop-dot-tab",
        category: .navigation,
        interaction: .tap,
        name: L("Hopping Dot", "跳跃圆点指示器"),
        summary: L(
            "A tiny indicator dot jumps in an arc to the new tab, stretching in flight and squashing on landing.",
            "小圆点指示器沿弧线跳到新标签：空中拉长，落地压扁。"
        ),
        prompt: L(
            "A floating tab bar with five outline icons and a 7 pt dot under the selected one. Selecting a tab makes the dot hop there: it travels horizontally on an ease-in-out curve over ≈0.42 s while rising on an arc whose apex is ≈22 pt plus a little extra for longer jumps; in flight it stretches vertically to 80% × 125%, and on touchdown it squashes to ≈140% × 60% before springing back round. The landing icon dips 3 pt as if pushed by the impact and swaps to its filled variant, while the previous icon empties. Cartoon physics — squash, stretch, anticipation — in a 7 pt element.",
            "悬浮标签栏上有五个线框图标，选中项下方有一枚 7pt 小圆点。切换标签时，圆点跳过去：水平方向以缓入缓出曲线在约 0.42 秒内移动，竖直方向沿弧线上升，顶点约 22pt，跳得越远弧线越高；空中纵向拉长到 80% × 125%，落地瞬间压扁到约 140% × 60%，再弹回圆形。落点图标像被撞到一样下沉 3pt，并切换为实心版本，原图标变回线框。在一个 7pt 的元素里演绎挤压、拉伸与预备动作的卡通物理。"
        ),
        implementation: L(
            "The dot's x offset animates with a timing curve on the selection value, while a keyframeAnimator keyed on a hop counter plays the arc height and the stretch/squash scales; the landing icon runs its own delayed keyframe dip.",
            "圆点的横向位移随选中值以时间曲线动画；以跳跃计数为触发器的 keyframeAnimator 播放弧线高度与拉伸/挤压缩放；落点图标运行一段带延迟的关键帧下沉。"
        ),
        apis: ["keyframeAnimator", "KeyframeTrack", "CubicKeyframe", "SpringKeyframe", "animation(_:value:)"],
        tags: ["tab indicator", "dot", "squash and stretch", "hop", "标签指示器", "圆点", "挤压拉伸", "跳跃"],
        params: [
            .slider("duration", L("Flight time", "飞行时长"), 0.25...0.8, default: 0.42, unit: "s"),
            .slider("height", L("Hop height", "跳跃高度"), 8...40, default: 22, decimals: 0, unit: "pt"),
            .slider("squash", L("Squash", "挤压程度"), 0.0...0.6, default: 0.4),
        ]
    ) { ctx in
        HopDotTabDemo(ctx: ctx)
    }
}

private struct HopDotFrame {
    var lift: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
}

private let hopSymbols: [String] = ["house", "square.grid.2x2", "plus.circle", "bookmark", "person"]

private struct HopDotTabDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var hops = 0
    @State private var distance = 1

    private let slot: CGFloat = 56

    /// Grid previews and still thumbnails get faint screen content above the bar.
    private var thumbnail: Bool { ctx.isPreview || ctx.isStill }

    var body: some View {
        VStack(spacing: 28) {
            if thumbnail {
                NavigationScreenPlaceholder().padding(.top, 20)
            }
            Spacer(minLength: 0)
            bar
            DemoHint(text: L("Tap an icon", "点击任一图标"), ctx: ctx)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.1) {
            let jumps: [Int] = [2, 1, 4, 0, 3]
            select(jumps[hops % jumps.count])
        }
    }

    private var bar: some View {
        ZStack(alignment: .bottomLeading) {
            HStack(spacing: 0) {
                ForEach(0..<hopSymbols.count, id: \.self) { index in
                    icon(index)
                }
            }
            dot
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .demoGlass(RoundedRectangle(cornerRadius: 26, style: .continuous), material: .regularMaterial)
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }

    private func icon(_ index: Int) -> some View {
        let isSelected = index == selected
        let landingDelay: Double = ctx["duration"]
        return Image(systemName: isSelected ? hopSymbols[index] + ".fill" : hopSymbols[index])
            .font(.system(size: 21, weight: .semibold))
            .foregroundStyle(isSelected ? Palette.indigo : Color.secondary)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: slot, height: 40)
            .contentShape(Rectangle())
            .onTapGesture { select(index) }
            .keyframeAnimator(initialValue: CGFloat(0), trigger: hops) { content, dip in
                content.offset(y: dip)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    LinearKeyframe(0, duration: landingDelay)
                    CubicKeyframe(isSelected ? 3 : 0, duration: 0.07)
                    SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                }
            }
    }

    private var dot: some View {
        let duration: Double = ctx["duration"]
        let apex: CGFloat = ctx.cg("height") + CGFloat(max(distance - 1, 0)) * 4
        let squash: CGFloat = ctx.cg("squash")
        let x: CGFloat = CGFloat(selected) * slot + slot / 2 - 3.5
        return Circle()
            .fill(Palette.indigo)
            .frame(width: 7, height: 7)
            .keyframeAnimator(initialValue: HopDotFrame(), trigger: hops) { content, frame in
                content
                    .scaleEffect(x: frame.scaleX, y: frame.scaleY, anchor: .bottom)
                    .offset(y: -frame.lift)
            } keyframes: { _ in
                KeyframeTrack(\.lift) {
                    CubicKeyframe(apex, duration: duration * 0.5)
                    CubicKeyframe(0, duration: duration * 0.5)
                }
                KeyframeTrack(\.scaleX) {
                    CubicKeyframe(0.8, duration: duration * 0.3)
                    LinearKeyframe(0.8, duration: duration * 0.6)
                    CubicKeyframe(1 + squash, duration: duration * 0.1)
                    SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                }
                KeyframeTrack(\.scaleY) {
                    CubicKeyframe(1.25, duration: duration * 0.3)
                    LinearKeyframe(1.25, duration: duration * 0.6)
                    CubicKeyframe(1 - squash, duration: duration * 0.1)
                    SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                }
            }
            .offset(x: x, y: 10)
            .animation(.easeInOut(duration: duration), value: selected)
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        distance = abs(index - selected)
        hops += 1
        withAnimation(.snappy) { selected = index }
    }
}
