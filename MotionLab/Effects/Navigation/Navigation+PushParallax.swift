import SwiftUI

extension Effect {
    static let navigationPushParallax = Effect(
        id: "navigation.push-parallax",
        category: .navigation,
        interaction: .gesture,
        name: L("Parallax Push & Swipe Back", "视差推入与侧滑返回"),
        summary: L(
            "A detail page slides over the list with parallax, and a swipe drags it back 1:1.",
            "详情页带视差覆盖列表推入，右滑即可 1:1 拖回。"
        ),
        prompt: L(
            "The iOS navigation push, done properly. Tapping a settings row slides the detail page in from the right edge while the list underneath moves only 30% as far to the left and dims by 12% — two speeds of motion that read as depth — and the incoming page casts a soft shadow along its leading edge. The large 'Settings' title fades out as the detail's '‹ Settings' back label slides in at 40% of the page's speed. The transition is a critically damped spring (response ≈0.5 s, no overshoot). Swiping right anywhere on the detail page (as in iOS 26) drags it back 1:1 with the finger, the parallax, dimming and shadow all tracking live; releasing with enough projected travel completes the pop, otherwise it springs back into place.",
            "把 iOS 导航推入做到位。点击设置列表中的一行，详情页从右边缘滑入；下方列表只向左移动其 30% 的距离并变暗 12%——两种速度的运动营造出纵深——推入的页面沿左边缘投下柔和阴影。大标题“设置”淡出，详情页的“‹ 设置”返回标签以页面 40% 的速度滑入。转场使用临界阻尼弹簧（响应约 0.5 秒、无过冲）。在详情页任意位置向右滑动（与 iOS 26 一致），页面 1:1 跟手拖回，视差、压暗与阴影全程实时联动；松手时若预测位移足够就完成返回，否则弹回原位。"
        ),
        implementation: L(
            "One 0–1 progress value drives the detail offset, the list's parallax offset and dim overlay, the edge shadow and both title labels; a DragGesture writes progress directly and predictedEndTranslation decides the outcome, animated with a dampingFraction 1 spring.",
            "单一 0–1 进度值驱动详情页位移、列表的视差位移与压暗层、边缘阴影以及两个标题标签；DragGesture 直接写入进度，由 predictedEndTranslation 决定结果，并以 dampingFraction 为 1 的弹簧完成动画。"
        ),
        apis: ["DragGesture", "predictedEndTranslation", "offset(x:)", "spring(response:dampingFraction:)", "shadow"],
        tags: ["navigation", "push", "swipe back", "parallax", "导航", "推入", "侧滑返回", "视差"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.9, default: 0.5, unit: "s"),
            .slider("parallax", L("Underlay parallax", "底层视差"), 0...0.6, default: 0.3),
            .slider("dim", L("Underlay dim", "底层压暗"), 0...0.35, default: 0.12),
        ]
    ) { ctx in
        PushParallaxDemo(ctx: ctx)
    }
}

private struct PushItem {
    let symbol: String
    let color: Color
    let title: LocalizedText
    let detail: LocalizedText
}

private let pushItems: [PushItem] = [
    PushItem(symbol: "wifi", color: Palette.blue, title: L("Wi-Fi", "无线局域网"), detail: L("Studio 5G", "Studio 5G")),
    PushItem(symbol: "bell.badge.fill", color: Palette.red, title: L("Notifications", "通知"), detail: L("Banners, sounds", "横幅、声音")),
    PushItem(symbol: "moon.fill", color: Palette.indigo, title: L("Focus", "专注模式"), detail: L("Off", "关闭")),
    PushItem(symbol: "paintpalette.fill", color: Palette.pink, title: L("Appearance", "外观"), detail: L("Automatic", "自动")),
]

private struct PushParallaxDemo: View {
    let ctx: DemoContext
    @State private var progress: CGFloat = 0
    @State private var selected = 0
    @State private var previewStep = 0
    @State private var token = 0

