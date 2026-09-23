import SwiftUI

extension Effect {
    static let navigationSideDrawer = Effect(
        id: "navigation.side-drawer-3d",
        category: .navigation,
        interaction: .gesture,
        name: L("3D Side Drawer", "3D 侧边抽屉"),
        summary: L(
            "The page slides aside, shrinks and turns in 3D to reveal a navigation drawer.",
            "页面向侧边滑开、缩小并三维转动，露出导航抽屉。"
        ),
        prompt: L(
            "A phone-sized page sits over a deep indigo drawer. Tapping the ☰ menu button — or dragging right from anywhere — slides the page ~150 pt to the right while it scales to 82%, rounds its corners to 26 pt and rotates about 12° around the vertical axis (perspective ≈0.6) so its far edge recedes, with a softer ghost copy trailing behind for depth. Everything is driven by one 0–1 progress value that follows the finger 1:1 and, on release, springs (response ≈0.45 s, damping ≈0.82) to open or closed based on fling velocity. Drawer items slide in from 20 pt left and fade up in a cascade as progress passes each one's threshold. Spatial, layered and silky.",
            "一个手机尺寸的页面覆盖在深靛蓝色的抽屉之上。点击 ☰ 菜单按钮或在任意位置向右拖拽时，页面向右滑开约 150pt，同时缩小到 82%、圆角变为 26pt，并绕竖直轴旋转约 12°（透视约 0.6），使远端边缘向后退去；后方还跟随一层更淡的页面「残影」增强纵深。一切由一个 0–1 的进度值驱动：拖拽时 1:1 跟手，松手后根据甩动速度以弹簧（响应约 0.45 秒、阻尼约 0.82）吸附到打开或关闭。抽屉菜单项随进度越过各自阈值，从左侧 20pt 处依次滑入并淡入。空间感强、层次分明、丝般顺滑。"
        ),
        implementation: L(
            "A single progress value (driven by DragGesture or a spring) feeds offset, scaleEffect, rotation3DEffect and corner radius of the page plus per-item opacity ramps in the drawer.",
            "单一进度值（由 DragGesture 或弹簧驱动）同时映射页面的位移、缩放、rotation3DEffect 与圆角，以及抽屉中每一项的透明度渐变。"
        ),
        apis: ["rotation3DEffect", "DragGesture", "predictedEndTranslation", "scaleEffect", "clipShape"],
        tags: ["drawer", "side menu", "hamburger", "3d", "抽屉", "侧边菜单", "汉堡菜单", "三维"],
        params: [
            .slider("angle", L("Rotation", "旋转角度"), 0...30, default: 12, decimals: 0, unit: "°"),
            .slider("scale", L("Page scale", "页面缩放"), 0.6...1.0, default: 0.82),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.45, unit: "s"),
        ]
    ) { ctx in
        SideDrawerDemo(ctx: ctx)
    }
}

private let drawerItems: [(String, LocalizedText)] = [
    ("house.fill", L("Home", "首页")),
    ("tray.full.fill", L("Inbox", "收件箱")),
    ("star.fill", L("Starred", "星标")),
    ("chart.bar.fill", L("Insights", "洞察")),
    ("gearshape.fill", L("Settings", "设置")),
]

