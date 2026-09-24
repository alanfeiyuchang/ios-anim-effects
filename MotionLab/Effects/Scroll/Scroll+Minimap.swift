import SwiftUI

extension Effect {
    static let scrollMinimap = Effect(
        id: "scroll.minimap",
        category: .scroll,
        interaction: .scroll,
        name: L("Minimap Scrubber", "缩略图导航"),
        summary: L("A code-editor-style minimap beside the page with a viewport lens you can see slide and drag.", "页面旁的代码编辑器式缩略图，视口镜框随滚动滑动，也可以直接拖动。"),
        prompt: L(
            "A document of coloured blocks (headings, paragraphs, images, code) scrolls on the left, and a 44 pt-wide minimap on the right renders the same document at 18% scale. A rounded lens on the minimap outlines exactly what is visible: its top is the scroll offset × 0.18 and its height the viewport × 0.18, so it glides in lockstep with the page. While scrolling, the lens brightens from 12% to 22% tint and its border thickens from 1 to 1.5 pt, easing back 0.6 s after the scroll settles. Dragging on the minimap jumps the page so the lens centers under the finger, with a selection tick. Informative, precise and quietly technical, like a code editor.",
            "左侧是一篇由彩色块（标题、段落、图片、代码）组成的文档，右侧一条44 pt宽的缩略图以18%的比例渲染同一篇文档。缩略图上的圆角镜框准确框出当前可见区域：顶部等于滚动偏移× 0.18，高度等于视口× 0.18，因此它与页面同步滑动。滚动时，镜框的着色从12%提亮到22%，边框从1 pt加粗到1.5 pt，滚动停止0.6秒后再缓缓恢复。在缩略图上拖动会让页面跳转，使镜框中心落在手指下，并伴随选择触感。信息清晰、精准，带一点安静的技术感，就像代码编辑器。"
        ),
        implementation: L(
            "Both views are built from one block list, the minimap with every length multiplied by 0.18. onScrollGeometryChange reports offset and viewport as one Equatable struct for the lens; onScrollPhaseChange drives the active state, and a DragGesture on the minimap calls ScrollPosition.scrollTo(y:).",
            "两侧视图由同一份块列表生成，缩略图的所有尺寸乘以 0.18。onScrollGeometryChange 把偏移和视口打包成一个 Equatable 结构体用于镜框；onScrollPhaseChange 控制激活状态，缩略图上的 DragGesture 调用 ScrollPosition.scrollTo(y:)。"
        ),
        apis: ["onScrollGeometryChange", "onScrollPhaseChange", "ScrollPosition", "DragGesture", "Equatable"],
        tags: ["minimap", "scrubber", "overview", "code editor", "缩略图", "导航", "概览", "编辑器"],
        params: [
            // Capped so the whole miniature (≈1,210 pt × scale) always fits the stage.
            .slider("scale", L("Minimap scale", "缩略比例"), 0.12...0.22, default: 0.18),
            .toggle("glow", L("Glow while scrolling", "滚动时高亮"), default: true),
        ]
    ) { ctx in
        ScrollMinimapDemo(ctx: ctx)
    }
}

private struct ScrollMinimapBlock {
    enum Kind { case heading, text, image, code }
    let kind: Kind
    let height: CGFloat
    /// Fraction of the column width.
    let width: CGFloat
    let color: Int
}

private let scrollMinimapBlocks: [ScrollMinimapBlock] = {
    var blocks: [ScrollMinimapBlock] = []
    let pattern: [(ScrollMinimapBlock.Kind, CGFloat, CGFloat)] = [
        (.heading, 22, 0.7), (.text, 60, 1), (.text, 44, 0.9), (.image, 110, 1), (.text, 58, 1),
        (.code, 84, 0.95), (.heading, 20, 0.55), (.text, 70, 1), (.image, 90, 1), (.text, 40, 0.8),
        (.code, 64, 0.9), (.text, 56, 1), (.heading, 22, 0.65), (.text, 48, 1), (.image, 120, 1), (.text, 62, 0.85),
    ]
    for (i, item) in pattern.enumerated() {
        blocks.append(ScrollMinimapBlock(kind: item.0, height: item.1, width: item.2, color: i))
    }
    return blocks
}()

private let scrollMinimapSpacing: CGFloat = 14
private let scrollMinimapPadding: CGFloat = 16

