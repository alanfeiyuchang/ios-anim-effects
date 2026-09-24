import SwiftUI

extension Effect {
    static let navigationDockMagnify = Effect(
        id: "navigation.dock-magnify",
        category: .navigation,
        interaction: .gesture,
        name: L("Dock Magnification", "程序坞放大"),
        summary: L(
            "Slide a finger along the dock and icons swell around it like the macOS Dock.",
            "手指沿程序坞滑动，附近的图标像 macOS 程序坞一样膨胀放大。"
        ),
        prompt: L(
            "A frosted dock of seven 32 pt app icons with 8 pt gaps. As a finger slides along it, each icon's size follows a smooth cosine falloff of its distance to the finger: 1.6× directly under the touch, easing back to 1× about 100 pt away, so a wave of magnification travels with the finger. Icons grow upward from a shared baseline and push their neighbors outward while the frosted backing widens to fit, all tracking through a tight interactive spring (response 0.2 s). The icon under the finger lifts a name tooltip, with a selection tick each time it changes. On release everything settles on a softer spring (0.45 s, damping 0.75). Fluid, playful, precise.",
            "手指划过磨砂程序坞，七个 32 pt 图标（间距 8 pt）随之涌起一道放大波：尺寸按与手指距离的余弦衰减变化，正下方放大到 1.6 倍，约 100 pt 外回落至原大。图标沿同一底线向上长高，把邻居向两侧推开，磨砂底座跟着变宽，全程由紧致的交互式弹簧（响应 0.2 秒）贴手驱动。指下的图标上方浮出名称提示，每换一个就轻轻一记选择触感。松手后，一切以更柔和的弹簧（0.45 秒、阻尼 0.75）回落原位。流畅、灵动、分毫不差。"
        ),
        implementation: L(
            "Icon sizes are computed from the finger's x against each icon's resting center with a cosine falloff; positions are accumulated manually so the row widens symmetrically, and if the row would outgrow the canvas the extra growth is scaled down proportionally. Previews drive the finger with a 30 fps TimelineView sine sweep.",
            "根据手指 x 与每个图标静止中心的距离，用余弦衰减计算图标尺寸；位置手动累加，使整排对称变宽，若整排将超出画布，则按比例压缩额外增量。预览模式用 30 fps 的 TimelineView 正弦扫动模拟手指。"
        ),
        apis: ["DragGesture", "TimelineView", "position(x:y:)", "interactiveSpring", "cos falloff"],
        tags: ["dock", "magnification", "macos", "fisheye", "程序坞", "放大", "鱼眼", "悬停"],
        params: [
            .slider("scale", L("Max magnification", "最大放大"), 1.2...2.0, default: 1.6, unit: "×"),
            .slider("range", L("Influence range", "影响范围"), 50...180, default: 100, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        DockMagnifyDemo(ctx: ctx)
    }
}

private struct DockApp {
    let symbol: String
    let colors: [Color]
    let name: LocalizedText
}

private let dockApps: [DockApp] = [
    DockApp(symbol: "message.fill", colors: [Palette.green, Palette.mint], name: L("Messages", "信息")),
    DockApp(symbol: "safari.fill", colors: [Palette.sky, Palette.blue], name: L("Safari", "Safari")),
    DockApp(symbol: "music.note", colors: [Palette.pink, Palette.red], name: L("Music", "音乐")),
    DockApp(symbol: "photo.fill", colors: [Palette.amber, Palette.coral], name: L("Photos", "照片")),
    DockApp(symbol: "calendar", colors: [Palette.red, Palette.coral], name: L("Calendar", "日历")),
    DockApp(symbol: "note.text", colors: [Palette.amber, Color(hex: 0xFFD66B)], name: L("Notes", "备忘录")),
    DockApp(symbol: "gearshape.fill", colors: [Color(hex: 0x8E8E93), Color(hex: 0x5A5A60)], name: L("Settings", "设置")),
]

private struct DockMagnifyDemo: View {
    let ctx: DemoContext
    @State private var fingerX: CGFloat?
    @State private var hovered: Int?
    /// Set while the detail-page intro sweeps a simulated finger across the dock.
    @State private var sweepStart: Date?
    @State private var sweepTask: Task<Void, Never>?
    /// Bumped by every finger update, so a tap's delayed lift-off never cuts into a newer touch.
    @State private var pokeToken = 0
    @State private var sliding = false

    private let sweepDuration: Double = 1.2

    private let canvas = CGSize(width: 330, height: 170)

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottom) {
                DockDesktop(language: ctx.language, clearsReplay: !ctx.isPreview)
                if ctx.isPreview {
                    TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: true))) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        DockRow(fingerX: canvas.width / 2 + 120 * CGFloat(sin(t * 1.3)), ctx: ctx, canvas: canvas)
                    }
                    .frame(width: canvas.width, height: canvas.height)
                } else {
                    TimelineView(.animation(minimumInterval: nil, paused: sweepStart == nil)) { timeline in
                        DockRow(fingerX: liveFingerX(at: timeline.date), ctx: ctx, canvas: canvas)
                    }
                    .frame(width: canvas.width, height: canvas.height)
                    .contentShape(Rectangle())
                    // Horizontal slides only (vertical swipes keep scrolling the page); a cancelled slide
                    // still reports its end, so the row never stays magnified. A tap magnifies briefly.
                    .pageSafeHorizontalDrag(minimumDistance: 6, onChanged: { value in
                        sliding = true
                        track(value.location.x)
                    }, onEnded: { _ in
                        sliding = false
                        lift()
                    })
                    .simultaneousGesture(
                        SpatialTapGesture()
                            .onEnded { value in poke(at: value.location.x) }
                    )
                }
            }
            .frame(width: canvas.width, height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 20, y: 10)
            DemoHint(text: L("Slide along the dock", "沿程序坞滑动手指"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(false, every: 1, intro: true) { sweep() }
        .onDisappear {
            // @State survives navigation: drop the intro sweep's anchors so the row comes back at rest.
            sweepTask?.cancel()
            sweepTask = nil
            sweepStart = nil
            fingerX = nil
            hovered = nil
        }
    }

    /// The real finger, or the intro's simulated one while it sweeps.
    private func liveFingerX(at date: Date) -> CGFloat? {
        guard let sweepStart else { return fingerX }
        let raw: Double = date.timeIntervalSince(sweepStart) / sweepDuration
        let t: Double = min(max(raw, 0), 1)
        let eased: Double = t * t * (3 - 2 * t)
        // Starts one influence range left of the first icon so the wave rolls in from rest.
        let from: CGFloat = DockRow.restCenter(0, canvasWidth: canvas.width) - ctx.cg("range")
        let to: CGFloat = DockRow.restCenter(dockApps.count - 1, canvasWidth: canvas.width)
        return from + (to - from) * CGFloat(eased)
    }

    private func sweep() {
        sweepTask?.cancel()
        sweepStart = .now
        let duration = sweepDuration
        sweepTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, sweepStart != nil else { return }
            // Dropping the simulated finger inside the release spring settles the row like a real lift-off.
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                sweepStart = nil
                fingerX = nil
            }
        }
    }

    private func track(_ x: CGFloat) {
        pokeToken += 1
        if sweepStart != nil {
            sweepTask?.cancel()
            sweepStart = nil
        }
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) { fingerX = x }
        let nearest = DockRow.nearestIndex(to: x, canvasWidth: canvas.width)
        if nearest != hovered {
            hovered = nearest
            Haptics.selection()
        }
    }

    /// Normal release or system cancellation: settle the row and hide the tooltip.
    private func lift() {
        hovered = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { fingerX = nil }
    }

    /// A tap swells the icons under the finger for a moment, then lets go.
    private func poke(at x: CGFloat) {
        track(x)
        let token = pokeToken
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            if token == pokeToken && !sliding { lift() }
        }
    }
}

