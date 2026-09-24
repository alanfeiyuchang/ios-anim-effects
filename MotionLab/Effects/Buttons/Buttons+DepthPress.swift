import SwiftUI

extension Effect {
    static let buttonsDepthPress = Effect(
        id: "buttons.depth-press",
        category: .buttons,
        interaction: .tap,
        name: L("3D Depth Press", "立体按压"),
        summary: L("The face sinks into its base like a physical keycap.", "按钮面板像实体键帽一样按进底座。"),
        prompt: L(
            "A chunky, game-like button built from two stacked layers: a saturated gradient face and a darker base of the same hue peeking out 8 pt below it, giving a solid extruded look with a soft ground shadow. On touch-down the face travels straight down about 85% of the depth in ~120 ms on a stiff, near-critically-damped spring, the visible base collapses and the ground shadow shrinks and tightens, so the key reads as pushed in. On release the face pops back up on a bouncier spring (response 0.35 s, damping 0.55) with a tiny overshoot, accompanied by a medium impact haptic. It feels mechanical, chunky and satisfying, like a keyboard key or arcade button.",
            "由两层叠成的厚实游戏风按钮：上层是饱和渐变的面板，下层是同色系更深的底座，从面板下方露出 8pt，形成立体挤出感，并带柔和的落地投影。手指按下时，面板在约 120 毫秒内以接近临界阻尼的硬弹簧垂直下沉约 85% 的厚度，露出的底座随之消失，落地投影缩小收紧，读起来就是“按进去了”。松手时面板以更有弹性的弹簧（响应 0.35 秒、阻尼 0.55）弹回并轻微过冲，伴随一次中等强度的触觉反馈。手感机械、厚实、爽快，如同键盘键帽或街机按钮。"
        ),
        implementation: L(
            "A ButtonStyle stacks a base shape offset by the depth under the label's face; configuration.isPressed, held for at least 140 ms so quick taps in a scroll view still bottom out, offsets the face down and picks a stiff spring for press and a bouncy one for release.",
            "ButtonStyle 在按钮面板下叠放一个按深度偏移的底座；configuration.isPressed（至少保持 140 毫秒，确保在滚动视图里快速轻点也能按到底）让面板下移，并在按下和松手时分别选用硬弹簧与弹性弹簧。"
        ),
        apis: ["ButtonStyle", "offset", "spring(response:dampingFraction:)", "ZStack"],
        tags: ["3d", "depth", "keycap", "skeuomorphic", "立体", "按压", "键帽", "拟物"],
        params: [
            .slider("depth", L("Depth", "厚度"), 3...14, default: 8, decimals: 0, unit: "pt"),
            .slider("travel", L("Press travel", "按下行程"), 0.6...1.0, default: 0.85),
            .slider("bounce", L("Release damping", "回弹阻尼"), 0.3...1.0, default: 0.55),
        ]
    ) { ctx in
        ButtonDepthPressDemo(ctx: ctx)
    }
}

private struct ButtonDepthPressDemo: View {
    let ctx: DemoContext
    @State private var autoPressed = false
    @State private var taps = 0

    private var colors: (top: Color, bottom: Color, base: Color) {
        (Color(hex: 0xFF9A7A), Palette.coral, Color(hex: 0xC2452F))
    }

    var body: some View {
        let palette = colors
        VStack(spacing: 0) {
            Spacer()
            Button {
                taps += 1
                Haptics.tap(.medium)
            } label: {
                Text(ctx.language == .zh ? "开始游戏" : "PLAY NOW")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .shadow(color: palette.base.opacity(0.6), radius: 0, y: 1.5)
            }
            .buttonStyle(
                ButtonDepthStyle(
                    depth: ctx.cg("depth"),
                    travel: ctx.cg("travel"),
                    top: palette.top,
                    bottom: palette.bottom,
                    base: palette.base,
                    releaseDamping: ctx["bounce"],
                    forcePressed: autoPressed,
                    taps: taps
                )
            )
            Spacer()
            DemoHint(text: L("Press the key", "按下这个键"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.8) {
            // The detail intro presses once and lets go, so the key never stays held down.
            if ctx.isPreview { autoPressed.toggle() } else { introPress() }
        }
    }

    private func introPress() {
        autoPressed = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            autoPressed = false
        }
    }
}

private struct ButtonDepthStyle: ButtonStyle {
    let depth: CGFloat
    /// Fraction of the depth the face travels when pressed (1 = fully bottomed out).
    let travel: CGFloat
    let top: Color
    let bottom: Color
    let base: Color
    let releaseDamping: Double
    let forcePressed: Bool
    /// Counts completed taps, so a tap whose press the key never saw still plays a full press.
    let taps: Int

    func makeBody(configuration: Configuration) -> some View {
        DepthKey(style: self, configuration: configuration)
    }
}

/// The key itself. Inside a scroll view (the detail page) iOS delays a button's pressed state until
/// it knows the touch isn't a scroll, so a quick tap reports press and release almost together and the
/// face never visibly sinks. The key therefore holds its pressed look for a minimum time, so every
/// tap bottoms out before it springs back.
private struct DepthKey: View {
    let style: ButtonDepthStyle
    let configuration: ButtonStyleConfiguration
    @State private var held = false
    @State private var pressedAt = Date.distantPast
    @State private var releasedAt = Date.distantPast
    @State private var releaseTask: Task<Void, Never>?

    private static let minimumHold: TimeInterval = 0.14
    private let size = CGSize(width: 220, height: 62)

    var body: some View {
        let depth = style.depth
        let travel = style.travel
        let top = style.top
        let bottom = style.bottom
        let base = style.base
        let pressed = held || style.forcePressed
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return ZStack(alignment: .top) {
            shape
                .fill(base)
                .frame(width: size.width, height: size.height)
                .offset(y: depth)
                .shadow(color: base.opacity(pressed ? 0.25 : 0.45), radius: pressed ? 4 : 14, y: pressed ? 2 : 10)
            configuration.label
                .frame(width: size.width, height: size.height)
                .background(
                    LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom),
                    in: shape
                )
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(0.5), .clear], startPoint: .top, endPoint: .center),
                        lineWidth: 1.5
                    )
                )
                .offset(y: pressed ? depth * travel : 0)
        }
        .frame(width: size.width, height: size.height + depth, alignment: .top)
        .animation(
            pressed
                ? .spring(response: 0.12, dampingFraction: 0.9)
                : .spring(response: 0.35, dampingFraction: style.releaseDamping),
            value: pressed
        )
        .onChange(of: configuration.isPressed) { _, isPressed in
            releaseTask?.cancel()
            if isPressed {
                pressedAt = .now
                held = true
            } else {
                releasedAt = .now
                let remaining = Self.minimumHold - Date.now.timeIntervalSince(pressedAt)
                guard remaining > 0 else {
                    held = false
                    return
                }
                releaseTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(remaining))
                    guard !Task.isCancelled else { return }
                    held = false
                }
            }
        }
        // A very quick tap can deliver press and release in the same frame, before the key ever
        // renders as pressed; the action still fires, so play one full press from it.
        .onChange(of: style.taps) {
            guard !held, Date.now.timeIntervalSince(releasedAt) > 0.3 else { return }
            releaseTask?.cancel()
            pressedAt = .now
            held = true
            releaseTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(Self.minimumHold))
                guard !Task.isCancelled else { return }
                held = false
            }
        }
        .onDisappear {
            releaseTask?.cancel()
            held = false
        }
    }
}
