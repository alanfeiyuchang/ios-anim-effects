import SwiftUI

extension Effect {
    static let navigationElasticDrawer = Effect(
        id: "navigation.elastic-drawer",
        category: .navigation,
        interaction: .gesture,
        name: L("Elastic Edge Drawer", "弹性边缘抽屉"),
        summary: L(
            "Pull a drawer out by its edge: the edge bulges toward your finger like a membrane and wobbles flat on release.",
            "从边缘拉出抽屉：边缘像一层薄膜朝手指鼓起，松手后晃动着恢复平直。"
        ),
        prompt: L(
            "A phone frame with a vivid gradient drawer hidden off the left edge. Dragging from the left pulls it out, but its trailing edge is not straight: it bulges toward the finger in a smooth bell curve centred at the finger's height, up to ≈50 pt, stretching like a membrane (pushing it back in makes the bulge concave). On release the drawer snaps to 190 pt open or fully closed on an under-damped spring (damping ≈0.45), and the bulge collapses in the same spring so the edge overshoots and wobbles a couple of times before lying flat. The page behind dims to 30% black while open, and the menu items fade in as the drawer widens. Organic, tactile and a little jelly-like.",
            "手机画框中，一个鲜艳渐变色的抽屉藏在左侧边缘外。从左侧拖动即可拉出，但它的右边缘不是直线：边缘以手指所在高度为中心，鼓出一段平滑的钟形曲线，最多约 50pt，像被拉伸的薄膜（向回推时则凹进去）。松手后，抽屉以欠阻尼弹簧（阻尼约 0.45）吸附到 190pt 打开或完全收起，鼓包也在同一个弹簧中回收，边缘因此过冲、来回晃动两三下后才恢复平直。打开时背后页面蒙上 30% 的黑色，菜单项随抽屉变宽而淡入。有机、可触，带一点果冻感。"
        ),
        implementation: L(
            "A Shape whose width, bulge amount and bulge centre form one AnimatablePair drives the drawer; the drag sets width and a signed bulge proportional to the finger's lead, and release animates both back with one bouncy spring so the edge wobbles.",
            "抽屉是一个自定义 Shape，其宽度、鼓包量与鼓包中心组成一个 AnimatablePair；拖动时设置宽度与按手指领先量计算的有符号鼓包，松手后用同一个弹跳弹簧同时回收，使边缘产生晃动。"
        ),
        apis: ["Shape", "AnimatablePair", "addCurve(to:control1:control2:)", "DragGesture", "spring(response:dampingFraction:)"],
        tags: ["drawer", "elastic", "jelly", "side menu", "抽屉", "弹性", "果冻", "侧边菜单"],
        params: [
            .slider("damping", L("Wobble damping", "晃动阻尼"), 0.25...0.9, default: 0.45),
            .slider("bulge", L("Max bulge", "最大鼓包"), 20...80, default: 50, decimals: 0, unit: "pt"),
            .toggle("dim", L("Dim the page", "页面变暗"), default: true),
        ]
    ) { ctx in
        ElasticDrawerDemo(ctx: ctx)
    }
}

private let elasticDrawerItems: [(String, LocalizedText)] = [
    ("sparkles", L("For You", "推荐")),
    ("flame.fill", L("Trending", "热门")),
    ("bookmark.fill", L("Saved", "收藏")),
    ("gearshape.fill", L("Settings", "设置")),
]

private struct ElasticDrawerDemo: View {
    let ctx: DemoContext
    @State private var width: CGFloat = 0
    @State private var bulge: CGFloat = 0
    @State private var bulgeY: CGFloat = 160
    @State private var dragStart: CGFloat?

    private let openWidth: CGFloat = 190
    private let frameSize = CGSize(width: 250, height: 320)

