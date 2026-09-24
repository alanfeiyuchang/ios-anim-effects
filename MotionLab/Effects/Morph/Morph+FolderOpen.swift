import SwiftUI

extension Effect {
    static let morphFolderOpen = Effect(
        id: "morph.folder-open",
        category: .morph,
        interaction: .tap,
        name: L("Folder Zoom", "文件夹展开"),
        summary: L(
            "A home-screen folder swells into a glass panel as its mini icons grow into full apps.",
            "主屏文件夹膨胀为玻璃面板，内部迷你图标长成完整应用。"
        ),
        prompt: L(
            "A home screen of 56 pt app icons on an indigo-to-pink wallpaper; the center cell is a frosted folder holding a 2 × 2 cluster of 20 pt mini icons. Tapping it grows the glass tile into a 212 pt panel with 34 pt continuous corners at screen center while each mini icon travels and scales into a full 58 pt app in the same 2 × 2 layout, all on one matched-geometry spring (response 0.48 s, damping 0.8). The folder name fades in above and app labels rise beneath their icons. Behind, the other icons recede to 88%, blur 6 pt and fade to 45% as the wallpaper dims 15%. Tapping outside shrinks the apps back into the tile. Spatial, tactile, unmistakably iOS.",
            "靛蓝到粉色壁纸上排着 56 pt 应用图标，正中是一个磨砂文件夹，内含 2 × 2 的 20 pt 迷你图标。点一下，玻璃图块在屏幕中央长成 212 pt、34 pt 连续圆角的面板，每个迷你图标同时飞出并放大成 58 pt 的完整应用，仍保持 2 × 2 排列，全部乘同一条几何匹配弹簧（响应 0.48 秒、阻尼 0.8）一起运动。文件夹名在上方淡入，应用名从图标下浮现。背后的图标缩到 88%、模糊 6 pt、淡至 45%，壁纸压暗 15%。点空白处，应用又缩回图块。有空间感和手感，一眼就是 iOS。"
        ),
        implementation: L(
            "The folder tile and the open panel are exclusive views sharing a matchedGeometryEffect id for the material background plus one id per app; icons are resizable shapes and symbols with the matched effect applied before their frames, so both position and size interpolate.",
            "文件夹图块与展开面板互斥显示，材质背景共享一个 matchedGeometryEffect ID，每个应用各有一个 ID；图标由可缩放的形状与 resizable 符号构成，且匹配效果放在 frame 之前，因此位置与尺寸都会插值。"
        ),
        apis: ["matchedGeometryEffect", "@Namespace", "ultraThinMaterial", "Image.resizable()", "blur(radius:)"],
        tags: ["folder", "home screen", "zoom", "springboard", "文件夹", "主屏幕", "放大", "图标"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.48, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.8),
            .toggle("recede", L("Recede other icons", "其他图标后退"), default: true),
        ]
    ) { ctx in
        FolderOpenDemo(ctx: ctx)
    }
}

private struct HomeApp {
    let symbol: String
    let colors: [Color]
    let name: LocalizedText
}

/// The eight regular apps around the folder (the folder sits in the center cell).
private let homeApps: [HomeApp] = [
    HomeApp(symbol: "message.fill", colors: [Palette.green, Palette.mint], name: L("Messages", "信息")),
    HomeApp(symbol: "safari.fill", colors: [Palette.sky, Palette.blue], name: L("Safari", "Safari")),
    HomeApp(symbol: "music.note", colors: [Palette.pink, Palette.red], name: L("Music", "音乐")),
    HomeApp(symbol: "photo.fill", colors: [Palette.amber, Palette.coral], name: L("Photos", "照片")),
    HomeApp(symbol: "calendar", colors: [Palette.red, Palette.coral], name: L("Calendar", "日历")),
    HomeApp(symbol: "map.fill", colors: [Palette.mint, Palette.green], name: L("Maps", "地图")),
    HomeApp(symbol: "note.text", colors: [Palette.amber, Color(hex: 0xFFD66B)], name: L("Notes", "备忘录")),
    HomeApp(symbol: "gearshape.fill", colors: [Color(hex: 0x8E8E93), Color(hex: 0x5A5A60)], name: L("Settings", "设置")),
]

private let folderApps: [HomeApp] = [
    HomeApp(symbol: "paintbrush.pointed.fill", colors: [Palette.violet, Palette.pink], name: L("Sketch", "草图")),
    HomeApp(symbol: "camera.aperture", colors: [Palette.indigo, Palette.sky], name: L("Lens", "镜头")),
    HomeApp(symbol: "wand.and.stars", colors: [Palette.pink, Palette.coral], name: L("Motion", "动效")),
    HomeApp(symbol: "scribble.variable", colors: [Palette.mint, Palette.sky], name: L("Ink", "墨迹")),
]

