import SwiftUI

extension Effect {
    static let cardsParallaxLayers = Effect(
        id: "cards.parallax-layers",
        category: .cards,
        interaction: .gesture,
        name: L("Layered Parallax Card", "分层视差卡片"),
        summary: L("A landscape card whose sky, sun, ridges and title drift at different depths.", "风景卡片中的天空、太阳、山脊与标题以不同景深错位漂移。"),
        prompt: L(
            "A tall poster card (240×300 pt, 28 pt corners) illustrates a dusk landscape built from separate layers: a violet-to-peach sky with faint stars, a glowing sun, a translucent far ridge, a dark near ridge and a bold title floating on top. Dragging tilts the card up to ~8° in perspective while every layer translates against the gesture by an amount proportional to its depth — stars ×0.1, sun ×0.25, far ridge ×0.55, near ridge ×0.9, title ×1.5 of a 16 pt base — revealing convincing depth like tvOS focus posters. Layers are overscanned so edges never show. Release returns all layers together on a soft spring (response ≈0.55 s, damping ≈0.7). Until the first touch the card drifts in a slow idle sway so the depth is visible on arrival.",
            "一张竖版海报卡片（240×300 pt，28 pt 圆角）描绘黄昏风景，由多个独立图层组成：紫色到蜜桃色的天空与点点星光、发光的太阳、半透明远山、深色近山，以及浮于最上层的粗体标题。拖动时卡片以透视方式倾斜最多约 8°，同时每一层按其景深比例朝手势反方向平移——以 16 pt 为基准，星空 ×0.1、太阳 ×0.25、远山 ×0.55、近山 ×0.9、标题 ×1.5——呈现类似 tvOS 焦点海报的真实纵深感。各图层留有出血，边缘永不露底。松手后所有图层以柔和弹簧（响应约 0.55 秒、阻尼约 0.7）一同归位。首次触摸前，卡片会缓慢地自行摇摆，一进入页面即可看出纵深。"
        ),
        implementation: L(
            "A ZStack of shapes and gradients where each layer gets .offset(normalisedDrag × depth × amount); a pair of rotation3DEffect modifiers add the tilt and clipShape hides the overscan.",
            "由形状与渐变组成的 ZStack，每层施加 .offset(归一化拖动 × 景深 × 幅度)；两个 rotation3DEffect 负责倾斜，clipShape 隐藏出血区域。"
        ),
        apis: ["offset", "rotation3DEffect", "Shape", "DragGesture", "TimelineView"],
        tags: ["parallax", "depth", "layers", "tvOS", "视差", "景深", "分层", "海报"],
        params: [
            .slider("depth", L("Parallax depth", "视差幅度"), 0...30, default: 16, step: 1, decimals: 0, unit: "pt"),
            .slider("tilt", L("Tilt", "倾斜"), 0...20, default: 8, step: 1, decimals: 0, unit: "°"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.55, unit: "s"),
        ]
    ) { ctx in
        CardsParallaxDemo(ctx: ctx)
    }
}

private struct CardsParallaxDemo: View {
    let ctx: DemoContext
    @State private var point: CGSize = .zero
    /// Until the first touch the layers drift on their own so the depth reads on arrival.
    @State private var touched = false

    var body: some View {
        VStack(spacing: 18) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: touched)) { timeline in
                CardsParallaxCard(
                    point: touched ? point : sway(at: timeline.date.timeIntervalSinceReferenceDate),
                    amount: ctx.cg("depth"),
                    tilt: ctx["tilt"],
                    language: ctx.language
                )
            }
            .gesture(drag)
            DemoHint(text: L("Drag the card", "拖动卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Idle drift: full swing in previews, a gentler sway on the detail stage.
    private func sway(at t: Double) -> CGSize {
        let amount = ctx.isPreview ? 1.0 : 0.6
        return CGSize(width: sin(t * 0.8) * 0.9 * amount, height: cos(t * 1.1) * 0.5 * amount)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !touched {
                    point = sway(at: Date().timeIntervalSinceReferenceDate)
                    touched = true
                }
                let x = (value.location.x / 240 - 0.5) * 2
                let y = (value.location.y / 300 - 0.5) * 2
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                    point = CGSize(width: x.clamped(to: -1...1), height: y.clamped(to: -1...1))
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: ctx["response"], dampingFraction: 0.7)) {
                    point = .zero
                }
            }
    }
}

