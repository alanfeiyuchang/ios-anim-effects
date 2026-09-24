import SwiftUI

extension Effect {
    static let cardsParallaxLayers = Effect(
        id: "cards.parallax-layers",
        category: .cards,
        interaction: .gesture,
        name: L("Layered Parallax Card", "分层视差卡片"),
        summary: L("A landscape card whose sky, sun, ridges and title drift at different depths.", "风景卡片中的天空、太阳、山脊与标题以不同景深错位漂移。"),
        prompt: L(
            "A 240×300 pt poster card with 28 pt corners shows a dusk landscape built from separate layers: a violet-to-peach sky with faint stars, a glowing sun, a translucent far ridge, a dark near ridge and a bold title on top. Dragging tilts the card up to 8° while each layer shifts against the finger in proportion to its depth (stars ×0.1, sun ×0.25, far ridge ×0.55, near ridge ×0.9, title ×1.5 of a 16 pt base). Every layer rides its own spring whose response grows with depth, from about 0.3 s for the stars to 0.7 s for the title (damping 0.7), so on release the layers settle one after another and the scene seems to breathe back into place. Before the first touch the card sways slowly so the depth reads on arrival.",
            "一张240×300 pt、28 pt圆角的竖版海报卡，黄昏风景由多个图层叠成：缀着星光的紫到蜜桃色天空、发光的太阳、半透明远山、深色近山和最上层的粗体标题。拖动时卡片倾斜最多8°，各层按景深朝手指反方向平移——以16 pt为基准，星空×0.1、太阳×0.25、远山×0.55、近山×0.9、标题×1.5。每层各配一个弹簧，越靠前响应越慢，从星空约0.3秒到标题约0.7秒（阻尼0.7），松手后各层依次落定，画面像呼吸般回位。未触摸时卡片缓缓摇摆，展示纵深。"
        ),
        implementation: L(
            "A ZStack of shapes and gradients where each layer gets .offset(normalisedDrag × depth × amount) plus its own .animation(.spring, value:) whose response scales with depth; two rotation3DEffect modifiers add the tilt and clipShape hides the overscan.",
            "由形状与渐变组成的 ZStack，每层施加 .offset(归一化拖动 × 景深 × 幅度)，并各带一个响应随景深增大的 .animation(.spring, value:)；两个 rotation3DEffect 负责倾斜，clipShape 隐藏出血区域。"
        ),
        apis: ["offset", "animation(_:value:)", "rotation3DEffect", "DragGesture", "TimelineView"],
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
    /// True while a real finger holds the card.
    @State private var held = false
    /// Resets on system cancellation too, so a stolen touch never leaves the card tilted.
    @GestureState private var pressing = false

    var body: some View {
        VStack(spacing: 18) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: touched)) { timeline in
                CardsParallaxCard(
                    point: touched ? point : sway(at: timeline.date.timeIntervalSinceReferenceDate),
                    amount: ctx.cg("depth"),
                    tilt: ctx["tilt"],
                    response: ctx["response"],
                    language: ctx.language
                )
            }
            .gesture(drag)
            DemoHint(text: L("Drag the card", "拖动卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
    }

    /// Idle drift: full swing in previews, a gentler sway on the detail stage.
    private func sway(at t: Double) -> CGSize {
        let amount = ctx.isPreview ? 1.0 : 0.6
        return CGSize(width: sin(t * 0.8) * 0.9 * amount, height: cos(t * 1.1) * 0.5 * amount)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                held = true
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
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: the layers spring back to flat.
    private func endHold() {
        guard held else { return }
        held = false
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.7)) {
            point = .zero
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
    let response: Double
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
            stars.offset(layer(0.1)).animation(lag(0.1), value: point)
            sun.offset(layer(0.25)).animation(lag(0.25), value: point)
            ridges
            title.offset(layer(1.5)).animation(lag(1.5), value: point)
        }
        .frame(width: 240, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        .rotation3DEffect(.degrees(-Double(point.height) * tilt), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(Double(point.width) * tilt), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .shadow(color: Color(hex: 0x5B3BFF).opacity(0.3), radius: 24, x: -point.width * 12, y: 16)
    }

    /// Each layer rides its own spring; deeper-into-the-foreground layers respond more slowly,
    /// so after a release the layers settle one after another instead of together.
    private func lag(_ depth: CGFloat) -> Animation {
        .spring(response: response * (0.5 + 0.5 * Double(depth)), dampingFraction: 0.7)
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
                .animation(lag(0.55), value: point)
            CardsRidge(heights: [0.3, 0.5, 0.34, 0.58, 0.38, 0.52, 0.26])
                .fill(LinearGradient(colors: [Color(hex: 0x2A1E5C), Color(hex: 0x120D2E)], startPoint: .top, endPoint: .bottom))
                .frame(width: 330, height: 156)
                .offset(layer(0.9))
                .animation(lag(0.9), value: point)
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
