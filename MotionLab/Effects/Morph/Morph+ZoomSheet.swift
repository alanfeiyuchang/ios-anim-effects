import SwiftUI

extension Effect {
    static let morphZoomSheet = Effect(
        id: "morph.zoom-sheet",
        category: .morph,
        interaction: .tap,
        name: L("Sheet from Source", "从按钮长出的面板"),
        summary: L(
            "A share button grows into a floating sheet while the page recedes behind it.",
            "分享按钮生长为悬浮面板，背后页面随之后退。"
        ),
        prompt: L(
            "A 56 pt circular share button floats in the bottom-right corner above a photo page. Tapping it grows the button itself into a floating bottom sheet inset 8 pt from the screen edges with 32 pt continuous corners: position, size and fill (brand indigo → elevated surface) interpolate on a spring (response ≈0.5 s, damping ≈0.84) and the share glyph glides into the sheet header. The page behind scales to 92% from its top edge and dims under a 25% scrim, echoing the iOS card presentation. Sheet rows (contacts, then actions) rise in with a 50 ms stagger. The sheet can be dragged down 1:1 — the scrim and page scale track the drag — and releasing past ~100 pt collapses it back into the button; dragging up rubber-bands.",
            "一张照片页面的右下角悬浮着 56pt 的圆形分享按钮。点击后按钮本身生长为一个距屏幕边缘 8pt、圆角 32pt 的悬浮底部面板：位置、尺寸与填充色（品牌靛蓝 → 浮层表面色）在弹簧（响应约 0.5 秒、阻尼约 0.84）中插值，分享图标平滑滑入面板页眉。背后的页面以顶边为锚点缩小到 92%，并覆上 25% 的暗色遮罩，呼应 iOS 卡片式呈现。面板内容（联系人、操作）以 50 毫秒间隔依次浮现。面板可 1:1 向下拖拽，遮罩与页面缩放随拖拽实时变化；松手超过约 100pt 时收回为按钮，向上拖拽则呈橡皮筋阻尼。"
        ),
        implementation: L(
            "Button and sheet share matchedGeometryEffect ids for their background and icon; a DragGesture offsets the sheet with rubber-banding and feeds a progress value that un-scales the page and fades the scrim.",
            "按钮与面板的背景和图标共享 matchedGeometryEffect ID；DragGesture 带橡皮筋地移动面板，并输出进度值用于恢复页面缩放、淡出遮罩。"
        ),
        apis: ["matchedGeometryEffect", "DragGesture", "scaleEffect(_:anchor:)", "rubber-band", "spring(response:dampingFraction:)"],
        tags: ["sheet", "share", "zoom", "modal", "面板", "分享", "弹出", "底部弹窗"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.84),
            .slider("recede", L("Page scale", "页面缩放"), 0.8...1.0, default: 0.92),
        ]
    ) { ctx in
        ZoomSheetDemo(ctx: ctx)
    }
}

