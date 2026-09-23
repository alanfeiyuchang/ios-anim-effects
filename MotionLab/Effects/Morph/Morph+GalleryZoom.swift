import SwiftUI

extension Effect {
    static let morphGalleryZoom = Effect(
        id: "morph.gallery-zoom",
        category: .morph,
        interaction: .tap,
        name: L("Gallery Zoom", "相册缩放转场"),
        summary: L(
            "A thumbnail zooms into a full-bleed photo; fling it away in any direction and it tilts and bounces home.",
            "缩略图放大为全屏照片；向任意方向甩动，它会倾斜并弹跳着回到原位。"
        ),
        prompt: L(
            "A 3 × 3 grid of rounded photo thumbnails (14 pt corners). Tapping one zooms it out of its cell into a full-bleed viewer: the frame interpolates from the thumbnail rect to the whole stage on a smooth spring (response ≈0.45 s, damping 0.86) while a black backdrop fades in. Dismissal is physical, like Photos: the photo follows the finger 1:1 in both axes without shrinking, tilts up to ±6° in proportion to the sideways drag as if held by one corner, and the backdrop fades with distance to reveal the grid. Releasing past ~90 pt (or with a flick) flies it back into its cell on an under-damped spring (damping ≈0.7) that lands with a small bounce; otherwise it springs back upright. Tactile and free-handed.",
            "一个 3 × 3 的圆角缩略图网格（圆角 14pt）。点击任意一张，它会从所在格子中放大为全屏查看器：外框以平滑弹簧（响应约 0.45 秒、阻尼 0.86）从缩略图位置插值到整个舞台，背后黑色背景淡入。关闭像“照片”App 一样有物理感：照片在横纵两个方向 1:1 跟手、不做缩小，并随横向拖动按比例倾斜最多 ±6°，仿佛被捏住一角；黑色背景随拖动距离渐隐，露出网格。松手时若超过约 90pt（或快速甩出），照片以欠阻尼弹簧（阻尼约 0.7）飞回原格子，落位时轻轻一弹；否则回正并弹回全屏。真实、随手。"
        ),
        implementation: L(
            "Grid tiles and the viewer share a matchedGeometryEffect id per photo; a two-axis DragGesture drives the offset, a drag-proportional rotationEffect and the backdrop opacity, and the return flight resets them inside an under-damped spring together with the geometry match.",
            "网格缩略图与查看器按照片共享 matchedGeometryEffect ID；双轴 DragGesture 驱动位移、与横向拖动成比例的 rotationEffect 以及背景透明度，归位时在欠阻尼弹簧中与几何匹配一起复位。"
        ),
        apis: ["matchedGeometryEffect", "DragGesture", "predictedEndTranslation", "rotationEffect", "spring(response:dampingFraction:)"],
        tags: ["photos", "gallery", "zoom", "drag to dismiss", "相册", "图片放大", "甩动关闭", "转场"],
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

private struct GalleryZoomDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var selected: Int?
    @State private var drag: CGSize = .zero
    @State private var autoIndex = 4
    @State private var flingTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme

    /// Opening is smooth and critically damped; only the flight home bounces.
    private var openSpring: Animation { .spring(response: ctx["response"], dampingFraction: 0.86) }
    private var returnSpring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }

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
            if let id = selected, let photo = galleryPhotos.first(where: { $0.id == id }) {
                Color.black
                    .opacity(0.9 * (1 - Double(dragProgress)))
                    .transition(.opacity)
                    .zIndex(1)
                viewer(photo)
                    .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) { hint }
        .autoplay(ctx.isPreview, every: 1.7) {
            if selected == nil {
                open(galleryPhotos[autoIndex % galleryPhotos.count].id)
                autoIndex += 2
            } else {
                fling()
            }
        }
        .onDisappear { flingTask?.cancel() }
    }

    private var hint: some View {
        DemoHint(
            text: selected == nil
                ? L("Tap a photo", "点击一张照片")
                : L("Fling the photo away to close", "把照片甩开即可关闭"),
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

    private func viewer(_ photo: GalleryPhoto) -> some View {
        GalleryArt(photo: photo, symbolSize: 84)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .matchedGeometryEffect(id: photo.id, in: ns)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .rotationEffect(tiltAngle)
            .offset(drag)
            .gesture(dismissDrag)
            .onTapGesture { close() }
    }

    private var dismissDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                flingTask?.cancel()
                drag = value.translation
            }
            .onEnded { value in
                let threshold: CGFloat = ctx.cg("threshold")
                let moved: CGFloat = GalleryZoomDemo.length(value.translation)
                let projected: CGFloat = GalleryZoomDemo.length(value.predictedEndTranslation)
                if moved > threshold || projected > threshold * 3 {
                    close()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { drag = .zero }
                }
            }
    }

    /// Autoplay stand-in for a finger: pull the photo down and to the side, then let go.
    private func fling() {
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
            selected = id
        }
    }

    private func close() {
        withAnimation(returnSpring) {
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
