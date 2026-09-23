import SwiftUI

extension Effect {
    static let morphCubeTransition = Effect(
        id: "morph.cube-transition",
        category: .morph,
        interaction: .gesture,
        name: L("3D Cube Transition", "3D 立方体转场"),
        summary: L(
            "Pages sit on the faces of a cube and rotate around its edge as you swipe.",
            "页面贴在立方体的各个面上，随滑动绕棱旋转切换。"
        ),
        prompt: L(
            "Content pages are mapped onto the outer faces of a cube. Swiping horizontally rotates the cube around its vertical axis 1:1 with the finger: the current face pivots on its trailing edge toward –90° while the next face swings in from +90° on its leading edge, the two always sharing a seam, with perspective ≈0.5 so far edges visibly recede. Faces darken by up to 30% as they turn away, suggesting a light source in front. Releasing projects the fling velocity and snaps to the nearest face on a spring (response ≈0.5 s, damping ≈0.85); overscroll at either end rubber-bands. Faces keep near-square 6 pt corners so neighboring faces meet at a crisp shared edge. Page dots below track the rotation. The feel is solid, dimensional and satisfyingly mechanical.",
            "内容页面贴在一个立方体的外侧各面上。水平滑动时立方体随手指 1:1 绕竖直轴旋转：当前面以右侧棱为轴转向 –90°，下一面以左侧棱为轴从 +90° 转入，两面始终共用一条棱；透视系数约 0.5，远端边缘明显后退。转离视线的面最多变暗 30%，仿佛正前方有光源。松手后根据甩动速度预测落点，以弹簧（响应约 0.5 秒、阻尼约 0.85）吸附到最近的一面；两端越界时呈橡皮筋阻尼。各面仅保留 6 pt 的小圆角，相邻两面在棱上严丝合缝地相接。下方页码圆点随旋转同步。整体坚实、立体，带有令人愉悦的机械感。"
        ),
        implementation: L(
            "An Animatable ViewModifier maps each face's continuous position (index − progress) to rotation3DEffect with an edge anchor, an x offset and a brightness shade, so both drags and springs are evaluated per frame.",
            "自定义 Animatable ViewModifier 将每个面的连续位置（索引 − 进度）映射为以棱为锚点的 rotation3DEffect、水平位移与亮度阴影，拖拽与弹簧动画都逐帧计算。"
        ),
        apis: ["rotation3DEffect(_:axis:anchor:perspective:)", "Animatable", "DragGesture", "predictedEndTranslation"],
        tags: ["cube", "3d", "carousel", "page transition", "立方体", "3D 转场", "翻页", "轮播"],
        params: [
            .slider("perspective", L("Perspective", "透视"), 0.1...1.5, default: 0.5),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .toggle("shade", L("Face shading", "侧面阴影"), default: true),
        ]
    ) { ctx in
        CubeTransitionDemo(ctx: ctx)
    }
}

private struct CubePage {
    let symbol: String
    let colors: [Color]
    let title: LocalizedText
    let subtitle: LocalizedText
}

private let cubePages: [CubePage] = [
    CubePage(symbol: "sun.max.fill", colors: [Palette.amber, Palette.coral], title: L("Morning", "清晨"), subtitle: L("6:40 · Sunrise run", "6:40 · 日出晨跑")),
    CubePage(symbol: "leaf.fill", colors: [Palette.mint, Palette.sky], title: L("Garden", "花园"), subtitle: L("Water the ferns", "给蕨类浇水")),
    CubePage(symbol: "sparkles", colors: [Palette.violet, Palette.pink], title: L("Studio", "工作室"), subtitle: L("Review motion specs", "评审动效规范")),
    CubePage(symbol: "moon.stars.fill", colors: [Palette.indigo, Color(hex: 0x241B5C)], title: L("Night", "夜晚"), subtitle: L("22:30 · Wind down", "22:30 · 放松入睡")),
]

private struct CubeTransitionDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var dragStart: CGFloat?
    @State private var previewDirection: CGFloat = 1

    private let faceWidth: CGFloat = 230
    private var lastIndex: CGFloat { CGFloat(cubePages.count - 1) }

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                ForEach(0..<cubePages.count, id: \.self) { index in
                    CubeFaceView(page: cubePages[index], language: ctx.language)
                        .frame(width: faceWidth, height: 250)
                        .modifier(CubeFace(
                            position: CGFloat(index) - progress,
                            width: faceWidth,
                            perspective: ctx.cg("perspective"),
                            shade: ctx.bool("shade")
                        ))
                }
            }
            .frame(width: faceWidth, height: 250)
            .contentShape(Rectangle())
            .pageSafeHorizontalDrag(onChanged: dragChanged, onEnded: dragEnded)
            dots
            DemoHint(text: L("Swipe left or right to turn the cube", "左右滑动旋转立方体"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) {
            // Ping-pong through the faces so the preview never jumps from the last face back to the first.
            let current = progress.rounded()
            if current + previewDirection > lastIndex || current + previewDirection < 0 {
                previewDirection = -previewDirection
            }
            snap(to: current + previewDirection)
        }
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0..<cubePages.count, id: \.self) { index in
                let active = max(0, 1 - abs(progress - CGFloat(index)))
                Capsule()
                    .fill(Color.primary.opacity(0.2 + 0.6 * Double(active)))
                    .frame(width: 7 + 12 * active, height: 7)
            }
        }
    }

    private func dragChanged(_ value: DragGesture.Value) {
        let start = dragStart ?? progress
        if dragStart == nil { dragStart = progress }
        let raw = start - value.translation.width / faceWidth
        if raw < 0 {
            progress = rubberBand(raw * faceWidth, limit: 60) / faceWidth
        } else if raw > lastIndex {
            progress = lastIndex + rubberBand((raw - lastIndex) * faceWidth, limit: 60) / faceWidth
        } else {
            progress = raw
        }
    }

    /// Release projects the flick (one face at most); a system cancellation (`nil`) snaps to the nearest face.
    private func dragEnded(_ value: DragGesture.Value?) {
        let start: CGFloat = dragStart ?? progress
        dragStart = nil
        let projected: CGFloat = value.map { start - $0.predictedEndTranslation.width / faceWidth } ?? progress
        let target: CGFloat = min(max(projected.rounded(), start.rounded() - 1), start.rounded() + 1)
        snap(to: target.clamped(to: 0...lastIndex))
    }

    private func snap(to target: CGFloat) {
        if !ctx.isPreview && target != progress.rounded() { Haptics.tap(.soft) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.85)) {
            progress = target
        }
    }
}

/// Places a face on the cube from its continuous position: 0 = facing the viewer, ±1 = side faces.
private struct CubeFace: ViewModifier, Animatable {
    var position: CGFloat
    let width: CGFloat
    let perspective: CGFloat
    let shade: Bool

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    func body(content: Content) -> some View {
        let p = position.clamped(to: -1...1)
        return content
            .brightness(shade ? -0.3 * Double(abs(p)) : 0)
            .rotation3DEffect(
                .degrees(Double(p) * 90),
                axis: (x: 0, y: 1, z: 0),
                anchor: p < 0 ? .trailing : .leading,
                perspective: perspective
            )
            .offset(x: p * width)
            .opacity(abs(position) < 0.999 ? 1 : 0)
    }
}

private struct CubeFaceView: View {
    let page: CubePage
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: page.symbol)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(page.title, language)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(page.subtitle, language)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding(22)
        .background(LinearGradient(colors: page.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        // Near-square corners: faces must meet at a crisp shared edge to read as a cube.
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
