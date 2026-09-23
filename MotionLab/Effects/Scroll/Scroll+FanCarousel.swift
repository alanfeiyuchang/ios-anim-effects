import SwiftUI

extension Effect {
    static let scrollFanCarousel = Effect(
        id: "scroll.fan-carousel",
        category: .scroll,
        interaction: .scroll,
        name: L("Fanned Hand Carousel", "扇形手牌轮播"),
        summary: L("Cards ride a wide arc like a hand of playing cards, tilting outward and dipping as they leave the center.", "卡片沿大弧线排开，像手中的一把扑克牌，离开中心时向外倾斜并下沉。"),
        prompt: L(
            "A carousel of 140×190 pt cards laid out like a hand of playing cards on the rim of a large wheel (radius 420 pt): the centered card stands upright and raised, and each step away rotates a card by 14° around the wheel, so it tilts outward, drops along the arc and overlaps its neighbour. Cards away from the center also shrink by up to 10% and dim slightly, and the focused card gains a soft 18 pt glow. Scrolling turns the whole hand continuously under the finger; release snaps the nearest card to the top of the arc with a selection haptic, and tapping any card turns the wheel to it (spring response 0.5 s, damping 0.86). Playful, tactile and a little casino.",
            "一组140×190 pt的卡片像手中的一把扑克牌，排列在一个半径420 pt的大轮盘边缘：居中的卡片直立且位置最高，每离开中心一格就绕轮盘旋转14°，于是向外倾斜、沿弧线下沉，并与相邻卡片交叠。离开中心的卡片还会最多缩小10%并略微变暗，聚焦的卡片带有18 pt的柔和光晕。滚动时整把牌在手指下连续转动；松手后最近的卡片吸附到弧顶并伴随选择触感，点击任意卡片则转到它（弹簧响应0.5秒、阻尼0.86）。俏皮、可触，还带点赌场的味道。"
        ),
        implementation: L(
            "Items keep a plain horizontal layout with a stride-snapping ScrollTargetBehavior; each card's visualEffect converts its distance from the center into a wheel angle and replaces the linear position with the arc position (R·sinθ, R·(1−cosθ)) plus a matching rotationEffect.",
            "卡片保持普通的横向布局，并用按步长吸附的 ScrollTargetBehavior；每张卡的 visualEffect 把到中心的距离换算成轮盘角度，用弧线位置（R·sinθ, R·(1−cosθ)）替换线性位置，并施加对应的 rotationEffect。"
        ),
        apis: ["visualEffect", "rotationEffect", "ScrollTargetBehavior", "onScrollGeometryChange", "ScrollPosition"],
        tags: ["fan", "arc", "carousel", "playing cards", "扇形", "弧形", "轮播", "扑克牌"],
        params: [
            .slider("step", L("Angle per card", "每张角度"), 4...24, default: 14, step: 1, decimals: 0, unit: "°"),
            .slider("radius", L("Wheel radius", "轮盘半径"), 200...800, default: 420, step: 10, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ScrollFanDemo(ctx: ctx)
    }
}

private struct ScrollFanDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .leading)
    @State private var current: Int
    @State private var width: CGFloat = 340
    @State private var direction = 1
    /// True while autoplay (or the detail intro) scrolls, so scripted selection ticks stay silent.
    @State private var scripted = false

    private let count = 9
    private let cardSize = CGSize(width: 140, height: 190)
    private let pitch: CGFloat = 110

    /// Still thumbnails never run `onAppear`, so the initial scroll never happens and item 0 sits in the
    /// selection band: seed the index to match, so title, chip and highlight describe what is drawn.
    init(ctx: DemoContext) {
        self.ctx = ctx
        _current = State(initialValue: ctx.isStill ? 0 : 3)
    }

    var body: some View {
        VStack(spacing: 8) {
            wheel
            Text(ScrollKit.title(current), ctx.language)
                .font(.headline)
                .contentTransition(.interpolate)
                .animation(.snappy, value: current)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: current) {
            if !ctx.isPreview && !scripted { Haptics.selection() }
        }
        .autoplay(ctx.isPreview, every: 1.3) { advance() }
    }

    private var wheel: some View {
        let stepAngle: Double = ctx["step"]
        let radius = ctx.cg("radius")
        let viewport = max(width, 1)
        let pitch = self.pitch
        let count = self.count
        return ScrollView(.horizontal) {
            LazyHStack(spacing: pitch - cardSize.width) {
                ForEach(0..<count, id: \.self) { i in
                    ScrollFanCard(index: i, focused: i == current, language: ctx.language, size: cardSize)
                        .visualEffect { content, proxy in
                            let mid: CGFloat = proxy.frame(in: .scrollView).midX
                            let d: CGFloat = (mid - viewport / 2) / pitch
                            let theta: Double = Double(d) * stepAngle * .pi / 180
                            let arcX: CGFloat = radius * CGFloat(sin(theta))
                            let arcY: CGFloat = radius * CGFloat(1 - cos(theta))
                            let near: CGFloat = min(abs(d), 1)
                            return content
                                .rotationEffect(.radians(theta))
                                .scaleEffect(1 - near * 0.1)
                                .brightness(-Double(near) * 0.08)
                                .offset(x: arcX - d * pitch, y: arcY - 24)
                        }
                        // Neighbours overlap: cards nearer the top of the arc draw above the rest.
                        .zIndex(-Double(abs(i - current)))
                        .onTapGesture { select(i) }
                }
            }
            .padding(.horizontal, max((width - cardSize.width) / 2, 0))
        }
        .scrollTargetBehavior(ScrollStrideSnap(pitch: pitch))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self, of: { geometry in
            let offset = geometry.contentOffset.x + geometry.contentInsets.leading
            return Int((offset / pitch).rounded()).clamped(to: 0...(count - 1))
        }, action: { _, newValue in
            current = newValue
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting { scripted = false }
        }
        .onAppear { position.scrollTo(x: CGFloat(3) * pitch) }
        .scrollIndicators(.hidden)
        .frame(height: cardSize.height + 80)
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    private func select(_ i: Int) {
        scripted = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(i) * pitch)
        }
    }

    private func advance() {
        scripted = true
        if current + direction >= count || current + direction < 0 { direction = -direction }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
            position.scrollTo(x: CGFloat(current + direction) * pitch)
        }
    }
}

private struct ScrollFanCard: View {
    let index: Int
    let focused: Bool
    let language: AppLanguage
    let size: CGSize

    var body: some View {
        ScrollKitArt(index: index, language: language, showsTitle: false)
            .overlay(alignment: .topLeading) {
                Text(verbatim: "\(index + 1)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
            .shadow(color: focused ? Palette.violet.opacity(0.45) : .black.opacity(0.15), radius: focused ? 18 : 8, y: focused ? 8 : 4)
            .animation(.easeOut(duration: 0.25), value: focused)
    }
}
