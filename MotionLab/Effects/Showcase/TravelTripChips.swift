import SwiftUI

extension Effect {
    static let showcaseTripChips = Effect(
        id: "showcase.trip-chips",
        category: .showcase,
        interaction: .tap,
        name: L("Trip Filter Chips", "行程筛选标签"),
        summary: L(
            "A lime selection pill glides between filter chips while destination tiles reflow with a staggered spring.",
            "青柠色选中胶囊在筛选标签间滑动，目的地卡片以错峰弹簧重新排布。"
        ),
        prompt: L(
            "A dark “Plan Trips With Ease” card holds a segmented row of filter chips (All · Trails · Nights · Lakes) on a 6% white track, above a 3-column grid of photo tiles. Tapping a chip slides a single lime capsule (with a faint lime glow) behind the new label via shared geometry on a spring (response 0.42 s, damping 0.78); the label flips from muted white to black. Tiles that no longer match shrink out within 150 ms, surviving tiles glide to their new grid slots, and incoming tiles scale up from 60% with opacity, each delayed 45 ms after the previous. The count label rolls with a numeric content transition. A selection haptic marks each change. It feels fluid, organized and effortless.",
            "暗色「轻松规划旅程」卡片上方是一排分段筛选标签（全部 · 步道 · 夜景 · 湖泊），底轨为 6% 白色，下面是三列照片卡片网格。点击标签后，唯一一枚青柠色胶囊（带淡淡的青柠辉光）通过共享几何以弹簧（响应 0.42 秒、阻尼 0.78）滑到新标签背后，文字由浅灰白变成黑色。不再符合条件的卡片在 150 毫秒内缩小消失，保留的卡片平滑滑到新格位，新卡片从 60% 缩放加淡入出现，每张比上一张晚 45 毫秒。计数文字用数字滚动过渡更新。每次切换都有一下选择触感。整体流畅、有条理，操作毫不费力。"
        ),
        implementation: L(
            "The pill is one Capsule with matchedGeometryEffect rendered behind whichever chip is selected; tiles are filtered inside a LazyVGrid and use an asymmetric AnyTransition with .animation(spring.delay(index × stagger)).",
            "选中胶囊是一枚使用 matchedGeometryEffect 的 Capsule，只绘制在当前选中标签背后；卡片在 LazyVGrid 中过滤，并使用非对称 AnyTransition 搭配 .animation(spring.delay(序号 × 错峰))。"
        ),
        apis: ["matchedGeometryEffect", "LazyVGrid", "AnyTransition.animation", "contentTransition(.numericText)", "spring(response:dampingFraction:)"],
        tags: ["chips", "filter", "segmented", "stagger", "筛选", "标签", "分段控件", "错峰"],
        params: [
            .slider("stagger", L("Tile stagger", "卡片错峰"), 0...0.12, default: 0.045, decimals: 3, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1, default: 0.78),
        ]
    ) { ctx in
        TravelTripChipsDemo(ctx: ctx)
    }
}

// MARK: - Model

private enum TravelTripKind: Int, CaseIterable {
    case all, trails, nights, lakes

    var title: LocalizedText {
        switch self {
        case .all: return L("All", "全部")
        case .trails: return L("Trails", "步道")
        case .nights: return L("Nights", "夜景")
        case .lakes: return L("Lakes", "湖泊")
        }
    }

    var symbol: String {
        switch self {
        case .all: return "globe.europe.africa.fill"
        case .trails: return "figure.hiking"
        case .nights: return "moon.stars.fill"
        case .lakes: return "water.waves"
        }
    }
}

private struct TravelTripSpot: Identifiable {
    let id: String
    let name: LocalizedText
    let meta: LocalizedText
    let kind: TravelTripKind
    let seed: Int