    private let size = CGSize(width: 300, height: 320)
    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: 1) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                PushListScreen(progress: progress, language: ctx.language, onSelect: push)
                    .offset(x: -size.width * ctx.cg("parallax") * progress)
                    .overlay {
                        Color.black
                            .opacity(ctx["dim"] * Double(progress))
                            .allowsHitTesting(false)
                    }
                PushDetailScreen(item: pushItems[selected], progress: progress, width: size.width, language: ctx.language, onBack: pop)
                    .shadow(color: .black.opacity(0.2 * Double(progress)), radius: 14, x: -3)
                    .offset(x: size.width * (1 - progress))
                    .gesture(backSwipe)
                    .allowsHitTesting(progress > 0.01)
            }
            .frame(width: size.width, height: size.height)
            .background(Palette.surface)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            DemoHint(text: L("Tap a row, then swipe right to go back", "点击一行，再向右滑返回"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6) { previewAdvance() }
    }

    private var backSwipe: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                progress = 1 - min(max(value.translation.width, 0) / size.width, 1)
            }
            .onEnded { value in
                if value.predictedEndTranslation.width > size.width * 0.5 {
                    pop()
                } else {
                    withAnimation(spring) { progress = 1 }
                }
            }
    }

    private func push(_ index: Int) {
        if !ctx.isPreview { Haptics.tap() }
        selected = index
        withAnimation(spring) { progress = 1 }
    }

    private func pop() {
        if !ctx.isPreview { Haptics.tap(.soft) }
        withAnimation(spring) { progress = 0 }
    }

    /// Previews alternate a push with a simulated half swipe that then completes.
    private func previewAdvance() {
        if previewStep % 2 == 0 {
            push((previewStep / 2) % pushItems.count)
        } else {
            withAnimation(.easeOut(duration: 0.35)) { progress = 0.55 }
            token += 1
            let current = token
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                guard token == current else { return }
                pop()
            }
        }
        previewStep += 1
    }
}

private struct PushListScreen: View {
    let progress: CGFloat
    let language: AppLanguage
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(language == .zh ? "设置" : "Settings")
                .font(.largeTitle.weight(.bold))
                .opacity(Double(1 - progress))
                .padding(.horizontal, 20)
                .padding(.top, 18)
            VStack(spacing: 0) {
                ForEach(0..<pushItems.count, id: \.self) { index in
                    Button { onSelect(index) } label: {
                        row(pushItems[index])
                    }
                    .buttonStyle(PushRowStyle())
                    if index < pushItems.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 14)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.surface)
    }

    private func row(_ item: PushItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(item.color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(item.title, language)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: 4)
            Text(item.detail, language)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .contentShape(Rectangle())
    }
}

private struct PushRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.primary.opacity(configuration.isPressed ? 0.08 : 0))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct PushDetailScreen: View {
    let item: PushItem
    let progress: CGFloat
    let width: CGFloat
    let language: AppLanguage
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onBack) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text(language == .zh ? "设置" : "Settings")
                        .font(.body)
                }
                .foregroundStyle(Palette.indigo)
                .frame(height: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // The back label travels at 40% of the page's speed, so it appears to slide out of the old title.
            .offset(x: -width * 0.6 * (1 - progress))
            .opacity(Double(progress))
            VStack(spacing: 10) {
                Image(systemName: item.symbol)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(item.color.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: item.color.opacity(0.35), radius: 12, y: 6)
                Text(item.title, language)
                    .font(.title3.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 0) {
                settingRow(language == .zh ? "开启" : "Enabled", on: true)
                Divider().padding(.leading, 14)
                settingRow(language == .zh ? "在锁定屏幕显示" : "Show on Lock Screen", on: false)
            }
            .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.surface)
        .contentShape(Rectangle())
    }

    private func settingRow(_ title: String, on: Bool) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Capsule()
                .fill(on ? Palette.green : Color.primary.opacity(0.12))
                .frame(width: 44, height: 26)
                .overlay(alignment: on ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                        .padding(2)
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
    }
}
