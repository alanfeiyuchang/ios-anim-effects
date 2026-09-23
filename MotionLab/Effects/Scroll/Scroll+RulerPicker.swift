import SwiftUI

extension Effect {
    static let scrollRulerPicker = Effect(
        id: "scroll.ruler-picker",
        category: .scroll,
        interaction: .scroll,
        name: L("Ruler Picker", "刻度尺选择器"),
        summary: L("A horizontal tick ruler that snaps to each unit, swelling the ticks under a fixed center needle.", "横向刻度尺逐格吸附，固定中心指针下方的刻度随之放大。"),
        prompt: L(
            "A weight picker: a horizontal ruler of ticks every 12 pt (one per kilogram, 40–120 kg) with taller labelled ticks every 5 kg, scrolling under a fixed 3 pt gradient needle in the center. Ticks swell as they approach the needle — up to 1.7× taller and fully opaque within 60 pt, fading to 35% further out — so the ruler reads like a lens. Scrolling snaps to whole kilograms; every tick that crosses the needle fires a selection haptic, and the big value above rolls its digits with a numeric transition. Both edges fade out through a gradient mask. Precise, tactile and calm, like a fitness app's onboarding picker.",
            "一个体重选择器：横向刻度尺每 12 pt 一格（每格 1 公斤，40–120 公斤），每 5 公斤有一根带数字的长刻度，在中央一根固定的 3 pt 渐变指针下滚动。刻度靠近指针时会膨胀——在 60 pt 内最高放大到 1.7 倍并完全不透明，远处则淡到 35%——整把尺子像被放大镜扫过。滚动吸附到整公斤；每根刻度经过指针都会触发选择触感，上方的大号数值以数字滚动过渡切换。两端通过渐变遮罩淡出。精准、可触、沉静，就像健身 App 引导页里的选择器。"
        ),
        implementation: L(
            "Spacer padding centers tick i at offset i × 12 pt; a stride-snapping ScrollTargetBehavior lands on whole ticks, each tick's visualEffect scales it by its distance from the center, and onScrollGeometryChange derives the value for the numericText label and sensoryFeedback.",
            "两侧留白让第 i 根刻度在偏移为 i × 12 pt 时居中；按步长吸附的 ScrollTargetBehavior 落在整格上，每根刻度的 visualEffect 按到中心的距离缩放，onScrollGeometryChange 推算数值，驱动 numericText 标签与 sensoryFeedback。"
        ),
        apis: ["visualEffect", "ScrollTargetBehavior", "onScrollGeometryChange", "contentTransition(.numericText(value:))", "sensoryFeedback"],
        tags: ["ruler", "picker", "ticks", "weight", "刻度尺", "选择器", "刻度", "体重"],
        params: [
            .slider("swell", L("Tick swell", "刻度放大"), 1...2.5, default: 1.7),
            .slider("lens", L("Lens width", "放大范围"), 20...140, default: 60, step: 5, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ScrollRulerDemo(ctx: ctx)
    }
}

private let scrollRulerMin = 40
private let scrollRulerMax = 120

private struct ScrollRulerDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .leading)
    @State private var index = 28
    @State private var width: CGFloat = 340
    @State private var step = 0

    private let spacing: CGFloat = 12

    var body: some View {
        VStack(spacing: 22) {
            readout
            ruler
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: index) { _, _ in !ctx.isPreview }
        .autoplay(ctx.isPreview, every: 1.4) { autoScroll() }
    }

    private var readout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(verbatim: "\(scrollRulerMin + index)")
                .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: Double(index)))
                .animation(.snappy, value: index)
            Text(verbatim: "kg")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var ruler: some View {
        let count = scrollRulerMax - scrollRulerMin + 1
        let viewport = max(width, 1)
        let swell = ctx.cg("swell")
        let lens = max(ctx.cg("lens"), 1)
        let stride = spacing
        return ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    ScrollRulerTick(value: scrollRulerMin + i, viewport: viewport, swell: swell, lens: lens)
                        .frame(width: stride, height: 96, alignment: .bottom)
                }
            }
            .padding(.horizontal, max((width - stride) / 2, 0))
        }
        .scrollTargetBehavior(ScrollStrideSnap(stride: stride))
        .scrollPosition($position)
        .onScrollGeometryChange(for: Int.self, of: { geometry in
            let offset = geometry.contentOffset.x + geometry.contentInsets.leading
            return Int((offset / stride).rounded()).clamped(to: 0...(count - 1))
        }, action: { _, newValue in
            index = newValue
        })
        .onAppear { position.scrollTo(x: CGFloat(28) * stride) }
        .scrollIndicators(.hidden)
        .frame(height: 100)
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(Palette.primary)
                .frame(width: 3, height: 70)
                .shadow(color: Palette.indigo.opacity(0.5), radius: 6)
                .allowsHitTesting(false)
        }
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.2),
                    .init(color: .black, location: 0.8),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }, action: { newWidth in
            width = newWidth
        })
    }

    private func autoScroll() {
        let targets = [34, 22, 45, 30, 12, 28]
        let target = targets[step % targets.count]
        step += 1
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            position.scrollTo(x: CGFloat(target) * spacing)
        }
    }
}

/// One tick: the bar swells near the center needle, the label (every 5 kg) only fades so its digits never stretch.
private struct ScrollRulerTick: View {
    let value: Int
    let viewport: CGFloat
    let swell: CGFloat
    let lens: CGFloat

    var body: some View {
        let major = value % 5 == 0
        let viewport = self.viewport
        let swell = self.swell
        let lens = self.lens
        VStack(spacing: 6) {
            if major {
                Text(verbatim: "\(value)")
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .visualEffect { content, proxy in
                        let mid: CGFloat = proxy.frame(in: .scrollView).midX
                        let t: CGFloat = min(abs(mid - viewport / 2) / lens, 1)
                        return content.opacity(0.35 + 0.65 * Double(1 - t))
                    }
            }
            Capsule()
                .fill(Color.primary.opacity(major ? 0.7 : 0.35))
                .frame(width: major ? 2 : 1.5, height: major ? 34 : 20)
                .visualEffect { content, proxy in
                    let mid: CGFloat = proxy.frame(in: .scrollView).midX
                    let t: CGFloat = min(abs(mid - viewport / 2) / lens, 1)
                    let grow: CGFloat = 1 + (swell - 1) * (1 - t)
                    return content
                        .scaleEffect(x: 1, y: grow, anchor: .bottom)
                        .opacity(0.35 + 0.65 * Double(1 - t))
                }
        }
    }
}
