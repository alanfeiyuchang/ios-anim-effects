import SwiftUI

extension Effect {
    static let morphCircularReveal = Effect(
        id: "morph.circular-reveal",
        category: .morph,
        interaction: .tap,
        name: L("Circular Reveal", "圆形揭示"),
        summary: L(
            "A new theme floods the screen from the exact point you touched.",
            "新主题从手指触碰的位置以圆形扩散铺满屏幕。"
        ),
        prompt: L(
            "A settings screen in its day theme. Tapping anywhere — typically the sun/moon toggle — reveals the night theme through a circular mask centered on the touch point: the circle grows from 0 to the distance of the farthest screen corner in about 700 ms on an expo in-out curve (cubic-bezier 0.7, 0, 0.2, 1), so it starts slowly, sweeps fast and lands softly. The new theme is fully rendered underneath, so text and controls appear crisply inside the expanding edge rather than fading. The sun glyph becomes a moon the instant the edge sweeps over it, and a light haptic lands on touch. Once complete the layers swap invisibly so the next tap can reveal back from a new origin.",
            "一个日间主题的设置页面。点击任意位置（通常是太阳/月亮切换按钮），夜间主题会通过一个以触点为圆心的圆形遮罩展开：圆的半径在约 700 毫秒内从 0 增长到触点到最远屏幕角的距离，使用 expo 缓入缓出曲线（cubic-bezier 0.7, 0, 0.2, 1）——起步缓、中段快、落地柔。新主题在下方已完整渲染，因此文字与控件在扩散边缘内清晰出现，而不是淡入。扩散边缘扫过切换按钮的瞬间，太阳图标即变为月亮；触摸时伴随轻触觉。完成后两层无痕交换，下一次点击可以从新的触点反向揭示。"
        ),
        implementation: L(
            "The incoming theme is layered on top and masked by a Circle positioned at the tap location from onTapGesture; its diameter animates to twice the farthest-corner distance, then the layers swap inside a non-animated transaction.",
            "新主题叠放在上层，并用定位于 onTapGesture 触点的 Circle 作为遮罩；直径动画到最远角距离的两倍，完成后在禁用动画的事务中交换两层。"
        ),
        apis: ["mask", "onTapGesture(coordinateSpace:perform:)", "onGeometryChange", "withAnimation(_:completion:)", "timingCurve"],
        tags: ["reveal", "theme switch", "dark mode", "mask", "揭示", "主题切换", "深色模式", "遮罩"],
        params: [
            .slider("duration", L("Duration", "时长"), 0.3...1.5, default: 0.7, unit: "s"),
            .choice("curve", L("Curve", "曲线"), [L("Expo", "指数"), L("Ease out", "缓出"), L("Spring", "弹簧")], default: 0),
        ]
    ) { ctx in
        CircularRevealDemo(ctx: ctx)
    }
}

private struct CircularRevealDemo: View {
    let ctx: DemoContext
    @State private var baseDark = false
    @State private var progress: CGFloat = 0
    @State private var origin: CGPoint = .zero
    @State private var size: CGSize = .zero
    @State private var animating = false

    private var diameter: CGFloat {
        let corners = [
            CGPoint.zero,
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height),
        ]
        let farthest = corners.map { hypot($0.x - origin.x, $0.y - origin.y) }.max() ?? 0
        return farthest * 2 * progress
    }

    var body: some View {
        ZStack {
            ThemePanel(dark: baseDark, language: ctx.language)
            ThemePanel(dark: !baseDark, language: ctx.language)
                .mask {
                    Circle()
                        .frame(width: diameter, height: diameter)
                        .position(origin)
                }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            size = newSize
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            reveal(from: location)
        }
        .autoplay(ctx.isPreview, every: 1.8) {
            reveal(from: CGPoint(x: size.width - 46, y: 46))
        }
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap anywhere to switch theme", "点击任意位置切换主题"), ctx: ctx)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, 14)
                .opacity(ctx.isPreview ? 0 : 1)
                .allowsHitTesting(false)
        }
    }

    private var animation: Animation {
        let duration = ctx["duration"]
        switch ctx.int("curve") {
        case 1: return .easeOut(duration: duration)
        case 2: return .spring(duration: duration, bounce: 0)
        default: return .timingCurve(0.7, 0, 0.2, 1, duration: duration)
        }
    }

    private func reveal(from point: CGPoint) {
        guard !animating else { return }
        if !ctx.isPreview { Haptics.tap() }
        animating = true
        origin = point
        withAnimation(animation) {
            progress = 1
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                baseDark.toggle()
                progress = 0
            }
            animating = false
        }
    }
}

private struct ThemePanel: View {
    let dark: Bool
    let language: AppLanguage

    private var ink: Color { dark ? .white : Color(hex: 0x1B1D2A) }
    private var background: LinearGradient {
        LinearGradient(
            colors: dark ? [Color(hex: 0x0E1024), Color(hex: 0x262B57)] : [Color(hex: 0xFFF8EE), Color(hex: 0xE9EEFF)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(language == .zh ? "外观" : "Appearance")
                        .font(.title2.weight(.bold))
                    Text(dark ? (language == .zh ? "夜间模式" : "Night mode") : (language == .zh ? "日间模式" : "Day mode"))
                        .font(.subheadline)
                        .opacity(0.6)
                }
                Spacer()
                Image(systemName: dark ? "moon.stars.fill" : "sun.max.fill")
                    .font(.title2)
                    .foregroundStyle(dark ? Palette.amber : Palette.coral)
                    .frame(width: 48, height: 48)
                    .background(ink.opacity(0.08), in: Circle())
            }
            VStack(spacing: 0) {
                row(symbol: "bold", title: language == .zh ? "粗体文本" : "Bold Text", on: true)
                Divider().overlay(ink.opacity(0.1))
                row(symbol: "circle.lefthalf.filled", title: language == .zh ? "自动切换" : "Automatic", on: dark)
                Divider().overlay(ink.opacity(0.1))
                row(symbol: "moon.circle", title: language == .zh ? "夜览" : "Night Shift", on: dark)
                Divider().overlay(ink.opacity(0.1))
                row(symbol: "circle.righthalf.filled", title: language == .zh ? "增强对比度" : "Increase Contrast", on: false)
                Divider().overlay(ink.opacity(0.1))
                row(symbol: "sparkles", title: language == .zh ? "减弱动态效果" : "Reduce Motion", on: false)
            }
            .padding(.horizontal, 14)
            .background(ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer(minLength: 0)
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(background)
    }

    private func row(symbol: String, title: String, on: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 22)
                .opacity(0.7)
            Text(title).font(.subheadline.weight(.medium))
            Spacer()
            Capsule()
                .fill(on ? Palette.mint : ink.opacity(0.15))
                .frame(width: 42, height: 26)
                .overlay(alignment: on ? .trailing : .leading) {
                    Circle().fill(.white).padding(3).shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                }
        }
        .frame(height: 46)
    }
}
