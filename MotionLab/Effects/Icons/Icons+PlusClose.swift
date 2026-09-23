import SwiftUI

extension Effect {
    static let iconsPlusClose = Effect(
        id: "icons.plus-close",
        category: .icons,
        interaction: .tap,
        name: L("Plus ↔ Close Twist", "加号 ↔ 关闭扭转"),
        summary: L("The plus winds 135° into an X with a squeeze-and-pop while the button changes material.", "加号扭转 135° 变成 X，伴随挤压回弹，按钮同时换上新材质。"),
        prompt: L(
            "A 72 pt circular action button carries a bold plus made of two 30×5 pt rounded bars. Tapping winds the plus 135° clockwise on an under-damped spring (response 0.45 s, damping 0.62), overshooting a few degrees before it locks into an X; at the same moment a keyframed squeeze scales the glyph to 78% in 90 ms, pops it to 110% and settles at 100%, so the twist feels wound up and released. The disc cross-fades from the indigo-violet gradient with a coloured shadow to a dark neutral with a flatter shadow, and a caption rolls between 'New' and 'Close'. Tapping again unwinds the other way. A medium haptic accompanies each twist — decisive and springy.",
            "一个 72 pt 的圆形操作按钮上有一个由两根 30×5 pt 圆角横条组成的粗加号。点击后，加号以欠阻尼弹簧（响应 0.45 秒、阻尼 0.62）顺时针扭转 135°，先略微转过头再锁定成 X；与此同时一段关键帧挤压让图标在 90 毫秒内缩到 78%，再弹到 110% 后回到 100%，扭转仿佛先上紧发条再释放。圆底从带彩色投影的靛紫渐变交叉淡变为深色中性底与更平的阴影，下方文字在「新建」与「关闭」之间滚动切换。再次点击则反向拧回。每次扭转伴随中等触感——果断而有弹性。"
        ),
        implementation: L(
            "Two Capsules in a ZStack rotate together via rotationEffect under a spring; a keyframeAnimator keyed to the tap count adds the squeeze-pop scale, and the background swaps between two ShapeStyles inside the same animation.",
            "ZStack 中的两个 Capsule 在弹簧动画下通过 rotationEffect 一起旋转；以点击次数为触发器的 keyframeAnimator 叠加挤压回弹缩放，背景在同一动画中于两种 ShapeStyle 之间切换。"
        ),
        apis: ["rotationEffect", "keyframeAnimator", "spring(response:dampingFraction:)", "contentTransition(.interpolate)"],
        tags: ["plus", "close", "FAB", "rotate", "加号", "关闭", "旋转", "图标形变"],
        params: [
            .choice("turn", L("Twist", "扭转角度"), [L("45°", "45°"), L("135°", "135°"), L("225°", "225°")], default: 1),
            .slider("damping", L("Damping", "阻尼"), 0.3...1.0, default: 0.62),
            .toggle("squeeze", L("Squeeze-pop", "挤压回弹"), default: true),
        ]
    ) { ctx in
        PlusCloseDemo(ctx: ctx)
    }
}

private struct PlusCloseDemo: View {
    let ctx: DemoContext
    @State private var open = false
    @State private var taps = 0

    private var turn: Double {
        switch ctx.int("turn") {
        case 0: return 45
        case 2: return 225
        default: return 135
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Button { toggle() } label: {
                disc
            }
            .buttonStyle(.plain)
            Text(open ? L("Close", "关闭") : L("New", "新建"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.interpolate)
                .animation(.snappy, value: open)
            DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4) { toggle() }
    }

    private var disc: some View {
        let squeeze = ctx.bool("squeeze")
        return glyph
            .keyframeAnimator(initialValue: CGFloat(1), trigger: taps) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    CubicKeyframe(squeeze ? CGFloat(0.78) : CGFloat(1), duration: 0.09)
                    SpringKeyframe(squeeze ? CGFloat(1.1) : CGFloat(1), duration: 0.16, spring: .snappy)
                    SpringKeyframe(CGFloat(1), duration: 0.35, spring: .bouncy)
                }
            }
            .frame(width: 72, height: 72)
            .background(open ? AnyShapeStyle(Color(white: 0.16)) : AnyShapeStyle(Palette.primary), in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(open ? 0.1 : 0.25), lineWidth: 1))
            .shadow(color: open ? Color.black.opacity(0.2) : Palette.violet.opacity(0.45), radius: open ? 8 : 16, y: open ? 4 : 8)
            .animation(.easeInOut(duration: 0.3), value: open)
    }

    private var glyph: some View {
        ZStack {
            Capsule().frame(width: 30, height: 5)
            Capsule().frame(width: 5, height: 30)
        }
        .foregroundStyle(.white)
        .rotationEffect(.degrees(open ? turn : 0))
        .animation(.spring(response: 0.45, dampingFraction: ctx["damping"]), value: open)
    }

    private func toggle() {
        Haptics.tap(.medium)
        open.toggle()
        taps += 1
    }
}
