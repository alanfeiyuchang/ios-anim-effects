import SwiftUI

extension Effect {
    static let gesturesDragDismiss = Effect(
        id: "gestures.drag-dismiss",
        category: .gestures,
        interaction: .gesture,
        name: L("Drag to Dismiss", "下拉关闭卡片"),
        summary: L("Pull a detail card down: it shrinks, rounds its corners and lets go past a threshold.", "下拉详情卡片，它会缩小、圆角变大，越过阈值即关闭。"),
        prompt: L(
            "A 220×260 pt detail card (hero gradient image, title and text lines, 14 pt corners, deep shadow) floats above a dimmed grid of thumbnails. Dragging down makes it follow the finger while it scales interactively from 100% toward 70% around the grabbed point, so that spot stays under the finger, its corner radius grows from 14 to 44 pt, sideways travel is damped to 60% and the backdrop brightens as the dim fades, so the card visibly turns back into a thumbnail; a swipe that starts upward scrolls the page instead, and pushing back above the start rubber-bands. On release, a pull past 140 pt or a predicted end beyond 320 pt shrinks the card to 35% and drops it away as it fades (spring response 0.45 s, damping 0.85); anything less springs back to full size. Direct, reversible and forgiving, like closing a photo in iOS.",
            "一张220×260 pt的详情卡片（渐变主图、标题与文字行、14 pt圆角）悬浮在变暗的缩略图网格上。向下拖动时卡片跟手，并以按住的点为锚点从100%交互式缩向70%，让那一点始终留在指下；圆角由14 pt增到44 pt，横向位移衰减为60%，背景遮罩逐渐褪去，仿佛“变回”缩略图；起手上滑交给页面滚动，拖回起点上方带橡皮筋阻尼。松手时若下拉超过140 pt或预测终点超过320 pt，卡片缩到35%并下坠淡出（弹簧响应0.45秒、阻尼0.85），否则弹回全尺寸。就像iOS下拉关闭照片。"
        ),
        implementation: L(
            "A UIKit pan bridged with UIGestureRecognizerRepresentable, which only begins on downward or sideways drags, maps vertical translation to a 0–1 progress that drives scaleEffect (anchored at the touch's UnitPoint), corner radius and backdrop opacity; the release checks distance and the velocity-projected end to dismiss or spring back.",
            "通过 UIGestureRecognizerRepresentable 桥接、只在向下或横向拖动时开始的 UIKit 平移手势，把竖直位移映射为 0–1 进度，驱动 scaleEffect（以触点换算的 UnitPoint 为锚点）、圆角与背景遮罩透明度；松手时根据位移和按速度投影的终点决定关闭或回弹。"
        ),
        apis: ["UIGestureRecognizerRepresentable", "UIPanGestureRecognizer", "scaleEffect", "clipShape", "spring(response:dampingFraction:)"],
        tags: ["dismiss", "pull down", "sheet", "interactive", "close", "下拉关闭", "交互式", "卡片", "关闭"],
        params: [
            .slider("threshold", L("Dismiss distance", "关闭距离"), 80...220, default: 140, step: 1, decimals: 0, unit: "pt"),
            .slider("shrink", L("Max shrink", "最大缩小"), 0.1...0.5, default: 0.3),
        ]
    ) { ctx in
        DragDismissDemo(ctx: ctx)
    }
}

private struct DragDismissDemo: View {
    let ctx: DemoContext
    @State private var drag: CGSize = .zero
    @State private var dismissed = false
    /// Scale anchor: the grabbed point in card space, so it stays under the finger.
    @State private var anchor: UnitPoint = .center
    /// True while a real finger holds the card; each new hold re-captures `anchor`.
    @State private var held = false
    /// The scripted pull, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Brings the card back after a dismissal.
    @State private var reset: Task<Void, Never>?

    private static let cardSize = CGSize(width: 220, height: 260)