    static let all: [TravelTripSpot] = [
        TravelTripSpot(id: "nordkette", name: L("Nordkette", "北链山"), meta: L("12 km · 5h", "12 公里 · 5 小时"), kind: .trails, seed: 0),
        TravelTripSpot(id: "azure", name: L("Azure Coast", "蔚蓝海岸"), meta: L("Sunset cruise", "日落航线"), kind: .nights, seed: 1),
        TravelTripSpot(id: "braies", name: L("Lago di Braies", "布拉耶斯湖"), meta: L("Rowboats", "湖上划船"), kind: .lakes, seed: 2),
        TravelTripSpot(id: "canyon", name: L("Red Canyon", "红岩峡谷"), meta: L("8 km · 3h", "8 公里 · 3 小时"), kind: .trails, seed: 3),
        TravelTripSpot(id: "aurora", name: L("Aurora Camp", "极光营地"), meta: L("Stargazing", "观星露营"), kind: .nights, seed: 4),
        TravelTripSpot(id: "glacier", name: L("Glacier Bay", "冰川湾"), meta: L("Kayak · 2 days", "皮划艇 · 2 天"), kind: .lakes, seed: 7),
    ]
}

// MARK: - Demo

private struct TravelTripChipsDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var selected: TravelTripKind = .all

    private var zh: Bool { ctx.language == .zh }
    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }
    private var visible: [TravelTripSpot] {
        selected == .all ? TravelTripSpot.all : TravelTripSpot.all.filter { $0.kind == selected }
    }

    var body: some View {
        SignatureStage {
            VStack(alignment: .leading, spacing: 14) {
                header
                chips
                grid
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(width: 310, height: 318, alignment: .top)
            .signatureCard()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.7) {
            select(TravelTripKind(rawValue: (selected.rawValue + 1) % TravelTripKind.allCases.count) ?? .all)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Text(zh ? "轻松规划" : "Plan Trips With")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(zh ? "旅程" : "Ease")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Signature.lime, in: Capsule())
            }
            Spacer(minLength: 0)
            Text(zh ? "\(visible.count) 处" : "\(visible.count) spots")
                .font(Signature.number(13))
                .foregroundStyle(Signature.textSecondary)
                .contentTransition(.numericText(value: Double(visible.count)))
        }
    }

    private var chips: some View {
        HStack(spacing: 4) {
            ForEach(TravelTripKind.allCases, id: \.self) { kind in
                TravelTripChip(title: kind.title(ctx.language), isSelected: kind == selected, ns: ns) {
                    select(kind)
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, spot in
                TravelTripTile(spot: spot, language: ctx.language)
                    .transition(tileTransition(index))
            }
        }
    }

    private func tileTransition(_ index: Int) -> AnyTransition {
        .asymmetric(
            insertion: AnyTransition.scale(scale: 0.6)
                .combined(with: .opacity)
                .animation(spring.delay(Double(index) * ctx["stagger"])),
            removal: AnyTransition.scale(scale: 0.8)
                .combined(with: .opacity)
                .animation(.easeOut(duration: 0.15))
        )
    }

    private func select(_ kind: TravelTripKind) {
        guard kind != selected else { return }
        if !ctx.isPreview { Haptics.selection() }
        withAnimation(spring) { selected = kind }
    }
}

// MARK: - Pieces

private struct TravelTripChip: View {
    let title: String
    let isSelected: Bool
    let ns: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.black : Signature.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Signature.lime)
                            .shadow(color: Signature.lime.opacity(0.35), radius: 8, y: 2)
                            .matchedGeometryEffect(id: "pill", in: ns)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct TravelTripTile: View {
    let spot: TravelTripSpot
    let language: AppLanguage

    var body: some View {
        LandscapeArt(seed: spot.seed)
            .frame(height: 92)
            .overlay(
                LinearGradient(colors: [.clear, Color.black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: spot.kind.symbol)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 20, height: 20)
                    .background(Color.black.opacity(0.3), in: Circle())
                    .padding(6)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(spot.name(language))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text(spot.meta(language))
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .lineLimit(1)
                .padding(7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Signature.hairline)
            )
    }
}
