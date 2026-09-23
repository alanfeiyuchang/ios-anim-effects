import SwiftUI

extension Effect {
    static let feedbackConnectionBanner = Effect(
        id: "feedback.connection-banner",
        category: .feedback,
        interaction: .state,
        name: L("Connection Status Banner", "网络状态横幅"),
        summary: L(
            "An offline banner pushes the feed down, pulses while reconnecting, then turns green and tucks away.",
            "离线横幅推开内容，重连时信号脉动，恢复后转绿并收起。"
        ),
        prompt: L(
            "When the connection drops, a 46 pt full-width graphite banner (wifi.slash glyph, small 'Retry' capsule) slides down from under the navigation bar, physically pushing the feed below on a spring (response 0.5 s, damping 0.82) while the feed desaturates and fades to 55% so stale content reads as stale. Retrying tints it indigo, lights the Wi-Fi arcs in sequence and cross-fades to 'Reconnecting…'. On success it flushes green, the glyph symbol-replaces into a checkmark and 'Back online' fades in with a success haptic as color returns to the feed; after a short hold the banner retracts and the content glides back up. Honest, calm, self-resolving.",
            "网络一断，一条 46 pt 的石墨色通栏横幅（wifi.slash 图标加小小的“重试”胶囊）从导航栏下滑出，以弹簧（响应 0.5 秒、阻尼 0.82）实打实地把信息流往下推；信息流随即褪色、淡到 55%，过时的内容一眼可辨。点重试，横幅转为靛蓝，Wi-Fi 信号弧依次点亮，文字换成“正在重新连接…”。连上后横幅泛绿，图标以符号替换变成对勾，“已恢复连接”淡入并伴随成功触感，信息流重新上色；稍作停留，横幅收起，内容顺滑回位。坦诚、平静，自行化解。"
        ),
        implementation: L(
            "A four-phase enum drives an if-inserted banner (move-from-top transition inside a clipped VStack so the feed reflows), its background color, a symbol replace + variableColor effect and the feed's saturation; a tokenized Task sequences reconnect → restored → hidden.",
            "四段状态枚举驱动横幅的插入（在裁切的 VStack 中使用自顶部移入的转场，使信息流随之重排）、背景色、符号替换与可变色特效以及信息流的饱和度；带令牌的 Task 依次推进“重连 → 恢复 → 隐藏”。"
        ),
        apis: ["transition(.move(edge:))", "contentTransition(.symbolEffect(.replace))", "symbolEffect(.variableColor)", "saturation"],
        tags: ["offline", "network", "banner", "reconnect", "离线", "网络", "横幅", "重新连接"],
        params: [
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.9, default: 0.5, unit: "s"),
            .slider("hold", L("Success hold", "恢复停留"), 0.6...3.0, default: 1.4, decimals: 1, unit: "s"),
            .toggle("dim", L("Desaturate content", "内容褪色"), default: true),
        ]
    ) { ctx in
        ConnectionBannerDemo(ctx: ctx)
    }
}

private enum LinkPhase: Equatable {
    case online
    case offline
    case reconnecting
    case restored
}

private struct ConnectionBannerDemo: View {
    let ctx: DemoContext
    @State private var phase: LinkPhase = .online
    @State private var token = 0

    private var spring: Animation { .spring(response: ctx["response"], dampingFraction: 0.82) }

    var body: some View {
        let stale = ctx.bool("dim") && (phase == .offline || phase == .reconnecting)
        VStack(spacing: 14) {
            VStack(spacing: 0) {
                header
                if phase != .online {
                    ConnectionBanner(phase: phase, language: ctx.language)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                ConnectionFeed(language: ctx.language)
                    .saturation(stale ? 0 : 1)
                    .opacity(stale ? 0.55 : 1)
            }
            .frame(width: 300, height: 280, alignment: .top)
            .background(Palette.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            .contentShape(Rectangle())
            .onTapGesture { advance() }
            DemoHint(text: L("Tap to drop or restore the connection", "点击断开或恢复网络"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.6) { advance() }
    }

    private var header: some View {
        HStack {
            Text(ctx.language == .zh ? "动态" : "Feed")
                .font(.title3.weight(.bold))
            Spacer()
            Image(systemName: "bell")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(Palette.elevated)
        .zIndex(1)
    }

    private func advance() {
        switch phase {
        case .online:
            token += 1
            if !ctx.isPreview { Haptics.error() }
            withAnimation(spring) { phase = .offline }
        case .offline:
            reconnect()
        case .reconnecting, .restored:
            break
        }
    }

    private func reconnect() {
        token += 1
        let current = token
        let hold = ctx["hold"]
        // Captured now: false inside the silent intro/autoplay, so delayed feedback stays quiet too.
        let buzz: Bool = !ctx.isPreview && !Haptics.isMuted
        let spring = self.spring
        if buzz { Haptics.tap() }
        withAnimation(spring) { phase = .reconnecting }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            guard token == current else { return }
            withAnimation(spring) { phase = .restored }
            if buzz { Haptics.success() }
            try? await Task.sleep(for: .seconds(hold))
            guard token == current else { return }
            withAnimation(spring) { phase = .online }
        }
    }
}

private struct ConnectionBanner: View {
    let phase: LinkPhase
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.variableColor.iterative, isActive: phase == .reconnecting)
                .frame(width: 22)
            Text(title, language)
                .font(.subheadline.weight(.semibold))
                .contentTransition(.interpolate)
            Spacer(minLength: 0)
            if phase == .offline {
                Text(language == .zh ? "重试" : "Retry")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.2), in: Capsule())
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(tint)
    }

    private var symbol: String {
        switch phase {
        case .online, .restored: return "checkmark.circle.fill"
        case .offline: return "wifi.slash"
        case .reconnecting: return "wifi"
        }
    }

    private var title: LocalizedText {
        switch phase {
        case .online, .restored: return L("Back online", "已恢复连接")
        case .offline: return L("No internet connection", "网络连接已断开")
        case .reconnecting: return L("Reconnecting…", "正在重新连接…")
        }
    }

    private var tint: Color {
        switch phase {
        case .online, .restored: return Palette.green
        case .offline: return Color(hex: 0x3A3A3F)
        case .reconnecting: return Palette.indigo
        }
    }
}

private struct ConnectionFeed: View {
    let language: AppLanguage

    private let rows: [(String, [Color], LocalizedText, LocalizedText)] = [
        ("photo.fill", [Palette.amber, Palette.coral], L("Weekend in Kyoto", "京都的周末"), L("24 new photos", "24 张新照片")),
        ("music.note", [Palette.pink, Palette.violet], L("Friday Mix", "周五歌单"), L("Updated by Mia", "米娅更新了歌单")),
        ("figure.run", [Palette.mint, Palette.sky], L("Morning run", "晨跑"), L("5.2 km · 26 min", "5.2 公里 · 26 分钟")),
        ("book.fill", [Palette.indigo, Palette.blue], L("Reading list", "阅读清单"), L("3 articles saved", "收藏了 3 篇文章")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows.count, id: \.self) { index in
                let row = rows[index]
                HStack(spacing: 12) {
                    Image(systemName: row.0)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            LinearGradient(colors: row.1, startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.2, language)
                            .font(.subheadline.weight(.semibold))
                        Text(row.3, language)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
            }
        }
    }
}
