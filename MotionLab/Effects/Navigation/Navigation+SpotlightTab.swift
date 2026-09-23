import SwiftUI

extension Effect {
    static let navigationSpotlightTab = Effect(
        id: "navigation.spotlight-tab",
        category: .navigation,
        interaction: .tap,
        name: L("Spotlight Tabs", "聚光灯标签"),
        summary: L(
            "A ceiling lamp swings its beam onto the chosen tab like a pendulum, and a pool of light slides across the floor.",
            "顶部灯具像钟摆一样把光束甩向选中的标签，地面的光斑随之滑过。"
        ),
        prompt: L(
            "A 300 × 210 pt dark stage with a small lamp fixture hanging at top-centre and four tab labels along the floor (Live, Music, Talks, Kids). The selection is a soft cone of warm light from the lamp to the chosen label. Choosing another tab swings the cone around the lamp's pivot on an under-damped spring (response ≈0.6 s, damping ≈0.45), so it overshoots, sways back and settles like a pendulum; an elliptical floor pool follows on a slower, well-damped spring and widens slightly as it lands. The lit label brightens to white with a warm glow while the others dim to 40%. A soft haptic accompanies the swing. Theatrical, warm and physical.",
            "一个 300 × 210pt 的暗色舞台：顶部正中悬挂一盏小灯，地面排列四个标签（直播、音乐、讲座、少儿）。选中态是一束从灯具射向所选标签的暖色锥形光。切换标签时，光束绕灯具支点以欠阻尼弹簧（响应约 0.6 秒、阻尼约 0.45）摆动，先冲过头、再荡回并停稳，像一只钟摆；地面上的椭圆光斑以更慢、阻尼更高的弹簧跟随，落位时略微展宽。被照亮的标签变为白色并带暖色辉光，其余标签降到 40% 亮度。摆动时伴随柔和触觉。戏剧化、温暖、富有物理感。"
        ),
        implementation: L(
            "The beam is a trapezoid Shape rotated with rotationEffect(anchor: .top) by the angle from the pivot to the tab centre (atan2), animated with a low-damping spring; the floor pool is a blurred RadialGradient ellipse offset on its own spring.",
            "光束是一个梯形 Shape，用 rotationEffect(anchor: .top) 旋转到支点指向标签中心的角度（atan2），以低阻尼弹簧驱动；地面光斑是一个模糊的 RadialGradient 椭圆，用独立弹簧偏移。"
        ),
        apis: ["Shape", "rotationEffect(_:anchor:)", "atan2", "spring(response:dampingFraction:)", "RadialGradient"],
        tags: ["spotlight", "pendulum", "tabs", "light", "聚光灯", "钟摆", "标签页", "光束"],
        params: [
            .slider("damping", L("Swing damping", "摆动阻尼"), 0.25...0.95, default: 0.45),
            .slider("response", L("Swing response", "摆动响应"), 0.3...1.2, default: 0.6, unit: "s"),
            .slider("beam", L("Beam width", "光束宽度"), 30...100, default: 60, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        SpotlightTabDemo(ctx: ctx)
    }
}

private let spotlightTabs: [LocalizedText] = [L("Live", "直播"), L("Music", "音乐"), L("Talks", "讲座"), L("Kids", "少儿")]

private struct SpotlightTabDemo: View {
    let ctx: DemoContext
    @State private var selected = 1

    private let stageWidth: CGFloat = 300
    private let stageHeight: CGFloat = 210
    private let pivotY: CGFloat = 26
    private let floorY: CGFloat = 176
    private let warm = Color(hex: 0xFFE3A3)

    var body: some View {
        VStack(spacing: 16) {
            stage
            DemoHint(text: L("Tap a label", "点击任一标签"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) {
            let next: Int = selected == 0 ? 3 : (selected == 3 ? 1 : (selected == 1 ? 2 : 0))
            select(next)
        }
    }

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x1B1A2E), Color(hex: 0x0D0C17)], startPoint: .top, endPoint: .bottom))
            floorPool
            beam
            fixture
            labels
        }
        .frame(width: stageWidth, height: stageHeight)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
    }

    private func tabX(_ index: Int) -> CGFloat {
        let slot: CGFloat = stageWidth / CGFloat(spotlightTabs.count)
        return (CGFloat(index) + 0.5) * slot
    }

    private var beamAngle: Angle {
        let dx: Double = Double(tabX(selected) - stageWidth / 2)
        let dy: Double = Double(floorY - pivotY)
        return .radians(-atan2(dx, dy))
    }

    private var swing: Animation {
        .spring(response: ctx["response"], dampingFraction: ctx["damping"])
    }

    private var beam: some View {
        let length: CGFloat = 200
        return BeamCone(topWidth: 12, bottomWidth: ctx.cg("beam"))
            .fill(LinearGradient(colors: [warm.opacity(0.75), warm.opacity(0.05)], startPoint: .top, endPoint: .bottom))
            .frame(width: 120, height: length)
            .blur(radius: 3)
            .blendMode(.screen)
            .rotationEffect(beamAngle, anchor: .top)
            .offset(x: stageWidth / 2 - 60, y: pivotY)
            .animation(swing, value: selected)
    }

    private var floorPool: some View {
        Ellipse()
            .fill(RadialGradient(colors: [warm.opacity(0.55), warm.opacity(0)], center: .center, startRadius: 0, endRadius: 60))
            .frame(width: 120, height: 34)
            .blur(radius: 4)
            .offset(x: tabX(selected) - 60, y: floorY - 17)
            .animation(.spring(response: ctx["response"] * 1.3, dampingFraction: 0.85), value: selected)
    }

    private var fixture: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 2, height: 14)
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0x5A5870), Color(hex: 0x2E2C3E)], startPoint: .top, endPoint: .bottom))
                .frame(width: 30, height: 14)
                .overlay(alignment: .bottom) {
                    Capsule().fill(warm).frame(width: 16, height: 3)
                }
        }
        .offset(x: stageWidth / 2 - 15, y: pivotY - 26)
    }

    private var labels: some View {
        HStack(spacing: 0) {
            ForEach(0..<spotlightTabs.count, id: \.self) { index in
                let lit = index == selected
                Text(spotlightTabs[index], ctx.language)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(lit ? Color.white : Color.white.opacity(0.4))
                    .shadow(color: warm.opacity(lit ? 0.9 : 0), radius: 8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture { select(index) }
                    .animation(.easeInOut(duration: 0.3).delay(lit ? 0.12 : 0), value: selected)
            }
        }
        .frame(width: stageWidth)
        .offset(y: floorY - 34)
    }

    private func select(_ index: Int) {
        guard index != selected else { return }
        if !ctx.isPreview { Haptics.tap(.soft) }
        selected = index
    }
}

/// A trapezoid pointing down from its top edge's centre.
private struct BeamCone: Shape {
    let topWidth: CGFloat
    let bottomWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - topWidth / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + topWidth / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + bottomWidth / 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - bottomWidth / 2, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
