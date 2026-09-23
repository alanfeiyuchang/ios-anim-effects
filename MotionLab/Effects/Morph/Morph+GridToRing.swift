import SwiftUI

extension Effect {
    static let morphGridToRing = Effect(
        id: "morph.grid-to-ring",
        category: .morph,
        interaction: .tap,
        name: L("Grid to Ring", "网格变环形"),
        summary: L(
            "Twelve app tiles leave their grid one by one and swing into a circle, turning to face outward.",
            "十二个应用图块依次离开网格，旋入一个圆环，并转向朝外。"
        ),
        prompt: L(
            "Twelve 48 pt gradient app tiles sit in a 4 × 3 grid on 64 pt centres. A tap sends them into a 110 pt-radius ring, one after another in reading order, ≈30 ms apart, each on its own spring (response ≈0.55 s, damping 0.72) so the ring assembles like a clock being dealt. While travelling, every tile rotates to point away from the centre, and a count label (\"12 apps\") scales up from 60% in the middle once the last tile lands. Tapping again returns them to the grid in reverse order, un-rotating as they settle. The motion is choreographed, orbital and ceremonial rather than a simple reflow.",
            "十二枚 48pt 的渐变应用图块以 64pt 间距排成 4 × 3 网格。点击后，它们按阅读顺序依次（间隔约 30 毫秒）飞入半径 110pt 的圆环，每枚各自使用弹簧（响应约 0.55 秒、阻尼 0.72），圆环像被一张张发牌般拼成一只表盘。飞行过程中每枚图块转向背离圆心的方向；最后一枚落位后，中央的计数标签（「12 个应用」）从 60% 放大出现。再次点击，图块按相反顺序回到网格，同时转回正向。编排感强、带有轨道感与仪式感，而不是简单的重排。"
        ),
        implementation: L(
            "Each tile's grid and ring positions are computed from its index; the tile is placed with offset and rotationEffect, and animation(_:value:) with a per-index delay (reversed on the way back) produces the cascade.",
            "每枚图块根据序号计算网格位置与圆环位置，用 offset 与 rotationEffect 摆放；animation(_:value:) 按序号设置延迟（返回时顺序反转），形成依次接力。"
        ),
        apis: ["offset(x:y:)", "rotationEffect", "animation(_:value:)", "spring(response:dampingFraction:)", "delay(_:)"],
        tags: ["layout", "ring", "grid", "stagger", "布局", "环形", "网格", "错峰"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.55, unit: "s"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0.0...0.08, default: 0.03, decimals: 3, unit: "s"),
            .toggle("orient", L("Face outward", "朝外转向"), default: true),
        ]
    ) { ctx in
        GridToRingDemo(ctx: ctx)
    }
}

private let ringSymbols: [String] = [
    "message.fill", "phone.fill", "camera.fill", "music.note", "map.fill", "calendar",
    "cloud.sun.fill", "gamecontroller.fill", "book.fill", "cart.fill", "heart.fill", "gearshape.fill",
]

private struct GridToRingDemo: View {
    let ctx: DemoContext
    @State private var ring = false

    private let count = 12

    var body: some View {
        ZStack {
            centerLabel
            ForEach(0..<count, id: \.self) { index in
                tile(index)
            }
        }
        .frame(width: 300, height: 300)
        .contentShape(Rectangle())
        .onTapGesture { toggle() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Tap to rearrange", "点击重新排列"), ctx: ctx)
                .padding(.bottom, 12)
        }
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    private var centerLabel: some View {
        let reveal: Animation = ring
            ? .spring(response: 0.45, dampingFraction: 0.7).delay(ctx["stagger"] * Double(count))
            : .easeOut(duration: 0.15)
        return VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
            Text(L("apps", "个应用"), ctx.language)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .scaleEffect(ring ? 1 : 0.6)
        .opacity(ring ? 1 : 0)
        .animation(reveal, value: ring)
    }

    private func tile(_ index: Int) -> some View {
        let position = ring ? ringPoint(index) : gridPoint(index)
        let outward: Double = ringAngle(index) + 90
        // Turn the short way round (e.g. −30° rather than 330°).
        let shortest: Double = outward > 180 ? outward - 360 : outward
        let angle: Double = ring && ctx.bool("orient") ? shortest : 0
        let order: Int = ring ? index : count - 1 - index
        let delay: Double = Double(order) * ctx["stagger"]
        let color = Palette.spectrum[index % Palette.spectrum.count]
        return Image(systemName: ringSymbols[index])
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .shadow(color: color.opacity(0.35), radius: 6, y: 3)
            .rotationEffect(.degrees(angle))
            .offset(x: position.x, y: position.y)
            .animation(.spring(response: ctx["response"], dampingFraction: 0.72).delay(delay), value: ring)
    }

    private func gridPoint(_ index: Int) -> CGPoint {
        let column = CGFloat(index % 4)
        let row = CGFloat(index / 4)
        return CGPoint(x: (column - 1.5) * 64, y: (row - 1) * 64)
    }

    private func ringAngle(_ index: Int) -> Double {
        Double(index) / Double(count) * 360 - 90
    }

    private func ringPoint(_ index: Int) -> CGPoint {
        let radians: Double = ringAngle(index) * Double.pi / 180
        return CGPoint(x: CGFloat(cos(radians)) * 110, y: CGFloat(sin(radians)) * 110)
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        ring.toggle()
    }
}
