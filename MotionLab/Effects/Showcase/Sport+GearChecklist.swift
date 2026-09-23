import SwiftUI

extension Effect {
    static let showcaseGearChecklist = Effect(
        id: "showcase.gear-checklist",
        category: .showcase,
        interaction: .tap,
        name: L("Gear Checklist", "装备清单"),
        summary: L("Tick off your kit: checks draw themselves, packed items sink and the ring fills to lime.", "逐项勾选装备：对勾自行描绘，已打包项下沉，进度环最终变为青柠色。"),
        prompt: L(
            "A dark SUMMIT KIT checklist card: a title, a progress ring with a rolling \"2/5\" count, and five gear rows (glyph tile, name, detail, round check). Tapping a row presses it to 97%; its check circle fills with the orange gradient from 20% on a bouncy spring (response 0.35 s, damping 0.6) while a dark checkmark draws itself 80 ms later, the name dims to 45% and gains a strike-through, and ~300 ms later — once the check has landed — the row slides to the bottom of the list as the others close the gap (spring, response 0.5 s). The ring's orange arc sweeps to the new fraction with a soft glow. When the last item is packed, the ring turns lime, its count swaps for a checkmark, it swells 8%, the title changes to \"All packed\" and a success haptic fires. Orderly, satisfying and motivating.",
            "深色“登顶装备”清单卡片：标题、带滚动计数（“2/5”）的进度环，以及五行装备（图标小方块、名称、说明、圆形勾选框）。点击某一行，整行轻压到 97%；勾选圆以弹性弹簧（响应 0.35 秒、阻尼 0.6）从 20% 放大并填满橙色渐变，深色对勾在 80 毫秒后自行描绘出来，名称降到 45% 透明度并加上删除线，约 300 毫秒后（对勾落定之后）这一行才滑到列表底部，其余行顺势补位（弹簧，响应 0.5 秒）。进度环的橙色弧线带着柔光扫到新的比例。最后一项打包完成时，进度环变为青柠色，计数替换为对勾并放大 8%，标题变为“装备齐全”，同时触发成功触觉。井然有序、满足感十足，也很激励人。"
        ),
        implementation: L(
            "A Set of checked ids drives the check, ring and title at once; a second Set, copied from it ~300 ms later in its own spring withAnimation, decides the order of the id-keyed ForEach so packed items sink only after the check lands; the check is a trimmed custom Shape with its own delayed animation, and the ring is a trimmed Circle.",
            "已勾选 id 的 Set 立即驱动对勾、进度环与标题；约 300 毫秒后再把它复制到第二个 Set，并在独立的弹簧 withAnimation 中决定以 id 为标识的 ForEach 排序，让已打包项在对勾落定后才下沉；对勾是带独立延迟动画的 trim 自定义 Shape，进度环是 trim 后的 Circle。"
        ),
        apis: ["ForEach(id:)", "Shape.trim(from:to:)", "strikethrough(_:color:)", "contentTransition(.numericText(value:))", "spring(response:dampingFraction:)"],
        tags: ["checklist", "todo", "progress ring", "packing", "清单", "待办", "进度环", "打包"],
        params: [
            .slider("response", L("Reorder spring", "排序弹簧响应"), 0.2...0.9, default: 0.5, unit: "s"),
            .toggle("sort", L("Sink packed items", "已打包项下沉"), default: true),
            .toggle("strike", L("Strike-through", "删除线"), default: true),
        ]
    ) { ctx in
        SportGearDemo(ctx: ctx)
    }
}

private struct GearItem: Identifiable {
    let id: Int
    let symbol: String
    let name: LocalizedText
    let detail: LocalizedText
}

private struct SportGearDemo: View {
    let ctx: DemoContext
    @State private var checked: Set<Int> = [1]
    /// Lags `checked` by ~300 ms so a row is ticked first and reordered afterwards.
    @State private var sunk: Set<Int> = [1]
    @State private var reorderTask: Task<Void, Never>?

    private static let items: [GearItem] = [
        GearItem(id: 0, symbol: "shield.lefthalf.filled", name: L("Helmet", "头盔"), detail: L("Size M · MIPS", "M 码 · MIPS")),
        GearItem(id: 1, symbol: "eyeglasses", name: L("Goggles", "雪镜"), detail: L("Low-light lens", "弱光镜片")),
        GearItem(id: 2, symbol: "hand.raised.fill", name: L("Gloves", "手套"), detail: L("Gore-Tex shell", "Gore-Tex 外层")),
        GearItem(id: 3, symbol: "antenna.radiowaves.left.and.right", name: L("Avalanche beacon", "雪崩信标"), detail: L("Battery 92%", "电量 92%")),
        GearItem(id: 4, symbol: "cup.and.saucer.fill", name: L("Thermos", "保温壶"), detail: L("Hot ginger tea", "热姜茶")),
    ]

