import SwiftUI

extension Effect {
    static let showcaseSpotsGrid = Effect(
        id: "showcase.spots-grid",
        category: .showcase,
        interaction: .tap,
        name: L("Spots Grid Expand", "地点网格展开"),
        summary: L("Tap a photo tile and it grows into a detail card while the grid recedes behind it.", "点击照片方块，它会生长为详情卡片，其余网格退后虚化。"),
        prompt: L(
            "A dark \"Spots\" widget holds a 3×2 grid of rounded landscape thumbnails. Tapping a tile lifts that exact photo out of the grid and morphs its position and size into the hero image of a 290 pt detail card (matched geometry, spring ≈0.5 s response, damping 0.82); simultaneously the grid scales back to 90%, blurs by 6 pt and fades to ~30%, while the card's surface fades and scales up from 94% and the stats row and an orange \"Navigate\" pill rise 14 pt into place with a 120 ms delay. The spot's name is printed on the photo itself, so it travels with the image from the tile's corner to the hero's corner, cross-fading from a 9 pt caption to a 22 pt title. Tapping the card reverses everything and the photo flies back into its slot. A light haptic marks each open. Spatial, continuous and easy to follow.",
            "深色“地点”小组件里是 3×2 圆角风景缩略图。点击某格，这张照片浮起，位置与尺寸连续形变为 290pt 详情卡片的头图（共享几何，弹簧响应约 0.5 秒、阻尼 0.82）；网格同时缩到 90%、模糊 6pt、淡到约 30%，卡片底面从 94% 放大淡入，数据行与橙色“导航”按钮延迟 120 毫秒上移 14pt 就位。地点名印在照片上，随之从格子角落飞到头图角落，由 9pt 小字渐变为 22pt 标题。再点卡片则倒放，照片飞回原位；每次展开轻触一下。空间连贯。"
        ),
        implementation: L(
            "The tile and the detail hero share a matchedGeometryEffect id and are swapped by a single spring-animated selection; the detail container stays mounted so its backdrop and text animate with plain opacity/scale/offset.",
            "网格方块与详情头图共享 matchedGeometryEffect 的 id，由一次弹簧动画的选中状态切换；详情容器常驻，其底面与文字用普通的透明度、缩放与位移动画。"
        ),
        apis: ["matchedGeometryEffect", "@Namespace", "spring(response:dampingFraction:)", "blur(radius:)", "scaleEffect"],
        tags: ["hero", "expand", "photo grid", "matched geometry", "英雄动画", "展开", "照片网格", "共享元素"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.82),
            .slider("dim", L("Background dim", "背景淡化"), 0...0.9, default: 0.7),
        ]
    ) { ctx in
        SportSpotsDemo(ctx: ctx)
    }
}

private struct SpotInfo {
    let name: String
    let seed: Int
    let altitude: String
    let runs: Int
    let rating: String
}

private let sportSpots: [SpotInfo] = [
    SpotInfo(name: "Nordkette", seed: 0, altitude: "2,256 m", runs: 18, rating: "4.9"),
    SpotInfo(name: "Seegrube", seed: 2, altitude: "1,905 m", runs: 9, rating: "4.7"),
    SpotInfo(name: "Stubai", seed: 4, altitude: "3,210 m", runs: 26, rating: "4.8"),
    SpotInfo(name: "Axamer", seed: 1, altitude: "2,340 m", runs: 14, rating: "4.6"),
    SpotInfo(name: "Kühtai", seed: 3, altitude: "2,520 m", runs: 12, rating: "4.5"),
    SpotInfo(name: "Hafelekar", seed: 5, altitude: "2,334 m", runs: 7, rating: "4.8"),
]

