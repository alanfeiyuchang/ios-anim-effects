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
            "A frosted dock holding seven 32 pt app icons with 8 pt gaps, resting on a miniature desktop (soft gradient wallpaper, menu bar and a floating window). As the finger slides along it, each icon's size follows a smooth cosine falloff of its distance to the finger — up to 1.6× directly under the touch (capped at 2×), easing back to 1× about 100 pt away — so a gentle wave of magnification travels with the finger. Icons grow upward from a shared baseline and push their neighbors outward, the dock's frosted backing widening to fit; if the row would outgrow the screen, the extra growth is scaled down proportionally so the dock never clips; motion tracks the finger through a tight interactive spring (response ≈0.2 s). The icon under the finger lifts a label tooltip above it and a selection tick fires as it changes. On release everything settles back to rest on a softer spring.",
            "一条磨砂程序坞停在一块迷你桌面上（柔和渐变壁纸、菜单栏与一扇悬浮窗口），其中排列着七个 32pt 的应用图标，间距 8pt。手指沿程序坞滑动时，每个图标的尺寸按照它与手指距离的平滑余弦衰减变化——正下方最大放大到 1.6 倍（上限 2 倍），约 100pt 外回落到 1 倍——一道柔和的放大波随手指移动。图标以共同的底线为基准向上生长，并把相邻图标向两侧推开，磨砂底座随之变宽；若整排将超出屏幕，则按比例压缩额外增量，程序坞永远不会被裁切；运动通过紧致的交互式弹簧（响应约 0.2 秒）跟手。手指下方的图标会在上方弹出名称提示，每次切换时触发选择触觉。松手后一切以更柔和的弹簧回到静止状态。"
        ),
        implementation: L(
            "Icon sizes are computed from the finger's x against each icon's resting centre with a cosine falloff; positions are accumulated manually so the row widens symmetrically. Previews drive the finger with a TimelineView sine sweep.",
            "根据手指 x 与每个图标静止中心的距离，用余弦衰减计算图标尺寸；位置手动累加，使整排对称变宽。预览模式用 TimelineView 的正弦扫动模拟手指。"
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

    private let canvas = CGSize(width: 330, height: 170)

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottom) {
                DockDesktop(language: ctx.language)
                if ctx.isPreview {
                    TimelineView(.animation) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        DockRow(fingerX: canvas.width / 2 + 120 * CGFloat(sin(t * 1.3)), ctx: ctx, canvas: canvas)
                    }
                    .frame(width: canvas.width, height: canvas.height)
                } else {
                    DockRow(fingerX: fingerX, ctx: ctx, canvas: canvas)
                        .frame(width: canvas.width, height: canvas.height)
                        .contentShape(Rectangle())
                        .gesture(drag)
                }
            }
            .frame(width: canvas.width, height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 20, y: 10)
            DemoHint(text: L("Slide along the dock", "沿程序坞滑动手指"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let x = value.location.x
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) { fingerX = x }
                let nearest = DockRow.nearestIndex(to: x, canvasWidth: canvas.width)
                if nearest != hovered {
                    hovered = nearest
                    Haptics.selection()
                }
            }
            .onEnded { _ in
                hovered = nil
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { fingerX = nil }
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
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
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
                    .background(.regularMaterial, in: Capsule())
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
            .padding(.horizontal, 14)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }
}
