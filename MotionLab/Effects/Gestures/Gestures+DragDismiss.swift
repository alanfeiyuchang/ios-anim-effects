import SwiftUI

extension Effect {
    static let gesturesDragDismiss = Effect(
        id: "gestures.drag-dismiss",
        category: .gestures,
        interaction: .gesture,
        name: L("Drag to Dismiss", "下拉关闭卡片"),
        summary: L("Pull a detail card down: it shrinks, rounds its corners and lets go past a threshold.", "下拉详情卡片，它会缩小、圆角变大，越过阈值即关闭。"),
        prompt: L(
            "A 250 × 300 pt detail card (hero gradient image, title and text lines, 14 pt corners, deep shadow) floats above a dimmed grid of thumbnails. Dragging down makes the card follow the finger while it interactively scales from 100% toward 70%, its corner radius grows from 14 pt to 44 pt, horizontal movement is damped to 60%, and the backdrop brightens as the dim fades — the card visibly becomes a thumbnail again. Upward drags are rubber-banded. On release, if the pull exceeds ~140 pt or the predicted end passes 320 pt, the card shrinks to 35% and drops away while fading (spring response 0.45 s, damping 0.85); otherwise it springs back to full size. The same gesture you use to close photos in iOS: direct, reversible and forgiving.",
            "一张 250 × 300pt 的详情卡片（渐变主图、标题与文字行、14pt 圆角、深投影）悬浮在一片变暗的缩略图网格之上。向下拖拽时卡片跟手，同时交互式地从 100% 缩小至约 70%、圆角由 14pt 增大到 44pt，水平位移衰减为 60%，背景遮罩逐渐褪去——卡片看起来正“变回”缩略图。向上拖拽带橡皮筋阻尼。松手时，若下拉超过约 140pt 或预测终点超过 320pt，卡片缩至 35% 并下坠淡出（弹簧响应 0.45 秒、阻尼 0.85）；否则以弹簧回到全尺寸。与 iOS 照片下拉关闭一致：直接、可逆、容错。"
        ),
        implementation: L(
            "A DragGesture maps vertical translation to a 0–1 progress that drives scaleEffect, corner radius and backdrop opacity; onEnded checks distance and predictedEndTranslation to dismiss or spring back.",
            "DragGesture 把竖直位移映射为 0–1 进度，驱动 scaleEffect、圆角与背景遮罩透明度；onEnded 根据位移和 predictedEndTranslation 决定关闭或回弹。"
        ),
        apis: ["DragGesture", "predictedEndTranslation", "scaleEffect", "clipShape", "spring(response:dampingFraction:)"],
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

    var body: some View {
        let progress = min(max(drag.height / 300, 0), 1)
        let scale = dismissed ? 0.35 : 1 - progress * ctx.cg("shrink")
        let radius = 14 + progress * 30
        let y = drag.height < 0 ? rubberBand(drag.height, limit: 40) : drag.height

        ZStack {
            ThumbnailGrid()
                .overlay(Color.black.opacity(dismissed ? 0 : 0.28 * Double(1 - progress)))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            DetailCard(language: ctx.language)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 14)
                .scaleEffect(scale)
                .offset(x: dismissed ? 0 : drag.width * 0.6, y: dismissed ? 150 : y)
                .opacity(dismissed ? 0 : 1)
                .gesture(dragGesture)
        }
        .frame(width: 290, height: 330)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            DemoHint(text: L("Pull the card down", "向下拖动卡片"), ctx: ctx)
                .padding(.bottom, 4)
        }
        .autoplay(ctx.isPreview, every: 2.8, delay: 0.5) { simulate() }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !dismissed else { return }
                drag = value.translation
            }
            .onEnded { value in
                guard !dismissed else { return }
                if value.translation.height > ctx.cg("threshold") || value.predictedEndTranslation.height > 320 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { drag = .zero }
                }
            }
    }

    private func dismiss() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            dismissed = true
            drag = .zero
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { dismissed = false }
        }
    }

    private func simulate() {
        withAnimation(.easeInOut(duration: 0.6)) { drag = CGSize(width: 14, height: 170) }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.65))
            dismiss()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Palette.ocean)
                .frame(height: 150)
                .overlay {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            VStack(alignment: .leading, spacing: 10) {
                Text(language == .zh ? "海岸线" : "Coastline")
                    .font(.headline)
                PlaceholderLines(count: 3)
            }
            .padding(.horizontal, 16)
            Spacer(minLength: 0)
        }
        .frame(width: 250, height: 300)
        .background(Palette.elevated)
    }
}
