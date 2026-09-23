import SwiftUI

extension Effect {
    static let navigationFadeThrough = Effect(
        id: "navigation.fade-through",
        category: .navigation,
        interaction: .tap,
        name: L("Fade Through & Shared Axis", "淡出穿透与共享轴"),
        summary: L(
            "Three page-to-page patterns in one: fade through, shared X axis and shared Z axis.",
            "三种页面切换模式合一：淡出穿透、共享 X 轴与共享 Z 轴。"
        ),
        prompt: L(
            "A three-destination app (Inbox, Calendar, Files) inside a phone frame with a bottom bar. Switching destinations never slides whole screens; instead it uses a choreographed hand-off. Fade through: the outgoing page fades out in the first ≈30% of the 0.3 s duration, then the incoming page fades in while scaling from 92% to 100% over the remaining 70%, so the two never overlap. Shared X axis: both pages move 30 pt in the direction of travel while cross-fading. Shared Z axis: the outgoing page grows to 110% and fades out in the first 30%, then the incoming one grows in from 80%. Calm, systematic, Material-motion-grade.",
            "手机画框中是一个有三个目的地（收件箱、日历、文件）和底部导航栏的应用。切换目的地时不会整屏滑动，而是一次编排好的交接。淡出穿透：旧页面在 0.3 秒总时长的前约 30% 内淡出，新页面在余下 70% 内淡入并从 92% 放大到 100%，二者不会重叠。共享 X 轴：两个页面沿切换方向移动 30pt 并交叉淡化。共享 Z 轴：旧页面在前 30% 内放大到 110% 并淡出，随后新页面从 80% 放大进入。沉稳、系统化，达到 Material 动效规范的水准。"
        ),
        implementation: L(
            "Pages swap by id with an asymmetric transition whose insertion and removal carry their own AnyTransition.animation timing (removal short, insertion delayed); the pattern and direction are chosen before the selection changes.",
            "页面通过 id 切换，使用非对称过渡：插入与移除各自带有 AnyTransition.animation 的时序（移除短、插入延迟）；模式与方向在切换选中前确定。"
        ),
        apis: ["AnyTransition.asymmetric", "AnyTransition.animation(_:)", "transition(_:)", "id(_:)", "scale(scale:)"],
        tags: ["page transition", "fade through", "shared axis", "material motion", "页面转场", "淡出穿透", "共享轴", "Material"],
        params: [
            .choice("pattern", L("Pattern", "模式"), [L("Fade through", "淡出穿透"), L("Shared X", "共享 X 轴"), L("Shared Z", "共享 Z 轴")], default: 0),
            .slider("duration", L("Duration", "时长"), 0.2...0.8, default: 0.3, unit: "s"),
        ]
    ) { ctx in
        FadeThroughDemo(ctx: ctx)
    }
}

private struct FadeDestination {
    let symbol: String
    let title: LocalizedText
    let tint: Color
}

private let fadeDestinations: [FadeDestination] = [
    FadeDestination(symbol: "tray.fill", title: L("Inbox", "收件箱"), tint: Palette.indigo),
    FadeDestination(symbol: "calendar", title: L("Calendar", "日历"), tint: Palette.coral),
    FadeDestination(symbol: "folder.fill", title: L("Files", "文件"), tint: Palette.mint),
]

private struct FadeThroughDemo: View {
    let ctx: DemoContext
    @State private var selected = 0
    @State private var forward = true

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    FadePage(destination: fadeDestinations[selected], language: ctx.language)
                        .id(selected)
                        .transition(transition)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                bottomBar
            }
            .frame(width: 250, height: 320)
            .background(Palette.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            DemoHint(text: L("Tap a destination", "点击底部目的地"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.1) { select((selected + 1) % fadeDestinations.count) }
    }

    private var transition: AnyTransition {
        let total: Double = ctx["duration"]
        let out: Animation = .easeIn(duration: total * 0.3)
        let inAnimation: Animation = .easeOut(duration: total * 0.7).delay(total * 0.3)
        let both: Animation = .easeInOut(duration: total)
        switch ctx.int("pattern") {
        case 1:
            let shift: CGFloat = forward ? 30 : -30
            return .asymmetric(
                insertion: AnyTransition.opacity.combined(with: .offset(x: shift)).animation(both),
                removal: AnyTransition.opacity.combined(with: .offset(x: -shift)).animation(both)
            )
        case 2:
            return .asymmetric(
                insertion: AnyTransition.opacity.combined(with: .scale(scale: 0.8)).animation(inAnimation),
                removal: AnyTransition.opacity.combined(with: .scale(scale: 1.1)).animation(out)
            )
        default:
            return .asymmetric(
                insertion: AnyTransition.opacity.combined(with: .scale(scale: 0.92)).animation(inAnimation),
                removal: AnyTransition.opacity.animation(out)
            )
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<fadeDestinations.count, id: \.self) { index in
                let isSelected = index == selected
                VStack(spacing: 3) {
                    Image(systemName: fadeDestinations[index].symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 52, height: 26)
                        .background(isSelected ? fadeDestinations[index].tint.opacity(0.18) : Color.clear, in: Capsule())
                    Text(fadeDestinations[index].title, ctx.language)
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(isSelected ? fadeDestinations[index].tint : Color.secondary)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { select(index) }
                .animation(.easeInOut(duration: 0.2), value: selected)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(Palette.surface)
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        forward = index > selected
        let duration: Double = ctx["duration"]
        // Change pages one run-loop later so the outgoing page has re-rendered with the new direction
        // (a removal uses the transition from its last render). The transitions carry their own timing;
        // this transaction only marks the change as animated.
        Task { @MainActor in
            withAnimation(.linear(duration: duration)) { selected = index }
        }
    }
}

private struct FadePage: View {
    let destination: FadeDestination
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: destination.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(destination.tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(destination.title, language)
                    .font(.title3.weight(.bold))
            }
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 10) {
                    Circle()
                        .fill(destination.tint.opacity(0.25))
                        .frame(width: 28, height: 28)
                    PlaceholderLines(count: 2, color: .primary.opacity(0.1))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.elevated)
    }
}