private struct FolderOpenDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var open = false

    private let screen = CGSize(width: 316, height: 316)

    var body: some View {
        let recede = open && ctx.bool("recede")
        let shape = RoundedRectangle(cornerRadius: 38, style: .continuous)
        VStack(spacing: 14) {
            ZStack {
                FolderWallpaper()
                Color.black
                    .opacity(open ? 0.15 : 0)
                homeGrid
                    .scaleEffect(recede ? 0.88 : 1)
                    .blur(radius: recede ? 6 : 0)
                    .opacity(recede ? 0.45 : 1)
                if open {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { setOpen(false) }
                    openPanel
                }
            }
            .frame(width: screen.width, height: screen.height)
            .clipShape(shape)
            .shadow(color: Color(hex: 0x4B3AA8).opacity(0.28), radius: 24, y: 14)
            DemoHint(text: L("Tap the folder", "点击文件夹"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { setOpen(!open) }
    }

    // MARK: Closed grid

    private var homeGrid: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { column in
                        cell(row * 3 + column)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ slot: Int) -> some View {
        if slot == 4 {
            VStack(spacing: 5) {
                if open {
                    Color.clear.frame(width: 56, height: 56)
                } else {
                    folderTile
                }
                label(ctx.language == .zh ? "创作" : "Create")
                    .opacity(open ? 0 : 1)
            }
            .frame(width: 80)
        } else {
            let app = homeApps[slot < 4 ? slot : slot - 1]
            VStack(spacing: 5) {
                FolderAppIcon(app: app, radius: 13)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                label(app.name(ctx.language))
            }
            .frame(width: 80)
        }
    }

    private var folderTile: some View {
        ZStack {
            DemoMaterial(RoundedRectangle(cornerRadius: 14, style: .continuous), material: .ultraThinMaterial)
                .matchedGeometryEffect(id: "folder", in: ns)
            VStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<2, id: \.self) { column in
                            let index = row * 2 + column
                            FolderAppIcon(app: folderApps[index], radius: 5)
                                .matchedGeometryEffect(id: "app-\(index)", in: ns)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .frame(width: 56, height: 56)
        .contentShape(Rectangle())
        .onTapGesture { setOpen(true) }
    }

    // MARK: Open panel

    private var openPanel: some View {
        VStack(spacing: 14) {
            Text(ctx.language == .zh ? "创作" : "Create")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            ZStack {
                DemoMaterial(RoundedRectangle(cornerRadius: 34, style: .continuous), material: .ultraThinMaterial)
                    .matchedGeometryEffect(id: "folder", in: ns)
                VStack(spacing: 14) {
                    ForEach(0..<2, id: \.self) { row in
                        HStack(spacing: 26) {
                            ForEach(0..<2, id: \.self) { column in
                                panelApp(row * 2 + column)
                            }
                        }
                    }
                }
            }
            .frame(width: 212, height: 212)
        }
    }

    private func panelApp(_ index: Int) -> some View {
        VStack(spacing: 6) {
            FolderAppIcon(app: folderApps[index], radius: 14)
                .matchedGeometryEffect(id: "app-\(index)", in: ns)
                .frame(width: 58, height: 58)
                .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
            label(folderApps[index].name(ctx.language))
                .transition(.opacity.combined(with: .offset(y: 6)))
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }

    private func setOpen(_ value: Bool) {
        guard value != open else { return }
        if !ctx.isPreview { Haptics.tap(value ? .medium : .light) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            open = value
        }
    }
}

/// A resizable app icon: gradient squircle plus a symbol that scales with its frame.
private struct FolderAppIcon: View {
    let app: HomeApp
    let radius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(LinearGradient(colors: app.colors, startPoint: .top, endPoint: .bottom))
            .overlay {
                Image(systemName: app.symbol)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .scaleEffect(0.5)
            }
    }
}

private struct FolderWallpaper: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1D2671), Color(hex: 0x6E4BD8), Color(hex: 0xE86BB0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(colors: [Palette.amber.opacity(0.45), .clear], center: UnitPoint(x: 0.85, y: 0.9), startRadius: 0, endRadius: 220)
            RadialGradient(colors: [.white.opacity(0.22), .clear], center: UnitPoint(x: 0.15, y: 0.1), startRadius: 0, endRadius: 200)
        }
    }
}
