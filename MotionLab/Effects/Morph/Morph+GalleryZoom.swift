import SwiftUI

extension Effect {
    static let morphGalleryZoom = Effect(
        id: "morph.gallery-zoom",
        category: .morph,
        interaction: .tap,
        name: L("Gallery Zoom", "相册缩放转场"),
        summary: L(
            "A thumbnail zooms into a full-bleed photo; drag down to shrink it back.",
            "缩略图放大为全屏照片，向下拖拽即可缩回原位。"
        ),
        prompt: L(
            "A 3 × 3 grid of rounded photo thumbnails (14 pt corners). Tapping one zooms it out of its cell into a full-bleed viewer: the frame interpolates from the thumbnail rect to the whole screen on a spring (response ≈0.45 s, damping ≈0.86), the corners square off and a black backdrop fades in behind while the grid falls away. The photo is interactive: dragging down makes it follow the finger 1:1, shrink toward ~70% and round its corners in proportion, while the backdrop becomes transparent to reveal the grid. Releasing past ~90 pt (or with a downward flick) flies it back into its exact original cell; otherwise it springs back to full screen.",
            "一个 3 × 3 的圆角缩略图网格（圆角 14pt）。点击任意一张，它会从所在格子中放大为全屏查看器：外框以弹簧（响应约 0.45 秒、阻尼约 0.86）从缩略图位置插值到整屏，圆角逐渐变直，背后黑色背景淡入，网格随之隐去。照片可交互：向下拖拽时它 1:1 跟手，按拖拽距离缩小到约 70% 并逐渐恢复圆角，黑色背景同时变透明露出网格。松手时若超过约 90pt（或快速下滑），照片会精准飞回原来的格子；否则弹回全屏。"
        ),
        implementation: L(
            "Grid tiles and the viewer share a matchedGeometryEffect id per photo; a DragGesture drives offset, scale, corner radius and backdrop opacity, and dismissing resets them in the same spring as the geometry match.",
            "网格缩略图与查看器按照片共享 matchedGeometryEffect ID；DragGesture 驱动位移、缩放、圆角与背景透明度，关闭时在与几何匹配相同的弹簧中复位。"
        ),
        apis: ["matchedGeometryEffect", "DragGesture", "predictedEndTranslation", "scaleEffect", "spring(response:dampingFraction:)"],
        tags: ["photos", "gallery", "zoom", "drag to dismiss", "相册", "图片放大", "下拉关闭", "转场"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.45, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.86),
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

private struct GalleryZoomDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var selected: Int?
    @State private var drag: CGSize = .zero
    @State private var autoIndex = 4

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }
    private var dragProgress: CGFloat { min(max(drag.height, 0) / 300, 1) }

    var body: some View {
        ZStack {
            grid
            if let id = selected, let photo = galleryPhotos.first(where: { $0.id == id }) {
                Color.black
                    .opacity(0.9 * (1 - dragProgress))
                    .transition(.opacity)
                    .zIndex(1)
                viewer(photo)
                    .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.7) {
            if selected == nil {
                open(galleryPhotos[autoIndex % galleryPhotos.count].id)
                autoIndex += 2
            } else {
                close()
            }
        }
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

    private func viewer(_ photo: GalleryPhoto) -> some View {
        GalleryArt(photo: photo, symbolSize: 84)
            .clipShape(RoundedRectangle(cornerRadius: 30 * dragProgress + 4, style: .continuous))
            .matchedGeometryEffect(id: photo.id, in: ns)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(1 - dragProgress * 0.3)
            .offset(drag)
            .gesture(dismissDrag)
            .onTapGesture { close() }
    }

    private var dismissDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                drag = CGSize(width: value.translation.width, height: max(value.translation.height, rubberBand(value.translation.height, limit: 30)))
            }
            .onEnded { value in
                if value.translation.height > ctx["threshold"] || value.predictedEndTranslation.height > ctx["threshold"] * 3 {
                    close()
                } else {
                    withAnimation(spring) { drag = .zero }
                }
            }
    }

    private func open(_ id: Int) {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(spring) {
            drag = .zero
            selected = id
        }
    }

    private func close() {
        withAnimation(spring) {
            selected = nil
            drag = .zero
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