private struct ZoomSheetDemo: View {
    let ctx: DemoContext
    @Namespace private var ns
    @State private var open = false
    @State private var showContent = false
    @State private var dragY: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: ctx["damping"]) }
    private var presence: CGFloat { open ? 1 - min(max(dragY, 0) / 220, 1) : 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            ZoomBackdrop(language: ctx.language)
                .scaleEffect(1 - (1 - ctx.cg("recede")) * presence, anchor: .top)
            Color.black
                .opacity(0.25 * Double(presence))
                .allowsHitTesting(open)
                .onTapGesture { close() }
            if open {
                ShareSheetPanel(ns: ns, language: ctx.language, showContent: showContent, onClose: close)
                    .offset(y: dragY)
                    .gesture(dismissDrag)
                    .onAppear { showContent = true }
                    .onChange(of: dragging) { _, active in
                        // System cancellation skips onEnded: settle the half-dragged sheet back into place.
                        if !active && dragY != 0 { withAnimation(spring) { dragY = 0 } }
                    }
            } else {
                shareButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: open ? .top : .bottomLeading) {
            hint
        }
        .autoplay(ctx.isPreview, every: 2.2) {
            if open { close() } else { present() }
        }
    }

    /// Closed: points at the share button. Open: sits on the photo and explains the hidden drag.
    private var hint: some View {
        DemoHint(
            text: open ? L("Drag the sheet down to close", "向下拖动面板即可关闭") : L("Tap the share button", "点击分享按钮"),
            ctx: ctx
        )
        .environment(\.colorScheme, open ? .dark : colorScheme)
        .padding(.top, open ? 30 : 0)
        .padding(.leading, open ? 0 : 24)
        .padding(.bottom, open ? 0 : 38)
        .opacity(dragY > 4 ? 0 : 1)
        .allowsHitTesting(false)
    }

    private var shareButton: some View {
        Button(action: present) {
            Image(systemName: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(.white)
                .matchedGeometryEffect(id: "icon", in: ns)
                .frame(width: 56, height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Palette.indigo)
                        .matchedGeometryEffect(id: "sheet", in: ns)
                        .shadow(color: Palette.indigo.opacity(0.4), radius: 12, y: 6)
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(20)
    }

    private var dismissDrag: some Gesture {
        DragGesture()
            .updating($dragging) { _, state, _ in state = true }
            .onChanged { value in
                let t = value.translation.height
                dragY = t > 0 ? t : rubberBand(t, limit: 24)
            }
            .onEnded { value in
                if value.translation.height > 100 || value.predictedEndTranslation.height > 260 {
                    close()
                } else {
                    withAnimation(spring) { dragY = 0 }
                }
            }
    }

    private func present() {
        if !ctx.isPreview { Haptics.tap(.medium) }
        withAnimation(spring) {
            dragY = 0
            open = true
        }
    }

    private func close() {
        showContent = false
        withAnimation(spring) {
            open = false
            dragY = 0
        }
    }
}

private struct ShareSheetPanel: View {
    let ns: Namespace.ID
    let language: AppLanguage
    let showContent: Bool
    let onClose: () -> Void

    private let contacts: [(String, Color)] = [("AL", Palette.pink), ("MJ", Palette.amber), ("SK", Palette.mint), ("YU", Palette.sky)]
    private let actions: [String] = ["doc.on.doc", "bookmark", "printer", "ellipsis"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
            header
            HStack(spacing: 0) {
                ForEach(0..<contacts.count, id: \.self) { index in
                    Text(contacts[index].0)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(contacts[index].1.gradient, in: Circle())
                        .frame(maxWidth: .infinity)
                }
            }
            .modifier(SheetRowReveal(visible: showContent, delay: 0.1))
            HStack(spacing: 0) {
                ForEach(actions, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.headline)
                        .frame(width: 52, height: 44)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .frame(maxWidth: .infinity)
                }
            }
            .modifier(SheetRowReveal(visible: showContent, delay: 0.15))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Palette.elevated)
                .matchedGeometryEffect(id: "sheet", in: ns)
                .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
        }
        .padding(8)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(Palette.indigo)
                .matchedGeometryEffect(id: "icon", in: ns)
            Text(language == .zh ? "分享照片" : "Share photo")
                .font(.headline)
                .modifier(SheetRowReveal(visible: showContent, delay: 0.05))
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .modifier(SheetRowReveal(visible: showContent, delay: 0.05))
        }
    }
}

private struct ZoomBackdrop: View {
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.sunset)
                .overlay {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(height: 150)
            VStack(alignment: .leading, spacing: 4) {
                Text(language == .zh ? "海边日落" : "Sunset over the bay")
                    .font(.headline)
                Text(language == .zh ? "9 月 12 日 · 18:42 · 旧金山" : "Sep 12 · 6:42 PM · San Francisco")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(language == .zh ? "云层压得很低，最后一缕光把整片海湾染成了琥珀色。" : "Low clouds, and the last light turned the whole bay amber.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SheetRowReveal: ViewModifier {
    let visible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 12)
            .animation(visible ? .spring(response: 0.45, dampingFraction: 0.86).delay(delay) : .easeOut(duration: 0.1), value: visible)
    }
}
