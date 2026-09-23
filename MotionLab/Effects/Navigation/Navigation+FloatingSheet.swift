import SwiftUI

extension Effect {
    static let navigationFloatingSheet = Effect(
        id: "navigation.floating-sheet",
        category: .navigation,
        interaction: .gesture,
        name: L("Floating to Edge Sheet", "悬浮到贴边面板"),
        summary: L(
            "A small floating glass card grows into a full sheet, its margins and corners melting into the screen edges.",
            "小巧的悬浮玻璃卡片长成完整面板，边距与圆角逐渐融入屏幕边缘。"
        ),
        prompt: L(
            "Over a map, a compact sheet floats 12 pt above the bottom and in from the sides as a glass card with 30 pt corners. Dragging it up (or tapping) moves through three detents — compact 96 pt, medium 190 pt, full — and every property is a function of height: side and bottom margins shrink from 12 pt to 0, the bottom corners flatten while the top corners ease from 30 to 24 pt, and the material shifts from translucent glass to an opaque surface. The sheet tracks the finger 1:1 with rubber-banding past the ends, and on release springs (response ≈0.45 s, damping 0.8) to the detent nearest the drag's projected end, with a light tick per detent. Like an iOS 26 floating sheet settling into the device.",
            "地图上方，一块紧凑面板以玻璃卡片的形态悬浮在距底部与两侧 12pt 处，圆角 30pt。向上拖动（或点击）会经过三个档位——紧凑 96pt、中等 190pt、全屏——而且所有属性都是高度的函数：左右与底部边距从 12pt 缩小到 0，底部圆角逐渐变平、顶部圆角从 30pt 缓和到 24pt，材质从半透明玻璃过渡到不透明表面。面板 1:1 跟手，超出两端时有橡皮筋阻尼；松手后依据拖拽的预测终点以弹簧（响应约 0.45 秒、阻尼 0.8）吸附到最近的档位，每到一个档位轻触一次。就像 iOS 26 的悬浮面板落定到设备边缘。"
        ),
        implementation: L(
            "Sheet height is the only state; margins, corner radii (UnevenRoundedRectangle) and the opacity of an opaque layer over the material are all interpolated from it in body, so drag and spring stay in lockstep.",
            "面板高度是唯一的状态；边距、圆角（UnevenRoundedRectangle）以及叠在材质上的不透明层的透明度都在 body 中由高度插值得出，因此拖拽与弹簧始终同步。"
        ),
        apis: ["UnevenRoundedRectangle", "DragGesture", "predictedEndTranslation", "Material", "spring(response:dampingFraction:)"],
        tags: ["sheet", "detents", "floating", "glass", "面板", "档位", "悬浮", "玻璃"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.55...1.0, default: 0.8),
            .toggle("glass", L("Glass when compact", "紧凑时为玻璃"), default: true),
        ]
    ) { ctx in
        FloatingSheetDemo(ctx: ctx)
    }
}

private struct FloatingSheetDemo: View {
    let ctx: DemoContext
    @State private var height: CGFloat = 96
    @State private var dragStart: CGFloat?
    @State private var autoStep = 0

    private let frameSize = CGSize(width: 250, height: 330)
    private var detents: [CGFloat] { [96, 190, frameSize.height - 30] }

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                FloatingMapBackdrop()
                sheet
            }
            .frame(width: frameSize.width, height: frameSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            DemoHint(text: L("Drag the sheet or tap it", "拖动或点击面板"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.3) {
            let sequence: [Int] = [1, 2, 1, 0]
            snap(to: detents[sequence[autoStep % sequence.count]])
            autoStep += 1
        }
    }

    private var sheet: some View {
        let low: CGFloat = detents[0]
        let high: CGFloat = detents[2]
        let t: CGFloat = min(max((height - low) / (high - low), 0), 1)
        let margin: CGFloat = 12 * (1 - t)
        let topRadius: CGFloat = 30 - 6 * t
        let bottomRadius: CGFloat = 30 * (1 - t)
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: topRadius,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: topRadius,
            style: .continuous
        )
        let solid: Double = ctx.bool("glass") ? Double(min(t * 1.6, 1)) : 1
        return FloatingSheetContent(expansion: t, language: ctx.language)
            .frame(width: frameSize.width - margin * 2, height: max(height, 60), alignment: .top)
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(Palette.elevated).opacity(solid)
                }
            }
            .clipShape(shape)
            .overlay(shape.stroke(Color.white.opacity(0.25 * (1 - solid)), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 16, y: 4)
            .padding(.bottom, margin)
            .contentShape(Rectangle())
            .gesture(drag)
            .onTapGesture { cycle() }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                let start = dragStart ?? height
                if dragStart == nil { dragStart = height }
                let raw: CGFloat = start - value.translation.height
                let low: CGFloat = detents[0]
                let high: CGFloat = detents[2]
                if raw > high {
                    height = high + rubberBand(raw - high, limit: 24)
                } else if raw < low {
                    height = low + rubberBand(raw - low, limit: 24)
                } else {
                    height = raw
                }
            }
            .onEnded { value in
                let start = dragStart ?? height
                dragStart = nil
                let projected: CGFloat = start - value.predictedEndTranslation.height
                let nearest: CGFloat = detents.min { abs($0 - projected) < abs($1 - projected) } ?? detents[0]
                snap(to: nearest)
            }
    }

    private func cycle() {
        let index: Int = detents.firstIndex { abs($0 - height) < 1 } ?? 0
        snap(to: detents[(index + 1) % detents.count])
    }

    private func snap(to target: CGFloat) {
        if !ctx.isPreview && abs(target - height) > 1 { Haptics.tap(.light) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            height = target
        }
    }
}

private struct FloatingSheetContent: View {
    let expansion: CGFloat
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.45))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            HStack(spacing: 10) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Palette.coral.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Harbor Coffee", "港湾咖啡"), language)
                        .font(.subheadline.weight(.bold))
                    Text(L("Open · 4 min walk", "营业中 · 步行 4 分钟"), language)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.spectrum[index + 3].opacity(0.3))
                        .frame(height: 64)
                }
            }
            .opacity(Double(min(max(expansion * 3 - 0.2, 0), 1)))
            PlaceholderLines(count: 4)
                .opacity(Double(min(max(expansion * 2 - 1, 0), 1)))
        }
        .padding(.horizontal, 16)
    }
}

private struct FloatingMapBackdrop: View {
    var body: some View {
        ZStack {
            Color.adaptive(light: 0xE8EEF2, dark: 0x1E2328)
            Canvas { context, size in
                var roads = Path()
                roads.move(to: CGPoint(x: 0, y: size.height * 0.3))
                roads.addCurve(to: CGPoint(x: size.width, y: size.height * 0.45), control1: CGPoint(x: size.width * 0.4, y: size.height * 0.15), control2: CGPoint(x: size.width * 0.6, y: size.height * 0.6))
                roads.move(to: CGPoint(x: size.width * 0.35, y: 0))
                roads.addLine(to: CGPoint(x: size.width * 0.55, y: size.height))
                context.stroke(roads, with: .color(.white.opacity(0.7)), lineWidth: 10)
                context.stroke(roads, with: .color(.gray.opacity(0.25)), lineWidth: 1)
                let park = Path(roundedRect: CGRect(x: size.width * 0.62, y: size.height * 0.08, width: 70, height: 50), cornerRadius: 14)
                context.fill(park, with: .color(Palette.green.opacity(0.25)))
            }
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white, Palette.coral)
                .offset(x: 10, y: -70)
        }
    }
}