    private var orderedItems: [GearItem] {
        guard ctx.bool("sort") else { return Self.items }
        return Self.items.filter { !sunk.contains($0.id) } + Self.items.filter { sunk.contains($0.id) }
    }

    private var allPacked: Bool { checked.count == Self.items.count }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap items to pack them", "点击物品即可打包"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.1, delay: 0.6) { previewTick() }
    }

    private var card: some View {
        VStack(spacing: 10) {
            header
            VStack(spacing: 2) {
                ForEach(orderedItems) { item in
                    row(item)
                }
            }
        }
        .padding(14)
        .frame(width: 292)
        .signatureCard()
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                SportEyebrowRow(title: L("Summit kit", "登顶装备")(ctx.language), symbol: "backpack.fill")
                Text(allPacked ? L("All packed", "装备齐全") : L("Pack your gear", "整理装备"), ctx.language)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
            GearRing(count: checked.count, total: Self.items.count, response: ctx["response"])
        }
        .padding(.horizontal, 4)
    }

    private func row(_ item: GearItem) -> some View {
        let isChecked = checked.contains(item.id)
        return Button {
            toggle(item.id)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: item.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isChecked ? Signature.accent : Color.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(isChecked ? 0.04 : 0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name, ctx.language)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .strikethrough(ctx.bool("strike") && isChecked, color: Color.white.opacity(0.45))
                        .foregroundStyle(Color.white.opacity(isChecked ? 0.45 : 1))
                    Text(item.detail, ctx.language)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Signature.textSecondary)
                }
                Spacer(minLength: 0)
                GearCheck(checked: isChecked)
            }
            .padding(.horizontal, 8)
            .frame(height: 38)
            .background(Color.white.opacity(isChecked ? 0 : 0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(SportPressStyle(scale: 0.97, dim: 0.04))
    }

    private func toggle(_ id: Int) {
        let wasPacked = allPacked
        var next = checked
        if next.contains(id) {
            next.remove(id)
        } else {
            next.insert(id)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            checked = next
        }
        scheduleReorder()
        guard !ctx.isPreview else { return }
        if allPacked && !wasPacked {
            Haptics.success()
        } else {
            Haptics.tap(.light)
        }
    }

    private func scheduleReorder() {
        reorderTask?.cancel()
        reorderTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: ctx["response"], dampingFraction: 0.8)) {
                sunk = checked
            }
        }
    }

    private func previewTick() {
        if let next = Self.items.first(where: { !checked.contains($0.id) }) {
            toggle(next.id)
        } else {
            reorderTask?.cancel()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                checked = []
                sunk = []
            }
        }
    }
}

private struct GearRing: View {
    let count: Int
    let total: Int
    let response: Double

    private var done: Bool { count == total }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(count) / CGFloat(max(total, 1)))
                .stroke(
                    done ? AnyShapeStyle(Signature.lime) : AnyShapeStyle(Signature.accentGradient),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (done ? Signature.lime : Signature.accent).opacity(0.6), radius: 5)
                .animation(.spring(response: response, dampingFraction: 0.75), value: count)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Signature.lime)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            } else {
                Text(verbatim: "\(count)/\(total)")
                    .font(Signature.number(14))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText(value: Double(count)))
                    .transition(.opacity)
            }
        }
        .frame(width: 52, height: 52)
        .scaleEffect(done ? 1.08 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.55), value: done)
    }
}

private struct GearCheck: View {
    let checked: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(checked ? 0 : 0.28), lineWidth: 1.5)
            Circle()
                .fill(Signature.accentGradient)
                .scaleEffect(checked ? 1 : 0.2)
                .opacity(checked ? 1 : 0)
                .shadow(color: Signature.accent.opacity(checked ? 0.6 : 0), radius: 5)
            GearCheckShape()
                .trim(from: 0, to: checked ? 1 : 0)
                .stroke(Signature.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .frame(width: 10, height: 8)
                .animation(checked ? Animation.easeOut(duration: 0.22).delay(0.08) : Animation.easeIn(duration: 0.1), value: checked)
        }
        .frame(width: 22, height: 22)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: checked)
    }
}

private struct GearCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