    var body: some View {
        let progress = min(max(drag.height / 300, 0), 1)
        let scale = dismissed ? 0.35 : 1 - progress * ctx.cg("shrink")
        let radius = 14 + progress * 30
        let y = drag.height < 0 ? rubberBand(drag.height, limit: 40) : drag.height

        VStack(spacing: 14) {
            ZStack {
                ThumbnailGrid()
                    .overlay(Color.black.opacity(dismissed ? 0 : 0.28 * Double(1 - progress)))
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                DetailCard(language: ctx.language, size: Self.cardSize)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 14)
                    .scaleEffect(scale, anchor: anchor)
                    .offset(x: dismissed ? 0 : drag.width * 0.6, y: dismissed ? 150 : y)
                    .opacity(dismissed ? 0 : 1)
                    // Only a drag that starts downward or sideways takes the card (the page scroll waits for it);
                    // an upward swipe scrolls the detail page. A cancelled pan reports `nil` and springs back.
                    .gesture(PageSafePan(
                        directions: [.down, .left, .right],
                        isEnabled: !dismissed,
                        onChanged: dragChanged,
                        onEnded: dragEnded,
                        onBegan: grab
                    ))
            }
            .frame(width: 290, height: 300)
            DemoHint(text: L("Pull the card down", "向下拖动卡片"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.8, delay: 0.5) { simulate() }
        .onDisappear {
            script?.cancel()
            reset?.cancel()
            dismissed = false
            drag = .zero
        }
    }

    /// Touch-down point of a pan that has just begun: the finger takes over from the script and anchors the scale.
    private func grab(_ start: CGPoint) {
        guard !dismissed else { return }
        held = true
        script?.cancel()
        script = nil
        anchor = UnitPoint(
            x: (start.x / Self.cardSize.width).clamped(to: 0...1),
            y: (start.y / Self.cardSize.height).clamped(to: 0...1)
        )
    }

    private func dragChanged(_ translation: CGSize) {
        guard held, !dismissed else { return }
        drag = translation
    }

    /// Normal release (with the flick's projection) or system cancellation (`nil`: spring back, never dismiss).
    private func dragEnded(_ end: PageSafePanEnd?) {
        guard held else { return }
        held = false
        guard !dismissed else { return }
        if let end, end.translation.height > ctx.cg("threshold") || end.predictedEndTranslation.height > 320 {
            dismiss()
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { drag = .zero }
        }
    }

    /// Simulated pulls dismiss from a Task (outside the muted autoplay call), so they pass `haptic: false`.
    private func dismiss(haptic: Bool = true) {
        if haptic && !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            dismissed = true
            drag = .zero
        }
        reset?.cancel()
        reset = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { dismissed = false }
        }
    }

    private func simulate() {
        guard !held, !dismissed else { return }
        anchor = UnitPoint(x: 0.5, y: 0.3)
        withAnimation(.easeInOut(duration: 0.6)) { drag = CGSize(width: 14, height: 170) }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.65))
            guard !Task.isCancelled else { return }
            dismiss(haptic: false)
        }
    }
}

private struct ThumbnailGrid: View {
    private let colors: [Color] = [Palette.indigo, Palette.coral, Palette.mint, Palette.amber, Palette.sky, Palette.pink, Palette.violet, Palette.green, Palette.blue]

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(0..<3, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colors[row * 3 + column].gradient.opacity(0.75))
                    }
                }
            }
        }
        .padding(8)
    }
}

private struct DetailCard: View {
    let language: AppLanguage
    let size: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Palette.ocean)
                .frame(height: 124)
                .overlay {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            VStack(alignment: .leading, spacing: 10) {
                Text(L("Coastline", "海岸线"), language)
                    .font(.headline)
                PlaceholderLines(count: 2)
            }
            .padding(.horizontal, 16)
            Spacer(minLength: 0)
        }
        .frame(width: size.width, height: size.height)
        .background(Palette.elevated)
    }
}
