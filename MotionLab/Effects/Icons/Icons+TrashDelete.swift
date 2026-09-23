import SwiftUI

extension Effect {
    static let iconsTrashDelete = Effect(
        id: "icons.trash-delete",
        category: .icons,
        interaction: .tap,
        name: L("Trash Delete", "删除入篓"),
        summary: L("The lid flips open, a document hops and drops in, and the can squashes shut.", "盖子掀开，文件轻跳后落入，垃圾桶压扁合盖。"),
        prompt: L(
            "A document glyph floats above a custom-drawn red trash can with a hinged lid. On tap the lid hinges open ~28° around its right end while lifting 8 pt; the document anticipates with a 16 pt hop and slight counter-tilt, then drops ~84 pt into the can on an ease-in, shrinking to 60% and fading as it passes behind the rim. As it lands the can squashes to 90% height (and widens to match) and rebounds on a bouncy spring, then the lid snaps shut with a small overshoot and a rigid haptic. A fresh document springs back in and the counter rolls up. Precise, cartoon-physical and satisfying — deletion as a tiny reward.",
            "一个文件图标悬浮在自绘的红色垃圾桶上方，桶盖可铰接开合。点击时，桶盖以右端为铰点掀开约28°并上抬8 pt；文件先向上轻跳16 pt、带轻微反向倾斜蓄力，随后以缓入曲线下落约84 pt进入桶中，经过桶沿时缩小到60%并淡出。落底瞬间桶身压扁至90%高度（同时相应变宽），再以弹性弹簧回弹；随后桶盖带小幅过冲“啪”地合上，伴随一次硬朗触感。新文件弹回原位，计数向上滚动。精准、带卡通物理感、令人满足——让删除也成为小小的奖励。"
        ),
        implementation: L(
            "One keyframeAnimator keyed on a counter runs parallel tracks for lid angle and lift, document offset/scale/tilt/opacity and the can's squash; the lid rotates with rotationEffect(anchor: .trailing).",
            "以计数为触发器的单个 keyframeAnimator 并行驱动多条轨道：盖子角度与上抬、文件位移/缩放/倾斜/透明度以及桶身压扁；盖子通过 rotationEffect(anchor: .trailing) 铰接旋转。"
        ),
        apis: ["keyframeAnimator", "KeyframeTrack", "SpringKeyframe", "UnevenRoundedRectangle", "contentTransition(.numericText(value:))"],
        tags: ["delete", "trash", "bin", "remove", "keyframes", "删除", "垃圾桶", "移除", "关键帧"],
        params: [
            .slider("lid", L("Lid angle", "开盖角度"), 10...45, default: 28, step: 1, decimals: 0, unit: "°"),
            .slider("bounce", L("Lid bounce", "合盖弹性"), 0...0.6, default: 0.35),
            .toggle("squash", L("Squash on landing", "落底压扁"), default: true),
        ]
    ) { ctx in
        IconsTrashDemo(ctx: ctx)
    }
}

private struct IconsTrashValues {
    var lid: Double = 0
    var lidLift: Double = 0
    var docY: Double = 0
    var docScale: Double = 1
    var docOpacity: Double = 1
    var docTilt: Double = 0
    var squash: Double = 1
}

private struct IconsTrashDemo: View {
    let ctx: DemoContext
    @State private var drops = 0
    @State private var deleted = 0