    private var openness: CGFloat { min(max(width / openWidth, 0), 1) }

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                background
                Color.black
                    .opacity(ctx.bool("dim") ? 0.3 * Double(openness) : 0)
                    .allowsHitTesting(false)
                drawer
            }
            .frame(width: frameSize.width, height: frameSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            .contentShape(Rectangle())
            .pageSafeHorizontalDrag(onChanged: dragChanged, onEnded: dragEnded)
            DemoHint(text: L("Drag from the left edge", "从左边缘向右拖动"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.9) { simulatePull() }
    }

    private var background: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Discover", "发现"), ctx.language)
                .font(.title3.weight(.bold))
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.spectrum[index + 1].opacity(0.25))
                    .frame(height: 64)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .padding(.top, 10)
        .frame(width: frameSize.width, height: frameSize.height, alignment: .topLeading)
        .background(Palette.elevated)
    }

    private var drawer: some View {
        ZStack(alignment: .topLeading) {
            BulgeDrawerShape(width: width, bulge: bulge, bulgeY: bulgeY)
                .fill(LinearGradient(colors: [Palette.violet, Palette.indigo], startPoint: .top, endPoint: .bottom))
                .shadow(color: Palette.indigo.opacity(0.4), radius: 14, x: 4)
            VStack(alignment: .leading, spacing: 18) {
                ForEach(0..<elasticDrawerItems.count, id: \.self) { index in
                    HStack(spacing: 12) {
                        Image(systemName: elasticDrawerItems[index].0)
                            .frame(width: 20)
                        Text(elasticDrawerItems[index].1, ctx.language)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                }
            }
            .padding(.top, 44)
            .padding(.leading, 22)
            .opacity(Double(openness))
            .offset(x: (openness - 1) * 40)
        }
        .frame(width: frameSize.width, height: frameSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    private func dragChanged(_ value: DragGesture.Value) {
        let start = dragStart ?? width
        if dragStart == nil { dragStart = width }
        let raw: CGFloat = start + value.translation.width * 0.8
        let clamped: CGFloat = min(max(raw, 0), openWidth + 20)
        let lead: CGFloat = value.location.x - clamped
        let limit: CGFloat = ctx.cg("bulge")
        width = clamped
        bulge = min(max(lead * 0.5, -limit * 0.6), limit)
        bulgeY = min(max(value.location.y, 40), frameSize.height - 40)
    }

    /// Release projects the flick; a system cancellation (`nil`) settles from the current width and drops the bulge.
    private func dragEnded(_ value: DragGesture.Value?) {
        let start = dragStart ?? width
        dragStart = nil
        let projected: CGFloat = value.map { start + $0.predictedEndTranslation.width * 0.8 } ?? width
        settle(open: projected > openWidth / 2)
    }

    private func settle(open: Bool, buzz: Bool = true) {
        if buzz && !ctx.isPreview { Haptics.tap(open ? .medium : .light) }
        withAnimation(.spring(response: 0.55, dampingFraction: ctx["damping"])) {
            width = open ? openWidth : 0
            bulge = 0
        }
    }

    /// Preview: pull out with a bulge, then let go; or push it closed.
    private func simulatePull() {
        // Captured now: false inside the silent intro/autoplay, so the settle in the completion stays quiet too.
        let buzz: Bool = !Haptics.isMuted
        if width > openWidth / 2 {
            withAnimation(.easeOut(duration: 0.2)) {
                width = openWidth * 0.55
                bulge = -ctx.cg("bulge") * 0.5
                bulgeY = 200
            } completion: {
                settle(open: false, buzz: buzz)
            }
        } else {
            withAnimation(.easeOut(duration: 0.28)) {
                width = openWidth * 0.6
                bulge = ctx.cg("bulge")
                bulgeY = 130
            } completion: {
                settle(open: true, buzz: buzz)
            }
        }
    }
}

private struct BulgeDrawerShape: Shape {
    var width: CGFloat
    var bulge: CGFloat
    var bulgeY: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(width, AnimatablePair(bulge, bulgeY)) }
        set {
            width = newValue.first
            bulge = newValue.second.first
            bulgeY = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let edge: CGFloat = rect.minX + max(width, 0)
        let spread: CGFloat = 110
        let top: CGFloat = bulgeY - spread
        let bottom: CGFloat = bulgeY + spread
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: edge, y: rect.minY))
        path.addLine(to: CGPoint(x: edge, y: top))
        path.addCurve(
            to: CGPoint(x: edge + bulge, y: bulgeY),
            control1: CGPoint(x: edge, y: top + spread * 0.45),
            control2: CGPoint(x: edge + bulge, y: bulgeY - spread * 0.4)
        )
        path.addCurve(
            to: CGPoint(x: edge, y: bottom),
            control1: CGPoint(x: edge + bulge, y: bulgeY + spread * 0.4),
            control2: CGPoint(x: edge, y: bottom - spread * 0.45)
        )
        path.addLine(to: CGPoint(x: edge, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
