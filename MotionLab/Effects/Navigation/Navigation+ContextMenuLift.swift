import SwiftUI

extension Effect {
    static let navigationContextMenuLift = Effect(
        id: "navigation.context-menu-lift",
        category: .navigation,
        interaction: .gesture,
        name: L("Context Menu Lift", "长按抬起菜单"),
        summary: L(
            "Press and hold a row: it sinks, lifts into a preview card and a menu unfolds beneath it.",
            "长按列表行：先下沉，再抬起成预览卡片，下方展开操作菜单。"
        ),
        prompt: L(
            "A list of photo rows on 18 pt continuous-corner cards. Pressing and holding a row sinks it to 96% over the whole hold (0.4 s ease-out), so the press feels like it is building. When the hold completes, a medium haptic fires and the row lifts out, morphing into a 280 × 168 pt preview card (artwork over title and caption) with a deep shadow on a spring (response ≈0.42 s, damping ≈0.78), while the list recedes to 97%, blurs 6 pt and dims under a 15% scrim. A frosted menu — Share, Copy, Favorite, a red Delete — scales out from the card's top-leading corner, rows fading down 30 ms apart. Tapping outside or an action folds it all back into the row; releasing early just springs back. Deliberate, tactile, focused.",
            "一组照片列表行（44 pt 缩略图、标题、说明），每行是 18 pt 连续圆角卡片。长按某一行时，它在整个按住期间以 0.4 秒缓出平滑下沉到 96%，让用户感到“力度在积蓄”。按满时触发中等触感，该行从列表中“抬起”：以弹簧（响应约 0.42 秒、阻尼约 0.78）形变为 280 × 168 pt 的预览卡片（上方插图、下方标题与说明），并投下深色阴影；其余列表缩小到 97%、模糊 6 pt，并覆上 15% 的暗色遮罩。一块磨砂菜单（分享、拷贝、收藏、红色的删除）从预览卡片左上角缩放展开，各行间隔 30 毫秒依次下落淡入。点击外部任意位置或选择某项操作，一切再收回原行；提前松手则直接弹回。审慎、可触、专注。"
        ),
        implementation: L(
            "onLongPressGesture(minimumDuration:perform:onPressingChanged:) drives the press sink and the lift; the row and the preview card are exclusive views sharing a matchedGeometryEffect id, the menu enters with a scale-from-anchor transition, and a scrim closes it.",
            "onLongPressGesture(minimumDuration:perform:onPressingChanged:) 驱动按压下沉与抬起；列表行与预览卡片互斥显示并共享 matchedGeometryEffect ID，菜单以锚点缩放转场出现，点击遮罩即可关闭。"
        ),
        apis: ["onLongPressGesture(minimumDuration:perform:onPressingChanged:)", "matchedGeometryEffect", "transition(.scale(scale:anchor:))", "blur(radius:)", "zIndex"],
        tags: ["context menu", "long press", "peek", "preview", "上下文菜单", "长按", "预览", "抬起"],
        params: [
            .slider("hold", L("Hold duration", "长按时长"), 0.2...0.8, default: 0.4, unit: "s"),
            .slider("response", L("Lift spring response", "抬起弹簧响应"), 0.2...0.8, default: 0.42, unit: "s"),
            .slider("blur", L("Background blur", "背景模糊"), 0...12, default: 6, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        ContextMenuLiftDemo(ctx: ctx)
    }
}

private struct LiftPhoto {
    let symbol: String
    let colors: [Color]
    let title: LocalizedText
    let caption: LocalizedText
}

private let liftPhotos: [LiftPhoto] = [
    LiftPhoto(symbol: "mountain.2.fill", colors: [Palette.sky, Palette.indigo], title: L("Alpine Lake", "高山湖泊"), caption: L("Yesterday · 24 photos", "昨天 · 24 张照片")),
    LiftPhoto(symbol: "sun.horizon.fill", colors: [Palette.amber, Palette.coral], title: L("Golden Hour", "黄金时刻"), caption: L("Sep 12 · 8 photos", "9 月 12 日 · 8 张照片")),
    LiftPhoto(symbol: "leaf.fill", colors: [Palette.mint, Palette.green], title: L("Fern Study", "蕨类习作"), caption: L("Sep 3 · 15 photos", "9 月 3 日 · 15 张照片")),
]

private let liftActions: [(String, LocalizedText, Bool)] = [
    ("square.and.arrow.up", L("Share", "分享"), false),
    ("doc.on.doc", L("Copy", "拷贝"), false),
    ("heart", L("Favorite", "收藏"), false),
    ("trash", L("Delete", "删除"), true),
]

private struct ContextMenuLiftDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var lifted: Int?
    @State private var pressing: Int?
    @State private var autoIndex = 1

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: 0.78) }

    var body: some View {
        ZStack(alignment: .top) {
            list
                .scaleEffect(lifted == nil ? 1 : 0.97)
                .blur(radius: lifted == nil ? 0 : ctx["blur"])
            if let index = lifted {
                Color.black
                    .opacity(0.15)
                    .contentShape(Rectangle())
                    .onTapGesture { close() }
                    .transition(.opacity)
                    .zIndex(1)
                VStack(alignment: .leading, spacing: 10) {
                    // Matched before the fixed frame, so the frame itself interpolates row → card.
                    LiftPreviewCard(photo: liftPhotos[index], language: ctx.language)
                        .matchedGeometryEffect(id: index, in: ns)
                        .frame(width: 280, height: 168)
                    LiftMenu(language: ctx.language, onSelect: { close() })
                        .transition(
                            .scale(scale: 0.4, anchor: .topLeading)
                                .combined(with: .opacity)
                        )
                }
                .padding(.top, 18)
                .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) {
            if lifted == nil { lift(autoIndex) } else { close() }
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(ctx.language == .zh ? "相簿" : "Albums")
                .font(.title2.weight(.bold))
            ForEach(0..<liftPhotos.count, id: \.self) { index in
                if lifted == index {
                    Color.clear.frame(width: 300, height: 64)
                } else {
                    LiftRow(photo: liftPhotos[index], language: ctx.language)
                        .matchedGeometryEffect(id: index, in: ns)
                        .frame(width: 300, height: 64)
                        .scaleEffect(pressing == index ? 0.96 : 1)
                        .onLongPressGesture(minimumDuration: ctx["hold"], maximumDistance: 12) {
                            lift(index)
                        } onPressingChanged: { isPressing in
                            // Sink gradually for the whole hold, spring back if released early.
                            withAnimation(isPressing ? .easeOut(duration: ctx["hold"]) : .spring(response: 0.3, dampingFraction: 0.7)) {
                                pressing = isPressing ? index : nil
                            }
                        }
                }
            }
            DemoHint(text: L("Press and hold a row", "长按任意一行"), ctx: ctx)
                .padding(.top, 4)
        }
        .padding(.top, 18)
    }

    private func lift(_ index: Int) {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(spring) {
            pressing = nil
            lifted = index
        }
    }

    private func close() {
        if !ctx.isPreview { Haptics.tap(.light) }
        withAnimation(spring) { lifted = nil }
    }
}