private struct ScrollMinimapMetrics: Equatable {
    var offset: CGFloat = 0
    var viewport: CGFloat = 1
    var content: CGFloat = 1
}

private struct ScrollMinimapDemo: View {
    let ctx: DemoContext
    @State private var position = ScrollPosition(edge: .top)
    @State private var metrics = ScrollMinimapMetrics()
    @State private var active = false
    @State private var idleTask: Task<Void, Never>?
    @State private var lastJump = -1
    @State private var down = false
    /// True while a real finger drags on the minimap.
    @State private var held = false
    /// Resets on system cancellation too, so a stolen touch never leaves the lens lit.
    @GestureState private var pressing = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                page
                minimap
            }
            DemoHint(text: L("Scroll the page, or drag on the minimap", "滚动页面，或在缩略图上拖动"), ctx: ctx)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .autoplay(ctx.isPreview, every: 2.8) {
            down.toggle()
            withAnimation(.smooth(duration: 2.2)) {
                position.scrollTo(edge: down ? .bottom : .top)
            }
        }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
        .onDisappear { idleTask?.cancel() }
    }

    private var page: some View {
        ScrollView {
            ScrollMinimapDocument(scale: 1)
                .padding(scrollMinimapPadding)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .onScrollGeometryChange(for: ScrollMinimapMetrics.self, of: { geometry in
            ScrollMinimapMetrics(
                offset: geometry.contentOffset.y + geometry.contentInsets.top,
                viewport: max(geometry.containerSize.height, 1),
                content: max(geometry.contentSize.height, 1)
            )
        }, action: { _, newValue in
            metrics = newValue
        })
        .onScrollPhaseChange { _, newPhase in
            if newPhase.isScrolling {
                idleTask?.cancel()
                withAnimation(.easeOut(duration: 0.15)) { active = true }
            } else {
                scheduleIdle()
            }
        }
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var minimap: some View {
        let scale = ctx.cg("scale")
        let lensTop = metrics.offset * scale
        let lensHeight = metrics.viewport * scale
        let lit = active && ctx.bool("glow")
        return ScrollMinimapDocument(scale: scale)
            .padding(scrollMinimapPadding * scale)
            .frame(width: 44, alignment: .top)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Palette.indigo.opacity(lit ? 0.22 : 0.12))
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Palette.indigo.opacity(0.8), lineWidth: lit ? 1.5 : 1))
                    .frame(height: lensHeight)
                    .offset(y: lensTop)
                    .padding(.horizontal, -3)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .gesture(scrub(scale: scale))
    }

    private func scrub(scale: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                held = true
                let maxOffset = max(metrics.content - metrics.viewport, 0)
                let target = (value.location.y / max(scale, 0.01) - metrics.viewport / 2).clamped(to: 0...maxOffset)
                let bucket = Int(target / 80)
                if bucket != lastJump {
                    lastJump = bucket
                    Haptics.selection()
                }
                position.scrollTo(y: target)
                idleTask?.cancel()
                active = true
            }
            .onEnded { _ in endHold() }
    }

    /// Release or system cancellation: forget the last jump and let the lens dim.
    private func endHold() {
        guard held else { return }
        held = false
        lastJump = -1
        scheduleIdle()
    }

    private func scheduleIdle() {
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.4)) { active = false }
        }
    }
}

/// The document, drawn at any scale so the minimap is an exact miniature of the page.
private struct ScrollMinimapDocument: View {
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: scrollMinimapSpacing * scale) {
            ForEach(scrollMinimapBlocks.indices, id: \.self) { i in
                block(scrollMinimapBlocks[i])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func block(_ block: ScrollMinimapBlock) -> some View {
        let height = block.height * scale
        let radius = max(6 * scale, 1)
        switch block.kind {
        case .heading:
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.primary.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .scaleEffect(x: block.width, y: 1, anchor: .leading)
        case .text:
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.primary.opacity(0.14))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .scaleEffect(x: block.width, y: 1, anchor: .leading)
        case .image:
            RoundedRectangle(cornerRadius: radius * 2, style: .continuous)
                .fill(LinearGradient(colors: ScrollKit.colors(block.color), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: height)
        case .code:
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Palette.indigo.opacity(0.16))
                .frame(height: height)
        }
    }
}
