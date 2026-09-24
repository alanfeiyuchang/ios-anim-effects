import SwiftUI

extension Effect {
    static let morphGalleryZoom = Effect(
        id: "morph.gallery-zoom",
        category: .morph,
        interaction: .tap,
        name: L("Gallery Zoom", "相册缩放转场"),
        summary: L(
            "A thumbnail zooms into a full-bleed paging viewer: swipe sideways between photos, fling one down to send it home.",
            "缩略图放大为全屏分页查看器：左右滑动翻看照片，向下甩动即把当前照片送回原位。"
        ),
        prompt: L(
            "A 3 × 3 grid of rounded photo thumbnails (14 pt corners). Tapping one zooms it out of its cell into a full-bleed viewer on a smooth spring (response ≈0.45 s, damping 0.86) while a black backdrop fades in. The viewer pages like Photos: a sideways swipe drags the whole strip 1:1 with the next photo peeking 16 pt behind a gap, rubber-bands at either end, and past 30% of the width (or a flick) snaps to the neighbour on a critically damped spring with a selection tick. A vertical pull locks to dismissal instead: the photo follows the finger, tilts up to ±6° with the sideways drift and the backdrop fades; past ~90 pt or a flick it flies into its own cell on an under-damped spring (≈0.7) that lands with a small bounce.",
            "3 × 3 圆角缩略图网格（圆角 14pt）。点击一张，它以平滑弹簧（响应约 0.45 秒、阻尼 0.86）从格子放大为全屏查看器，黑色背景淡入。查看器像“照片”一样分页：横向滑动时整条胶片 1:1 跟手，下一张隔着 16pt 间隙探出，两端带橡皮筋阻尼；拖过宽度的 30% 或快速轻扫，即以临界阻尼弹簧吸附到相邻照片，并伴随一次选择触感。若先竖向拖动则锁定为关闭手势：照片跟手移动，随横向偏移倾斜最多 ±6°，背景渐隐；超过约 90pt 或快速甩出，它以欠阻尼弹簧（约 0.7）飞回自己的格子，落位时轻轻一弹。"
        ),
        implementation: L(
            "Grid tiles and the current page share a matchedGeometryEffect id; one DragGesture locks its axis on the first movement: horizontal drives a paging offset whose settle spring swaps the page index in its completion, vertical drives the dismiss offset, tilt and backdrop.",
            "网格缩略图与当前页共享 matchedGeometryEffect ID；同一个 DragGesture 在首次移动时锁定方向：横向驱动分页位移，吸附弹簧在 completion 中切换页码；竖向驱动关闭位移、倾斜与背景透明度。"
        ),
        apis: ["matchedGeometryEffect", "DragGesture", "predictedEndTranslation", "withAnimation(_:completionCriteria:_:completion:)", "rotationEffect"],
        tags: ["photos", "gallery", "paging", "drag to dismiss", "相册", "分页", "翻页", "甩动关闭"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.45, unit: "s"),
            .slider("damping", L("Return damping", "归位阻尼"), 0.4...1.0, default: 0.7),
            .slider("tilt", L("Max tilt", "最大倾斜"), 0...15, default: 6, decimals: 0, unit: "°"),
            .slider("threshold", L("Dismiss distance", "关闭距离"), 40...200, default: 90, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        GalleryZoomDemo(ctx: ctx)
    }
}

private struct GalleryPhoto: Identifiable {
    let id: Int
    let symbol: String
    let colors: [Color]
}

private let galleryPhotos: [GalleryPhoto] = {
    let symbols = ["mountain.2.fill", "sun.horizon.fill", "leaf.fill", "water.waves", "cloud.sun.fill", "sparkles", "moon.stars.fill", "tree.fill", "flame.fill"]
    let spectrum = Palette.spectrum
    return symbols.enumerated().map { index, symbol in
        GalleryPhoto(
            id: index,
            symbol: symbol,
            colors: [spectrum[index % spectrum.count], spectrum[(index + 2) % spectrum.count]]
        )
    }
}()

private enum GalleryDragAxis {
    case paging
    case dismiss
}

private struct GalleryZoomDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    /// Index (= id) of the photo open in the viewer.
    @State private var selected: Int?
    /// Dismissal pull (vertical-locked drags).
    @State private var drag: CGSize = .zero
    /// Horizontal paging offset of the viewer strip.
    @State private var pageDrag: CGFloat = 0
    /// The neighbour the strip is springing to; committed as `selected` when the spring lands.
    @State private var pendingPage: Int?
    @State private var pageToken = 0
    @State private var axis: GalleryDragAxis?
    @State private var stageWidth: CGFloat = 0
    @State private var autoIndex = 4
    @State private var autoStage = 0
    @State private var flingTask: Task<Void, Never>?
    /// Resets on system cancellation too, so a cancelled pull never leaves the photo offset, tilted or between pages.
    @GestureState private var dragging = false
    @Environment(\.colorScheme) private var colorScheme

