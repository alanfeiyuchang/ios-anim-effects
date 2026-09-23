import SwiftUI

extension Effect {
    static let showcaseSpotsGrid = Effect(
        id: "showcase.spots-grid",
        category: .showcase,
        interaction: .tap,
        name: L("Spots Grid Expand", "地点网格展开"),
        summary: L("Tap a photo tile and it grows into a detail card while the grid recedes behind it.", "点击照片方块，它会生长为详情卡片，其余网格退后虚化。"),
        prompt: L(
            "A dark \"Spots\" widget holds a 3×2 grid of rounded landscape thumbnails. Tapping a tile lifts that exact photo out of the grid and morphs its position and size into the hero image of a 290 pt detail card (matched geometry, spring ≈0.5 s response, damping 0.82); simultaneously the grid scales back to 90%, blurs by 6 pt and fades to ~30%, while the card's surface fades and scales up from 94% and the title, stats and an orange \"Navigate\" pill rise 14 pt into place with a 120 ms delay. Tapping the card reverses everything and the photo flies back into its slot. A light haptic marks each open. Spatial, continuous and easy to follow.",
            "深色“地点”小组件里是 3×2 的圆角风景缩略图网格。点击某个方块，这张照片会从网格中“浮起”，其位置与尺寸连续形变为 290pt 详情卡片的头图（matchedGeometryEffect，弹簧响应约 0.5 秒、阻尼 0.82）；与此同时网格缩小到 90%、模糊 6pt 并淡到约 30%，卡片底面从 94% 放大淡入，标题、数据和橙色“导航”胶囊按钮延迟 120 毫秒上移 14pt 就位。再次点击卡片，一切倒放，照片飞回原位。每次展开伴随轻触感。空间关系清晰、过渡连贯、易于理解。"
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
        }
        .autoplay(ctx.isPreview, every: 1.9, delay: 0.8) { autoStep() }
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
                SpotPhoto(seed: sportSpots[index].seed)
                    .matchedGeometryEffect(id: index, in: ns)
                    .overlay(alignment: .bottomLeading) {
                        Text(sportSpots[index].name)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: .black.opacity(0.6), radius: 3)
                            .padding(7)
                    }
            }
        }
        .frame(width: 84, height: 84)
        .contentShape(Rectangle())
        .onTapGesture { select(index) }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Color.clear
                if let index = selected {
                    SpotPhoto(seed: sportSpots[index].seed)
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
        .onTapGesture { select(nil) }
        .allowsHitTesting(isOpen)
    }

    private func select(_ index: Int?) {
        if let index { shown = index }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) { selected = index }
        if !ctx.isPreview { Haptics.tap(index == nil ? .soft : .light) }
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

private struct SpotPhoto: View {
    let seed: Int

    var body: some View {
        LandscapeArt(seed: seed)
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
                Text(spot.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
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
