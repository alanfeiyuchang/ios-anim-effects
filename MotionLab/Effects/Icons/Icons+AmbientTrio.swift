import SwiftUI

extension Effect {
    static let iconsAmbientTrio = Effect(
        id: "icons.wiggle-rotate-breathe",
        category: .icons,
        interaction: .loop,
        name: L("Wiggle · Rotate · Breathe", "摇摆 · 旋转 · 呼吸"),
        summary: L("The iOS 18 indefinite symbol effects, side by side.", "iOS 18 新增的三种持续型符号动效并排展示。"),
        prompt: L(
            "Three status tiles show the iOS 18 ambient symbol effects running continuously: an incoming-call phone that wiggles side to side in quick, decaying shakes and then rests; a settings gear that rotates steadily around its centre like a working mechanism; and a heart that breathes — scaling gently between 100% and ~110% while its opacity softly pulses, about once per second. Each effect loops until its tile is tapped, which pauses it and dims the caption. Subtle, ambient signals that say \"something is happening\" without demanding attention.",
            "三块状态卡片同时展示 iOS 18 的持续型符号动效：来电话筒左右快速摇摆、振幅逐渐衰减后短暂停顿；设置齿轮绕中心匀速旋转，像一台正在运转的机械；爱心则在“呼吸”——大小在 100% 与约 110% 之间轻柔缩放，透明度同步微微起伏，约每秒一次。每个效果持续循环，点击卡片即可暂停并让说明文字变暗。这些都是低调的环境信号，传达“正在发生”，却不抢夺注意力。"
        ),
        implementation: L(
            ".symbolEffect(.wiggle / .rotate / .breathe, options: .speed(_:), isActive:) — iOS 18 effects that conform to IndefiniteSymbolEffect and loop while active.",
            ".symbolEffect(.wiggle / .rotate / .breathe, options: .speed(_:), isActive:)——iOS 18 新增的效果，遵循 IndefiniteSymbolEffect，激活期间持续循环。"
        ),
        apis: ["WiggleSymbolEffect", "RotateSymbolEffect", "BreatheSymbolEffect", "symbolEffect(_:options:isActive:)"],
        tags: ["wiggle", "rotate", "breathe", "ios 18", "摇摆", "旋转", "呼吸", "符号动效"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.5...2, default: 1),
            .toggle("byLayer", L("By layer", "按图层"), default: false),
        ]
    ) { ctx in
        AmbientTrioDemo(ctx: ctx)
    }
}

private struct AmbientTrioDemo: View {
    let ctx: DemoContext
    @State private var active = [true, true, true]

    private var byLayer: Bool { ctx.bool("byLayer") }
    private var options: SymbolEffectOptions { .speed(ctx["speed"]) }

    private var wiggle: WiggleSymbolEffect {
        byLayer ? .wiggle.byLayer : .wiggle.wholeSymbol
    }

    private var rotate: RotateSymbolEffect {
        byLayer ? .rotate.byLayer : .rotate.wholeSymbol
    }

    private var breathe: BreatheSymbolEffect {
        byLayer ? .breathe.byLayer : .breathe.wholeSymbol
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                tile(0, title: L("Wiggle", "摇摆"), tint: Palette.green) {
                    Image(systemName: "phone.fill")
                        .symbolEffect(wiggle, options: options, isActive: active[0])
                }
                tile(1, title: L("Rotate", "旋转"), tint: Palette.blue) {
                    Image(systemName: "gearshape.fill")
                        .symbolEffect(rotate, options: options, isActive: active[1])
                }
                tile(2, title: L("Breathe", "呼吸"), tint: Palette.pink) {
                    Image(systemName: "heart.fill")
                        .symbolEffect(breathe, options: options, isActive: active[2])
                }
            }
            DemoHint(text: L("Tap a tile to pause it", "点击卡片暂停"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tile<Icon: View>(_ i: Int, title: LocalizedText, tint: Color, @ViewBuilder icon: () -> Icon) -> some View {
        let glyph = icon()
        return Button {
            active[i].toggle()
            Haptics.selection()
        } label: {
            VStack(spacing: 14) {
                glyph
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 60, height: 60)
                    .background(tint.opacity(0.14), in: Circle())
                Text(title, ctx.language)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(active[i] ? Color.primary : Color.secondary)
            }
            .frame(width: 92, height: 132)
            .demoCard(cornerRadius: 22)
            .opacity(active[i] ? 1 : 0.6)
            .animation(.snappy, value: active[i])
        }
        .buttonStyle(.plain)
    }
}
