import SwiftUI

extension Effect {
    static let iconsAppearDisappear = Effect(
        id: "icons.appear-disappear",
        category: .icons,
        interaction: .tap,
        name: L("Toolbar Swap · Appear & Scale", "工具栏换装 · 出现与缩放"),
        summary: L("Toolbar glyphs dissolve layer by layer and the edit set grows in, one slot at a time.", "工具栏图标逐层消散，编辑图标按槽位依次长出。"),
        prompt: L(
            "A floating toolbar holds four browse actions (share, like, comment, save) under a Select/Done pill. Tapping Select swaps every slot to an edit action (trash, move, duplicate, pin) in a left-to-right cascade 70 ms apart: in each slot the old glyph plays the SF Symbols disappear effect by layer — its layers shrinking and sliding down in sequence — while the new glyph assembles upward from its layers, both at 1.2× speed. Tapping a single action while in either mode holds it in the scale-up effect (≈115%) with a light haptic, marking it as chosen, and tapping again releases it. The swap feels native and orderly, like the toolbar is reorganising itself.",
            "一个悬浮工具栏上有四个浏览操作（分享、喜欢、评论、收藏），上方是「选择/完成」胶囊按钮。点击「选择」后，每个槽位从左到右以70毫秒间隔依次换成编辑操作（删除、移动、复制、置顶）：每个槽位中，旧图标执行SF Symbols的按图层消失特效——各图层依次缩小并向下滑走；新图标则按图层自下而上组装出现，两者都以1.2倍速播放。在任一模式下点击单个操作，它会保持在放大（约115%）特效中表示已选中，并伴随轻触感，再次点击取消。原生而有秩序，仿佛工具栏在自我整理。"
        ),
        implementation: L(
            "Each slot stacks both glyphs and drives .symbolEffect(.disappear.down/up.byLayer, options: .speed(_:), isActive:) with complementary per-slot booleans flipped on a staggered schedule; selection uses .symbolEffect(.scale.up, isActive:).",
            "每个槽位叠放两个图标，用互补的逐槽布尔值驱动 .symbolEffect(.disappear.down/up.byLayer, options: .speed(_:), isActive:)，并按错开的时间表依次翻转；选中状态使用 .symbolEffect(.scale.up, isActive:)。"
        ),
        apis: ["symbolEffect(_:options:isActive:)", "DisappearSymbolEffect", "ScaleSymbolEffect", "SymbolEffectOptions.speed(_:)"],
        tags: ["appear", "disappear", "scale", "toolbar", "SF Symbols", "出现", "消失", "工具栏"],
        params: [
            .slider("speed", L("Effect speed", "特效速度"), 0.5...2.5, default: 1.2, unit: "×"),
            .slider("stagger", L("Slot stagger", "槽位错开"), 0...0.2, default: 0.07, unit: "s"),
            .choice("direction", L("Exit direction", "消失方向"), [L("Down", "向下"), L("Up", "向上")], default: 0),
        ]
    ) { ctx in
        AppearDisappearDemo(ctx: ctx)
    }
}

private struct ToolbarSlot {
    let browse: String
    let edit: String
    let tint: Color
}

private let toolbarSlots: [ToolbarSlot] = [
    ToolbarSlot(browse: "square.and.arrow.up", edit: "trash", tint: Palette.red),
    ToolbarSlot(browse: "heart", edit: "folder", tint: Palette.blue),
    ToolbarSlot(browse: "bubble.left.and.bubble.right", edit: "plus.square.on.square", tint: Palette.violet),
    ToolbarSlot(browse: "bookmark", edit: "pin", tint: Palette.amber),
]

private struct AppearDisappearDemo: View {
    let ctx: DemoContext
    @State private var editing: [Bool] = [false, false, false, false]
    @State private var chosen: Set<Int> = []
    @State private var mode = false

    private var options: SymbolEffectOptions { .speed(ctx["speed"]) }

    private var exitEffect: DisappearSymbolEffect {
        ctx.int("direction") == 1 ? .disappear.up.byLayer : .disappear.down.byLayer
    }

    private var enterEffect: DisappearSymbolEffect {
        ctx.int("direction") == 1 ? .disappear.down.byLayer : .disappear.up.byLayer
    }

    var body: some View {
        VStack(spacing: 22) {
            modeButton
            toolbar
            DemoHint(text: L("Tap Select, then an action", "点击「选择」，再点某个操作"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0) { toggleMode() }
    }

    private var modeButton: some View {
        Button { toggleMode() } label: {
            Text(mode ? L("Done", "完成") : L("Select", "选择"), ctx.language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(mode ? Color.white : Color.primary)
                .padding(.horizontal, 18)
                .frame(height: 34)
                .background(mode ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(.thinMaterial), in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.stroke))
                .contentTransition(.interpolate)
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: mode)
    }

    private var toolbar: some View {
        HStack(spacing: 6) {
            ForEach(toolbarSlots.indices, id: \.self) { index in
                slot(index)
            }
        }
        .padding(8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
    }

    private func slot(_ index: Int) -> some View {
        let item = toolbarSlots[index]
        let isEditing = editing[index]
        let isChosen = chosen.contains(index)
        return Button { choose(index) } label: {
            ZStack {
                Image(systemName: item.browse)
                    .symbolEffect(exitEffect, options: options, isActive: isEditing)
                    .symbolEffect(.scale.up, isActive: isChosen && !isEditing)
                Image(systemName: item.edit)
                    .foregroundStyle(item.tint)
                    .symbolEffect(enterEffect, options: options, isActive: !isEditing)
                    .symbolEffect(.scale.up, isActive: isChosen && isEditing)
            }
            .font(.system(size: 22, weight: .semibold))
            .frame(width: 58, height: 52)
            .background(Color.primary.opacity(isChosen ? 0.08 : 0), in: Capsule())
            .animation(.snappy, value: isChosen)
        }
        .buttonStyle(.plain)
    }

    private func choose(_ index: Int) {
        Haptics.tap(.light)
        if chosen.contains(index) {
            chosen.remove(index)
        } else {
            chosen.insert(index)
        }
    }

    private func toggleMode() {
        Haptics.selection()
        mode.toggle()
        chosen = []
        let target = mode
        let stagger: Double = ctx["stagger"]
        for index in toolbarSlots.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * stagger) {
                editing[index] = target
            }
        }
    }
}