private struct DockRow: View {
    let fingerX: CGFloat?
    let ctx: DemoContext
    let canvas: CGSize

    static let base: CGFloat = 32
    static let spacing: CGFloat = 8

    static func restCenter(_ index: Int, canvasWidth: CGFloat) -> CGFloat {
        let count = CGFloat(dockApps.count)
        let total = count * base + (count - 1) * spacing
        let start = (canvasWidth - total) / 2
        return start + CGFloat(index) * (base + spacing) + base / 2
    }

    static func nearestIndex(to x: CGFloat, canvasWidth: CGFloat) -> Int {
        var best = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for index in dockApps.indices {
            let d = abs(restCenter(index, canvasWidth: canvasWidth) - x)
            if d < bestDistance {
                bestDistance = d
                best = index
            }
        }
        return best
    }

    private var sizes: [CGFloat] {
        let maxScale = ctx.cg("scale")
        let range = ctx.cg("range")
        let raw = dockApps.indices.map { (index: Int) -> CGFloat in
            guard let fingerX else { return Self.base }
            let d = abs(Self.restCenter(index, canvasWidth: canvas.width) - fingerX)
            guard d < range else { return Self.base }
            let falloff = (cos(Double(d / range) * Double.pi) + 1) / 2
            return Self.base * (1 + (maxScale - 1) * CGFloat(falloff))
        }
        // Keep the widened dock (plus its 10 pt padding each side) inside the canvas: if the
        // magnified row would overflow, scale only the extra growth down proportionally.
        let count = CGFloat(raw.count)
        let available = canvas.width - 28 - (count - 1) * Self.spacing
        let restTotal = count * Self.base
        let extra = raw.reduce(0, +) - restTotal
        guard extra > 0, restTotal + extra > available else { return raw }
        let factor = max(available - restTotal, 0) / extra
        return raw.map { Self.base + ($0 - Self.base) * factor }
    }