private struct CardsRidge: Shape {
    let heights: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        let steps = CGFloat(max(heights.count - 1, 1))
        for (i, h) in heights.enumerated() {
            let x = rect.minX + rect.width * CGFloat(i) / steps
            path.addLine(to: CGPoint(x: x, y: rect.maxY - rect.height * h))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CardsParallaxCard: View {
    let point: CGSize
    let amount: CGFloat
    let tilt: Double
    let language: AppLanguage

    private static let stars: [CGPoint] = [
        CGPoint(x: -90, y: -120), CGPoint(x: -30, y: -135), CGPoint(x: 40, y: -110), CGPoint(x: 95, y: -128),
        CGPoint(x: -60, y: -85), CGPoint(x: 70, y: -80), CGPoint(x: 10, y: -95),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x2B2F77), Color(hex: 0x8A5CFF), Color(hex: 0xFF8A7A), Color(hex: 0xFFC58A)],
                startPoint: .top,
                endPoint: .bottom
            )
            .scaleEffect(1.15)
            stars.offset(layer(0.1))
            sun.offset(layer(0.25))
            ridges
            title.offset(layer(1.5))
        }
        .frame(width: 240, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        .rotation3DEffect(.degrees(-Double(point.height) * tilt), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(Double(point.width) * tilt), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .shadow(color: Color(hex: 0x5B3BFF).opacity(0.3), radius: 24, x: -point.width * 12, y: 16)
    }

    private func layer(_ depth: CGFloat) -> CGSize {
        CGSize(width: -point.width * amount * depth, height: -point.height * amount * depth)
    }

    private var stars: some View {
        ZStack {
            ForEach(CardsParallaxCard.stars.indices, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(i.isMultiple(of: 2) ? 0.9 : 0.5))
                    .frame(width: i.isMultiple(of: 3) ? 3 : 2, height: i.isMultiple(of: 3) ? 3 : 2)
                    .offset(x: CardsParallaxCard.stars[i].x, y: CardsParallaxCard.stars[i].y)
            }
        }
    }

    private var sun: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(hex: 0xFFF3C4), Color(hex: 0xFFB36B)], center: .center, startRadius: 2, endRadius: 34))
            .frame(width: 64, height: 64)
            .shadow(color: Color(hex: 0xFFB36B).opacity(0.8), radius: 24)
            .offset(y: 10)
    }

    private var ridges: some View {
        ZStack(alignment: .bottom) {
            CardsRidge(heights: [0.35, 0.62, 0.42, 0.78, 0.5, 0.68, 0.38])
                .fill(Color(hex: 0x6B4FD8).opacity(0.75))
                .frame(width: 320, height: 170)
                .offset(layer(0.55))
            CardsRidge(heights: [0.3, 0.5, 0.34, 0.58, 0.38, 0.52, 0.26])
                .fill(LinearGradient(colors: [Color(hex: 0x2A1E5C), Color(hex: 0x120D2E)], startPoint: .top, endPoint: .bottom))
                .frame(width: 330, height: 156)
                .offset(layer(0.9))
                .offset(y: 28)
        }
        .frame(width: 240, height: 300, alignment: .bottom)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("DOLOMITES", "多洛米蒂"), language)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .tracking(2)
            Text(L("Alta Via 1 · 7 days", "高山一号线 · 7 天"), language)
                .font(.footnote.weight(.semibold))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(width: 240, height: 300, alignment: .bottomLeading)
    }
}
