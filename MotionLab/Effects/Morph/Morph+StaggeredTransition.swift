import SwiftUI

extension Effect {
    static let morphStaggeredTransition = Effect(
        id: "morph.staggered-transition",
        category: .morph,
        interaction: .tap,
        name: L("Staggered Transition", "错峰转场"),
        summary: L(
            "A custom Transition cascades notifications in and folds them away in reverse.",
            "自定义 Transition 让通知依次浮现，并按相反顺序收起。"
        ),
        prompt: L(
            "A stack of four notification cards appears one after another: each card rises from 24 pt below, scales up from 92% anchored at its top edge and sharpens from an 8 pt blur while fading in, on a spring (response ≈0.5 s, damping ≈0.82) with 60 ms between cards, so the list pours down like a waterfall. Dismissing plays the same transition in reverse order — the last card leaves first, drifting up 12 pt with a quicker ease-in (≈220 ms) and a tighter 35 ms stagger — so exits feel faster than entrances. The trigger button's label morphs between states with an interpolated text transition. Calm, orderly and premium, like a well-rehearsed reveal.",
            "四张通知卡片依次出现：每张从下方 24pt 处上升，以顶边为锚点从 92% 放大，同时从 8pt 模糊变清晰并淡入；采用弹簧（响应约 0.5 秒、阻尼约 0.82），相邻卡片间隔 60 毫秒，整列像瀑布一样倾泻而下。收起时按相反顺序播放同一转场——最后一张先离开，向上漂移 12pt，使用更快的缓入曲线（约 220 毫秒）和更紧凑的 35 毫秒错开，让退出比进入更利落。触发按钮的文字随之切换。整体从容、有序、高级，像一场排练精准的揭幕。"
        ),
        implementation: L(
            "A struct conforming to the Transition protocol reads TransitionPhase to apply offset, scale, blur and opacity; each row wraps it in an asymmetric AnyTransition whose insertion and removal carry index-based delays.",
            "遵循 Transition 协议的结构体读取 TransitionPhase 应用位移、缩放、模糊与透明度；每一行用非对称 AnyTransition 包装，插入与移除分别携带基于索引的延迟。"
        ),
        apis: ["Transition", "TransitionPhase", "AnyTransition.asymmetric", "AnyTransition.animation(_:)", "ForEach"],
        tags: ["transition", "stagger", "cascade", "notifications", "转场", "错开", "级联", "通知"],
        params: [
            .slider("stagger", L("Stagger", "错开间隔"), 0.0...0.15, default: 0.06, decimals: 3, unit: "s"),
            .slider("distance", L("Rise distance", "上升距离"), 0...60, default: 24, decimals: 0, unit: "pt"),
            .slider("response", L("Spring response", "弹簧响应"), 0.2...1.0, default: 0.5, unit: "s"),
        ]
    ) { ctx in
        StaggeredTransitionDemo(ctx: ctx)
    }
}

private struct Notice {
    let symbol: String
    let color: Color
    let app: LocalizedText
    let message: LocalizedText
}

private let notices: [Notice] = [
    Notice(symbol: "message.fill", color: Palette.green, app: L("Messages", "信息"), message: L("Lunch at 12:30?", "12:30 一起吃午饭？")),
    Notice(symbol: "calendar", color: Palette.red, app: L("Calendar", "日历"), message: L("Design review in 15 min", "15 分钟后设计评审")),
    Notice(symbol: "figure.run", color: Palette.coral, app: L("Fitness", "健身"), message: L("Close your move ring", "完成今天的活动圆环")),
    Notice(symbol: "creditcard.fill", color: Palette.indigo, app: L("Wallet", "钱包"), message: L("Payment received", "已收到一笔付款")),
]

/// Rises, scales up and un-blurs on insertion; drifts up on removal.
private struct RiseTransition: Transition {
    var distance: CGFloat

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 8)
            .scaleEffect(phase.isIdentity ? 1 : 0.92, anchor: .top)
            .offset(y: offset(for: phase))
    }

    private func offset(for phase: TransitionPhase) -> CGFloat {
        switch phase {
        case .willAppear: return distance
        case .didDisappear: return -distance * 0.5
        default: return 0
        }
    }
}

private struct StaggeredTransitionDemo: View {
    let ctx: DemoContext
    @State private var shown = false

    private var visible: [Int] { shown ? Array(notices.indices) : [] }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                ForEach(visible, id: \.self) { index in
                    NoticeRow(notice: notices[index], language: ctx.language)
                        .transition(transition(for: index))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            Button(action: toggle) {
                Text(shown ? (ctx.language == .zh ? "全部清除" : "Clear all") : (ctx.language == .zh ? "显示通知" : "Show notifications"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.interpolate)
                    .padding(.horizontal, 20)
                    .frame(height: 42)
                    .background(Palette.primary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.0, delay: 0.3) { toggle() }
    }

    private func transition(for index: Int) -> AnyTransition {
        let rise = RiseTransition(distance: ctx.cg("distance"))
        let inDelay = Double(index) * ctx["stagger"]
        let outDelay = Double(notices.count - 1 - index) * ctx["stagger"] * 0.6
        return .asymmetric(
            insertion: AnyTransition(rise).animation(.spring(response: ctx["response"], dampingFraction: 0.82).delay(inDelay)),
            removal: AnyTransition(rise).animation(.easeIn(duration: 0.22).delay(outDelay))
        )
    }

    private func toggle() {
        if !ctx.isPreview { Haptics.tap() }
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.82)) {
            shown.toggle()
        }
    }
}

private struct NoticeRow: View {
    let notice: Notice
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notice.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(notice.color.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(notice.app, language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(notice.message, language)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(language == .zh ? "刚刚" : "now")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