private struct SportSpotsDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var selected: Int?
    @State private var shown = 0
    @State private var nextAuto = 0
    /// Detail intro: opens a spot, then closes it so the grid isn't left dimmed.
    @State private var introTask: Task<Void, Never>?

    private var isOpen: Bool { selected != nil }

    var body: some View {
        SignatureStage {
            ZStack {
                grid
                    .scaleEffect(isOpen ? 0.9 : 1)
                    .opacity(isOpen ? 1 - ctx["dim"] : 1)
                    .blur(radius: isOpen ? 6 : 0)
                    .allowsHitTesting(!isOpen)
                detail
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                DemoHint(text: L("Tap a photo; tap the card to close", "点击照片展开，点击卡片收起"), ctx: ctx)
                    .padding(.bottom, 14)
                    .allowsHitTesting(false)
            }
        }
        .autoplay(ctx.isPreview, every: 1.9, delay: 0.8) {
            if ctx.isPreview { autoStep() } else { playIntro() }
        }
        .onDisappear { cancelIntro() }
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("Spots", "雪场"), ctx.language)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Spacer(minLength: 0)
                Text(L("6 saved", "已收藏 6 个"), ctx.language)
                    .signatureEyebrow()
            }
            VStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { column in
                            tile(row * 3 + column)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 300)
        .signatureCard()
    }

    private func tile(_ index: Int) -> some View {
        ZStack {
            Color.clear
            if selected != index {
                SpotPhoto(seed: sportSpots[index].seed, name: sportSpots[index].name, large: false)
                    .matchedGeometryEffect(id: index, in: ns)
            }
        }
        .frame(width: 84, height: 84)
        .contentShape(Rectangle())
        .onTapGesture {
            cancelIntro()
            select(index)
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Color.clear
                if let index = selected {
                    SpotPhoto(seed: sportSpots[index].seed, name: sportSpots[index].name, large: true)
                        .matchedGeometryEffect(id: index, in: ns)
                }
            }
            .frame(height: 170)
            SpotDetailInfo(spot: sportSpots[shown], language: ctx.language)
                .opacity(isOpen ? 1 : 0)
                .offset(y: isOpen ? 0 : 14)
                .animation(.easeOut(duration: 0.3).delay(isOpen ? 0.12 : 0), value: isOpen)
        }
        .padding(10)
        .frame(width: 290)
        .background {
            Color.clear
                .signatureCard(cornerRadius: 28)
                .opacity(isOpen ? 1 : 0)
                .scaleEffect(isOpen ? 1 : 0.94)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            cancelIntro()
            select(nil)
        }
        .allowsHitTesting(isOpen)
    }

    private func select(_ index: Int?, silent: Bool = false) {
        if let index { shown = index }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { selected = index }
        if !silent && !ctx.isPreview { Haptics.tap(index == nil ? .soft : .light) }
    }

    /// Detail intro: open one spot, hold so the details can be read, then fly it back into the grid.
    private func playIntro() {
        cancelIntro()
        select(1, silent: true)
        introTask = Task {
            try? await Task.sleep(for: .seconds(2.0))
            guard !Task.isCancelled else { return }
            if selected != nil { select(nil, silent: true) }
            introTask = nil
        }
    }

    private func cancelIntro() {
        introTask?.cancel()
        introTask = nil
    }

    private func autoStep() {
        if selected == nil {
            select(nextAuto)
            nextAuto = (nextAuto + 1) % sportSpots.count
        } else {
            select(nil)
        }
    }
}

/// The photo carries its own name label, so the label rides the matched-geometry flight
/// (cross-fading from caption size to title size) instead of popping in and out.
private struct SpotPhoto: View {
    let seed: Int
    let name: String
    let large: Bool

    var body: some View {
        LandscapeArt(seed: seed)
            .overlay(
                LinearGradient(colors: [.clear, Color.black.opacity(large ? 0.55 : 0.35)], startPoint: .center, endPoint: .bottom)
            )
            .overlay(alignment: .bottomLeading) {
                Text(name)
                    .font(.system(size: large ? 22 : 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.6), radius: 3)
                    .padding(large ? 14 : 7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.white.opacity(0.12)))
    }
}

private struct SpotDetailInfo: View {
    let spot: SpotInfo
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("Tirol · Austria", "奥地利 · 蒂罗尔"), language)
                    .signatureEyebrow()
                Spacer(minLength: 0)
                Label(spot.rating, systemImage: "star.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Signature.accent)
            }
            HStack(spacing: 10) {
                Text(spot.altitude)
                Text(verbatim: "·")
                Text("\(spot.runs) " + L("runs", "条雪道")(language))
                Spacer(minLength: 0)
                Text(L("Navigate", "导航"), language)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Signature.accentGradient))
            }
            .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(Signature.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }
}