    var body: some View {
        let lidAngle = ctx["lid"]
        let bounce = ctx["bounce"]
        let squashes = ctx.bool("squash")
        VStack(spacing: 18) {
            Color.clear
                .frame(width: 200, height: 224)
                .keyframeAnimator(initialValue: IconsTrashValues(), trigger: drops) { content, value in
                    content.overlay { IconsTrashScene(value: value) }
                } keyframes: { _ in
                    KeyframeTrack(\.lid) {
                        SpringKeyframe(-lidAngle, duration: 0.2, spring: .snappy)
                        LinearKeyframe(-lidAngle, duration: 0.35)
                        SpringKeyframe(0, duration: 0.4, spring: Spring(duration: 0.4, bounce: bounce))
                        LinearKeyframe(0, duration: 0.35)
                    }
                    KeyframeTrack(\.lidLift) {
                        CubicKeyframe(-8, duration: 0.2)
                        LinearKeyframe(-8, duration: 0.35)
                        SpringKeyframe(0, duration: 0.4, spring: Spring(duration: 0.4, bounce: bounce))
                        LinearKeyframe(0, duration: 0.35)
                    }
                    KeyframeTrack(\.docY) {
                        CubicKeyframe(-16, duration: 0.18)
                        CubicKeyframe(84, duration: 0.3)
                        LinearKeyframe(84, duration: 0.37)
                        LinearKeyframe(0, duration: 0.01)
                        LinearKeyframe(0, duration: 0.44)
                    }
                    KeyframeTrack(\.docScale) {
                        CubicKeyframe(1.06, duration: 0.18)
                        CubicKeyframe(0.6, duration: 0.3)
                        LinearKeyframe(0.6, duration: 0.37)
                        LinearKeyframe(0.4, duration: 0.01)
                        SpringKeyframe(1, duration: 0.44, spring: .bouncy)
                    }
                    KeyframeTrack(\.docOpacity) {
                        LinearKeyframe(1, duration: 0.36)
                        LinearKeyframe(0, duration: 0.12)
                        LinearKeyframe(0, duration: 0.49)
                        CubicKeyframe(1, duration: 0.33)
                    }
                    KeyframeTrack(\.docTilt) {
                        CubicKeyframe(-6, duration: 0.18)
                        CubicKeyframe(14, duration: 0.3)
                        LinearKeyframe(14, duration: 0.37)
                        LinearKeyframe(0, duration: 0.01)
                        LinearKeyframe(0, duration: 0.44)
                    }
                    KeyframeTrack(\.squash) {
                        LinearKeyframe(1, duration: 0.46)
                        CubicKeyframe(squashes ? 0.9 : 1, duration: 0.08)
                        SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                        LinearKeyframe(1, duration: 0.36)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { delete() }
            counter
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { delete() }
    }

    private var counter: some View {
        HStack(spacing: 6) {
            Text(verbatim: "\(deleted)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(deleted)))
            Text(L("items deleted", "项已删除"), ctx.language)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to delete", "点击删除"), ctx: ctx)
                .fixedSize()
                .offset(y: 26)
        }
    }

    private func delete() {
        drops += 1
        if !ctx.isPreview { Haptics.tap(.medium) }
        // Captured now: the lid-thud haptic runs after autoplay (or the detail intro) has unmuted Haptics.
        let muted = Haptics.isMuted || ctx.isPreview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.snappy) { deleted += 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            if !muted { Haptics.tap(.rigid) }
        }
    }
}

private struct IconsTrashScene: View {
    let value: IconsTrashValues

    private var canShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 4,
            bottomLeadingRadius: 16,
            bottomTrailingRadius: 16,
            topTrailingRadius: 4,
            style: .continuous
        )
    }

    var body: some View {
        ZStack {
            document
            can
                .scaleEffect(x: CGFloat(2 - value.squash), y: CGFloat(value.squash), anchor: .bottom)
        }
    }

    private var document: some View {
        Image(systemName: "doc.text.fill")
            .font(.system(size: 42, weight: .regular))
            .foregroundStyle(LinearGradient(colors: [Palette.sky, Palette.blue], startPoint: .top, endPoint: .bottom))
            .shadow(color: Palette.blue.opacity(0.3), radius: 8, y: 4)
            .scaleEffect(CGFloat(value.docScale))
            .rotationEffect(.degrees(value.docTilt))
            .offset(y: CGFloat(-82 + value.docY))
            .opacity(value.docOpacity)
    }

    /// Lid stacked on the body in layout (so the squash anchors at the true base); the hinge motion is visual only.
    private var can: some View {
        VStack(spacing: -2) {
            lid
                .rotationEffect(.degrees(value.lid), anchor: .trailing)
                .offset(y: CGFloat(value.lidLift))
                .zIndex(1)
            canShape
                .fill(LinearGradient(colors: [Color(hex: 0xFF7A88), Palette.red], startPoint: .top, endPoint: .bottom))
                .frame(width: 78, height: 88)
                .overlay {
                    HStack(spacing: 13) {
                        ForEach(0..<3, id: \.self) { _ in
                            Capsule().fill(Color.white.opacity(0.35)).frame(width: 5, height: 52)
                        }
                    }
                }
                .shadow(color: Palette.red.opacity(0.3), radius: 12, y: 8)
        }
    }

    private var lid: some View {
        VStack(spacing: 0) {
            UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5, style: .continuous)
                .fill(Color(hex: 0xFF7A88))
                .frame(width: 30, height: 8)
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0xFF8C98), Color(hex: 0xE83E52)], startPoint: .top, endPoint: .bottom))
                .frame(width: 94, height: 11)
        }
    }
}