private struct SideDrawerDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var dragStart: CGFloat?

    private let travel: CGFloat = 150

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(hex: 0x1A1F4D), Color(hex: 0x3B2A7A)], startPoint: .topLeading, endPoint: .bottomTrailing)
                DrawerMenu(progress: progress, language: ctx.language)
                page(ghost: true)
                page(ghost: false)
            }
            .frame(width: 250, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            .contentShape(Rectangle())
            .gesture(drag)
            DemoHint(text: L("Tap ☰ or drag right to open the menu", "点击 ☰ 或向右拖动打开菜单"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { toggle() }
    }

    private func page(ghost: Bool) -> some View {
        let p: CGFloat = progress.clamped(to: -0.1...1.1)
        let depth: CGFloat = ghost ? 0.7 : 1
        let scale: CGFloat = 1 - (1 - ctx.cg("scale")) * p * (ghost ? 1.18 : 1)
        let shown: CGFloat = p.clamped(to: 0...1)
        let radius: CGFloat = 26 * shown + 1
        let alpha: Double = ghost ? 0.35 * Double(shown) : 1
        let shadowAlpha: Double = ghost ? 0 : 0.3 * Double(shown)
        let degrees: Double = ctx["angle"] * Double(p) * Double(depth)
        return DrawerPage(ctx: ctx, onMenu: toggle)
            .allowsHitTesting(!ghost)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .opacity(alpha)
            .shadow(color: .black.opacity(shadowAlpha), radius: 24, x: -6, y: 10)
            .scaleEffect(scale)
            .rotation3DEffect(
                .degrees(degrees),
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.6
            )
            .offset(x: travel * p * depth)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let start = dragStart ?? progress
                if dragStart == nil { dragStart = progress }
                let raw = start + value.translation.width / travel
                if raw > 1 {
                    progress = 1 + rubberBand((raw - 1) * travel, limit: 30) / travel
                } else if raw < 0 {
                    progress = rubberBand(raw * travel, limit: 20) / travel
                } else {
                    progress = raw
                }
            }
            .onEnded { value in
                let start = dragStart ?? progress
                dragStart = nil
                let projected = start + value.predictedEndTranslation.width / travel
                settle(open: projected > 0.5)
            }
    }

    private func toggle() {
        settle(open: progress < 0.5)
    }

    private func settle(open: Bool) {
        if !ctx.isPreview { Haptics.tap(open ? .medium : .light) }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.82)) {
            progress = open ? 1 : 0
        }
    }
}

/// Animatable so each frame of the open/close spring re-evaluates the per-row thresholds,
/// which keeps the cascade visible on taps and autoplay, not only while dragging.
private struct DrawerMenu: View, Animatable {
    var progress: CGFloat
    let language: AppLanguage

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Palette.sunset)
                    .frame(width: 38, height: 38)
                    .overlay(Text(verbatim: "A").font(.headline).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: "Alex Chen").font(.subheadline.weight(.semibold))
                    Text(language == .zh ? "专业版" : "Pro plan").font(.caption).opacity(0.6)
                }
            }
            .modifier(DrawerItemReveal(progress: progress, index: 0))
            ForEach(0..<drawerItems.count, id: \.self) { index in
                Label(drawerItems[index].1(language), systemImage: drawerItems[index].0)
                    .font(.subheadline.weight(.medium))
                    .opacity(index == 0 ? 1 : 0.75)
                    .modifier(DrawerItemReveal(progress: progress, index: index + 1))
            }
        }
        .foregroundStyle(.white)
        .padding(.leading, 24)
        .padding(.top, 24)
    }
}

private struct DrawerItemReveal: ViewModifier {
    let progress: CGFloat
    let index: Int

    func body(content: Content) -> some View {
        let start = 0.15 + CGFloat(index) * 0.08
        let local = ((progress - start) / 0.45).clamped(to: 0...1)
        return content
            .opacity(Double(local))
            .offset(x: -20 * (1 - local))
    }
}

private struct DrawerPage: View {
    let ctx: DemoContext
    let onMenu: () -> Void

    private var language: AppLanguage { ctx.language }
    private var agenda: [(String, Color, LocalizedText, String)] {
        [
            ("person.2.fill", Palette.violet, L("Design review", "设计评审"), "10:00"),
            ("paperplane.fill", Palette.sky, L("Ship motion specs", "发布动效规范"), "14:30"),
            ("figure.run", Palette.coral, L("Evening run", "傍晚跑步"), "18:00"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onMenu) {
                    Image(systemName: "line.3.horizontal")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .background(Color.primary.opacity(0.07), in: Circle())
                }
                .buttonStyle(.plain)
                Text(language == .zh ? "首页" : "Home")
                    .font(.headline)
                Spacer()
            }
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.aurora)
                .frame(height: 90)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language == .zh ? "早上好，Alex" : "Good morning, Alex")
                            .font(.headline)
                        Text(language == .zh ? "今天有 3 项安排" : "3 things on today")
                            .font(.caption.weight(.medium))
                            .opacity(0.85)
                    }
                    .foregroundStyle(.white)
                    .padding(14)
                }
            VStack(spacing: 10) {
                ForEach(0..<agenda.count, id: \.self) { index in
                    agendaRow(agenda[index])
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
    }

    private func agendaRow(_ item: (String, Color, LocalizedText, String)) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.0)
                .font(.caption.weight(.semibold))
                .foregroundStyle(item.1)
                .frame(width: 28, height: 28)
                .background(item.1.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(item.2, language)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(verbatim: item.3)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