    var body: some View {
        let sizes: [CGFloat] = self.sizes
        let gaps: CGFloat = CGFloat(sizes.count - 1) * Self.spacing
        let total: CGFloat = sizes.reduce(0, +) + gaps
        let baseline = canvas.height - 22
        let startX = (canvas.width - total) / 2
        let hovered = fingerX.map { Self.nearestIndex(to: $0, canvasWidth: canvas.width) }

        ZStack(alignment: .topLeading) {
            DemoMaterial(RoundedRectangle(cornerRadius: 22, style: .continuous), material: .regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.stroke))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                .frame(width: total + 20, height: Self.base + 20)
                .position(x: canvas.width / 2, y: baseline - Self.base / 2)

            ForEach(dockApps.indices, id: \.self) { index in
                let size: CGFloat = sizes[index]
                let before: CGFloat = sizes[..<index].reduce(0, +)
                let x: CGFloat = startX + before + CGFloat(index) * Self.spacing + size / 2
                DockIcon(app: dockApps[index], size: size, showLabel: hovered == index, language: ctx.language)
                    .position(x: x, y: baseline - size / 2)
            }
        }
        .frame(width: canvas.width, height: canvas.height)
    }
}

private struct DockIcon: View {
    let app: DockApp
    let size: CGFloat
    let showLabel: Bool
    let language: AppLanguage

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(LinearGradient(colors: app.colors, startPoint: .top, endPoint: .bottom))
            .overlay {
                Image(systemName: app.symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .overlay(alignment: .top) {
                Text(app.name, language)
                    .font(.caption.weight(.semibold))
                    .fixedSize()
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .demoGlass(Capsule(), material: .regularMaterial)
                    .offset(y: -30)
                    .opacity(showLabel ? 1 : 0)
                    .scaleEffect(showLabel ? 1 : 0.7, anchor: .bottom)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showLabel)
            }
    }
}

/// Miniature desktop behind the dock: wallpaper, menu bar and a floating window.
private struct DockDesktop: View {
    let language: AppLanguage
    /// On the detail stage the Replay orb sits over the top-trailing corner; the menu bar's clock
    /// steps in so the orb never clips it.
    var clearsReplay = false
    @Environment(\.colorScheme) private var scheme

    private var wallpaper: [Color] {
        scheme == .dark
            ? [Color(hex: 0x1D2671), Color(hex: 0x4B3AA8), Color(hex: 0x8A3F7E)]
            : [Color(hex: 0x9CCBFF), Color(hex: 0xC3B4FF), Color(hex: 0xFFC2D9)]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: wallpaper, startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 12) {
                Circle().fill(.white.opacity(0.9)).frame(width: 9, height: 9)
                Text(language == .zh ? "访达" : "Finder")
                    .font(.caption2.weight(.bold))
                Text(language == .zh ? "文件" : "File")
                    .font(.caption2)
                Text(language == .zh ? "编辑" : "Edit")
                    .font(.caption2)
                Spacer()
                Text(verbatim: "9:41")
                    .font(.caption2.weight(.semibold).monospacedDigit())
            }
            .foregroundStyle(.white)
            .padding(.leading, 14)
            .padding(.trailing, clearsReplay ? 44 : 14)
            .frame(height: 22)
            .background(.black.opacity(0.12))
            window
                .padding(.top, 36)
                .padding(.leading, 34)
        }
    }

    private var window: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Circle().fill(Palette.red).frame(width: 7, height: 7)
                Circle().fill(Palette.amber).frame(width: 7, height: 7)
                Circle().fill(Palette.green).frame(width: 7, height: 7)
            }
            PlaceholderLines(count: 2, color: .primary.opacity(0.1))
        }
        .padding(10)
        .frame(width: 170, alignment: .leading)
        .demoGlass(RoundedRectangle(cornerRadius: 10, style: .continuous), material: .regularMaterial)
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }
}