private struct LiftArt: View {
    let photo: LiftPhoto
    let symbolSize: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(colors: photo.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: photo.symbol)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
    }
}

private struct LiftRow: View {
    let photo: LiftPhoto
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            LiftArt(photo: photo, symbolSize: 18)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.title, language)
                    .font(.subheadline.weight(.semibold))
                Text(photo.caption, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct LiftPreviewCard: View {
    let photo: LiftPhoto
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LiftArt(photo: photo, symbolSize: 54)
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.title, language)
                    .font(.headline)
                Text(photo.caption, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 26, y: 14)
    }
}

private struct LiftMenu: View {
    let language: AppLanguage
    let onSelect: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<liftActions.count, id: \.self) { index in
                let action = liftActions[index]
                if action.2 {
                    Divider()
                }
                Button(action: onSelect) {
                    HStack(spacing: 12) {
                        Text(action.1, language)
                            .font(.subheadline)
                        Spacer(minLength: 24)
                        Image(systemName: action.0)
                            .font(.subheadline)
                    }
                    .foregroundStyle(action.2 ? Palette.red : Color.primary)
                    .padding(.horizontal, 14)
                    .frame(width: 200, height: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -6)
                .animation(.spring(response: 0.35, dampingFraction: 0.85).delay(0.05 + Double(index) * 0.03), value: appeared)
            }
        }
        .padding(.vertical, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.18), radius: 22, y: 10)
        .onAppear { appeared = true }
    }
}