    private static let pageGap: CGFloat = 16

    /// Opening and paging are smooth and critically damped; only the flight home bounces.
    private var openSpring: Animation { .spring(response: ctx["response"], dampingFraction: 0.86) }
    private var pageSpring: Animation { .spring(response: ctx["response"] * 0.8, dampingFraction: 1) }
    private var returnSpring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }
    private var pageStride: CGFloat { stageWidth + Self.pageGap }

    /// 0…1 by how far the photo has been pulled away, in any direction.
    private var dragProgress: CGFloat {
        min(GalleryZoomDemo.length(drag) / 260, 1)
    }

    private static func length(_ size: CGSize) -> CGFloat {
        (size.width * size.width + size.height * size.height).squareRoot()
    }

    private var tiltAngle: Angle {
        let limit: Double = ctx["tilt"]
        let raw: Double = Double(drag.width) / 160 * limit
        return .degrees(min(max(raw, -limit), limit))
    }

    var body: some View {
        ZStack {
            grid
            if let index = selected {
                Color.black
                    .opacity(0.9 * (1 - Double(dragProgress)))
                    .transition(.opacity)
                    .zIndex(1)
                viewer(index)
                    .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            stageWidth = width
        }
        .overlay(alignment: .bottom) { hint }
        .autoplay(ctx.isPreview, every: 1.7) { autoStep() }
        .onDisappear {
            flingTask?.cancel()
            flingTask = nil
            commitPendingPage()
            axis = nil
        }
    }

    private var hint: some View {
        DemoHint(
            text: selected == nil
                ? L("Tap a photo", "点击一张照片")
                : L("Swipe to browse, pull down to close", "左右滑动翻看，下拉关闭"),
            ctx: ctx
        )
        .environment(\.colorScheme, selected == nil ? colorScheme : .dark)
        .padding(.bottom, 12)
        .opacity(dragProgress > 0 ? 0 : 1)
        .allowsHitTesting(false)
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.fixed(88), spacing: 8), count: 3)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(galleryPhotos) { photo in
                if selected == photo.id {
                    Color.clear.frame(width: 88, height: 88)
                } else {
                    GalleryArt(photo: photo, symbolSize: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .matchedGeometryEffect(id: photo.id, in: ns)
                        .frame(width: 88, height: 88)
                        .onTapGesture { open(photo.id) }
                }
            }
        }
    }

    private func neighbours(of index: Int) -> [Int] {
        [index - 1, index + 1].filter { galleryPhotos.indices.contains($0) }
    }

    private func viewer(_ index: Int) -> some View {
        ZStack {
            // Neighbours ride the same strip one page (stage width + gap) away; only the current page is matched.
            ForEach(neighbours(of: index), id: \.self) { other in
                GalleryArt(photo: galleryPhotos[other], symbolSize: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: CGFloat(other - index) * pageStride + pageDrag)
                    .opacity(1 - Double(dragProgress))
                    .transition(.opacity)
            }
            GalleryArt(photo: galleryPhotos[index], symbolSize: 84)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .matchedGeometryEffect(id: galleryPhotos[index].id, in: ns)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .rotationEffect(tiltAngle)
                .offset(x: drag.width + pageDrag, y: drag.height)
        }
        .contentShape(Rectangle())
        .gesture(viewerDrag)
        .onTapGesture { close() }
        .onChange(of: dragging) { _, active in
            if !active { finishDrag(nil) }
        }
    }

    private var viewerDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragging) { _, state, _ in state = true }
            .onChanged { value in
                flingTask?.cancel()
                flingTask = nil
                if axis == nil {
                    // A new touch lands a page that is still settling, then locks to the dominant direction.
                    commitPendingPage()
                    axis = abs(value.translation.width) > abs(value.translation.height) ? .paging : .dismiss
                }
                if axis == .paging {
                    pageDrag = rubberedPage(value.translation.width)
                } else {
                    drag = value.translation
                }
            }
            .onEnded { value in finishDrag(value) }
    }

    /// 1:1 between photos, rubber-banded past the first and last.
    private func rubberedPage(_ x: CGFloat) -> CGFloat {
        guard let index = selected else { return 0 }
        let atStart: Bool = index == 0 && x > 0
        let atEnd: Bool = index == galleryPhotos.count - 1 && x < 0
        return atStart || atEnd ? rubberBand(x, limit: 60) : x
    }

    /// Normal release (with the flick's projection) or system cancellation (`nil`: settle, never commit a close).
    private func finishDrag(_ value: DragGesture.Value?) {
        guard let locked = axis else { return }
        axis = nil
        switch locked {
        case .paging:
            guard let index = selected else { return }
            let moved: CGFloat = pageDrag
            let predicted: CGFloat = value?.predictedEndTranslation.width ?? moved
            let half: CGFloat = pageStride * 0.3
            var step = 0
            if (moved < -half || predicted < -pageStride * 0.6) && index + 1 < galleryPhotos.count { step = 1 }
            if (moved > half || predicted > pageStride * 0.6) && index > 0 { step = -1 }
            settlePage(step, silent: false)
        case .dismiss:
            let threshold: CGFloat = ctx.cg("threshold")
            if let value,
               GalleryZoomDemo.length(value.translation) > threshold
                || GalleryZoomDemo.length(value.predictedEndTranslation) > threshold * 3 {
                close()
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { drag = .zero }
            }
        }
    }

    /// Springs the strip to the neighbour (`step` ±1) or back (0); the index swaps invisibly once it lands.
    private func settlePage(_ step: Int, silent: Bool) {
        guard step != 0, let index = selected else {
            withAnimation(pageSpring) { pageDrag = 0 }
            return
        }
        if !silent && !ctx.isPreview { Haptics.selection() }
        pageToken += 1
        let token = pageToken
        pendingPage = index + step
        withAnimation(pageSpring, completionCriteria: .logicallyComplete) {
            pageDrag = -CGFloat(step) * pageStride
        } completion: {
            guard token == pageToken else { return }
            commitPendingPage()
        }
    }

    /// The neighbour now sits exactly where the current page was: swap them without animation.
    private func commitPendingPage() {
        guard let next = pendingPage else { return }
        pendingPage = nil
        pageToken += 1
        var swap = Transaction()
        swap.disablesAnimations = true
        withTransaction(swap) {
            selected = next
            pageDrag = 0
        }
    }

    /// Autoplay stand-in for a finger: open a photo, page once, then fling it home.
    private func autoStep() {
        if selected == nil {
            open(galleryPhotos[autoIndex % galleryPhotos.count].id)
            autoIndex += 2
            autoStage = 0
        } else if autoStage == 0, let index = selected {
            autoStage = 1
            settlePage(index + 1 < galleryPhotos.count ? 1 : -1, silent: true)
        } else {
            fling()
        }
    }

    private func fling() {
        commitPendingPage()
        withAnimation(.easeOut(duration: 0.28)) { drag = CGSize(width: 46, height: 120) }
        flingTask?.cancel()
        flingTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled, selected != nil else { return }
            close()
        }
    }

    private func open(_ id: Int) {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(openSpring) {
            drag = .zero
            pageDrag = 0
            selected = id
        }
    }

    private func close() {
        commitPendingPage()
        withAnimation(returnSpring) {
            selected = nil
            drag = .zero
            pageDrag = 0
        }
    }
}

private struct GalleryArt: View {
    let photo: GalleryPhoto
    let symbolSize: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(colors: photo.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: photo.symbol)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
    }
}
