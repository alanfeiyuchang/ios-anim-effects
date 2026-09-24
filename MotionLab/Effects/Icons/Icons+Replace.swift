import SwiftUI

extension Effect {
    static let iconsReplace = Effect(
        id: "icons.replace",
        category: .icons,
        interaction: .state,
        name: L("Symbol Replace", "符号替换"),
        summary: L("Control toggles swap glyphs with the system replace transition.", "控制开关以系统替换过渡切换图标。"),
        prompt: L(
            "A Control-Center-style cluster of four circular toggles: mic, notifications, lock and camera. Toggling one swaps its glyph for the paired state (mic ↔ mic.slash, lock ↔ lock.open…) with the SF Symbols replace transition — on iOS 18 the default is a Magic Replace where shared strokes stay put and only the slash draws across, otherwise the old glyph scales down and out while the new one scales up from below. In the same snappy animation (≈0.35 s) the disc cross-fades between a translucent neutral fill and a saturated blue gradient, with a soft selection haptic. Crisp, systemic and reassuring.",
            "仿控制中心的四个圆形开关：麦克风、通知、锁和摄像头。切换时，图标以SF Symbols替换过渡变为成对的状态（mic↔mic.slash、lock↔lock.open……）——iOS 18默认使用“魔法替换”，共同的笔画保持不动，只有斜线被画出；其他样式则是旧图标缩小移出、新图标从下方放大进入。同一段利落的动画（约0.35秒）中，圆底在半透明中性底色与饱和蓝色渐变之间交叉渐变，并伴随轻柔的选择触感。利落、系统化、令人安心。"
        ),
        implementation: L(
            "Image(systemName:) whose name depends on state, with .contentTransition(.symbolEffect(.replace…)); the state flips inside withAnimation(.snappy).",
            "Image(systemName:) 的名称随状态变化，并设置 .contentTransition(.symbolEffect(.replace…))；状态在 withAnimation(.snappy) 中切换。"
        ),
        apis: ["contentTransition(.symbolEffect(_:))", "ReplaceSymbolEffect", "withAnimation(.snappy)", "Material"],
        tags: ["replace", "magic replace", "toggle", "control center", "替换", "魔法替换", "开关", "控制中心"],
        params: [
            .choice("style", L("Replace style", "替换样式"), [L("Automatic", "自动"), L("Down-Up", "下-上"), L("Up-Up", "上-上"), L("Off-Up", "隐-上")], default: 0),
            .toggle("byLayer", L("By layer", "按图层"), default: true),
        ]
    ) { ctx in
        ReplaceDemo(ctx: ctx)
    }
}

private struct ReplaceToggleModel {
    let on: String
    let off: String
}

private struct ReplaceDemo: View {
    let ctx: DemoContext
    @State private var states = [true, true, true, false]
    @State private var autoIndex = 0

    private let toggles: [ReplaceToggleModel] = [
        ReplaceToggleModel(on: "mic.fill", off: "mic.slash.fill"),
        ReplaceToggleModel(on: "bell.fill", off: "bell.slash.fill"),
        ReplaceToggleModel(on: "lock.fill", off: "lock.open.fill"),
        ReplaceToggleModel(on: "video.fill", off: "video.slash.fill"),
    ]

    private var effect: ReplaceSymbolEffect {
        let base: ReplaceSymbolEffect
        switch ctx.int("style") {
        case 1: base = .replace.downUp
        case 2: base = .replace.upUp
        case 3: base = .replace.offUp
        default: base = .replace
        }
        return ctx.bool("byLayer") ? base.byLayer : base.wholeSymbol
    }

    var body: some View {
        VStack(spacing: 20) {
            Grid(horizontalSpacing: 18, verticalSpacing: 18) {
                GridRow {
                    toggle(0)
                    toggle(1)
                }
                GridRow {
                    toggle(2)
                    toggle(3)
                }
            }
            .padding(20)
            .demoGlass(RoundedRectangle(cornerRadius: 32, style: .continuous), material: .thinMaterial)
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Palette.stroke))
            DemoHint(text: L("Tap the toggles", "点击开关"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.8) {
            flip(autoIndex % toggles.count)
            autoIndex += 1
        }
    }

    private func toggle(_ i: Int) -> some View {
        let isOn = states[i]
        return Button { flip(i) } label: {
            Image(systemName: isOn ? toggles[i].on : toggles[i].off)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .contentTransition(.symbolEffect(effect))
                .frame(width: 84, height: 84)
                .background {
                    Circle().fill(isOn ? AnyShapeStyle(Palette.ocean) : AnyShapeStyle(Color.primary.opacity(0.08)))
                }
                .shadow(color: Palette.blue.opacity(isOn ? 0.35 : 0), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func flip(_ i: Int) {
        withAnimation(.snappy(duration: 0.35)) { states[i].toggle() }
        if !ctx.isPreview { Haptics.selection() }
    }
}
