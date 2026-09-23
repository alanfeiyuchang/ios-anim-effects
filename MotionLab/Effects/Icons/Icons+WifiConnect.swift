import SwiftUI

extension Effect {
    static let iconsWifiConnect = Effect(
        id: "icons.wifi-connect",
        category: .icons,
        interaction: .tap,
        name: L("Wi-Fi Connect", "Wi-Fi 连接"),
        summary: L("Arcs chase outward while searching, then pop into place with a check badge.", "搜索时信号弧由内向外追逐，连上后逐层弹出并出现对勾角标。"),
        prompt: L(
            "A large Wi-Fi glyph (a dot and three concentric 90° arcs in 7 pt round-capped strokes) sits above a network name and a status line, its arcs 15% grey while off. Tapping starts a search: the arcs light blue from the inside out, one every 180 ms, then reset, a chase that repeats until the connection lands 1.8 s later. On connect all three arcs turn solid blue and pop from 88% to 100% on a bouncy spring (response 0.35 s, damping 0.45), anchored at the dot and staggered 60 ms outward, while a green check badge scales in at the top-right and the status rolls to “Connected” with a success haptic. Tapping again disconnects and the arcs fade back to grey. Clear, systemic and satisfying.",
            "一个大号Wi-Fi图标（一个圆点加三道同心90°圆弧，7 pt圆头描边）下方是网络名和状态文字，关闭时圆弧为15%灰。点击开始搜索：圆弧由内向外依次亮成蓝色，每180毫秒一道，然后全部熄灭，循环追逐，直到1.8秒后连上。连接成功时三道圆弧全部变成实心蓝，以圆点为锚点从88%弹到100%（弹簧响应0.35秒、阻尼0.45），由内向外错开60毫秒；右上角绿色对勾角标弹出，状态滚动为「已连接」，伴随成功触感。再点一次断开，圆弧淡回灰色。清晰、系统、令人满足。"
        ),
        implementation: L(
            "Each arc is a Shape stroked with round caps; a TimelineView computes the chase index while searching, and on connect every arc's scaleEffect(anchor:) animates with a per-arc delayed spring; the badge uses a scale transition and the status text .contentTransition(.numericText()).",
            "每道圆弧都是一个圆头描边的 Shape；搜索时由 TimelineView 计算追逐序号，连接时每道圆弧的 scaleEffect(anchor:) 以逐弧延迟的弹簧动画；角标使用缩放过渡，状态文字使用 .contentTransition(.numericText())。"
        ),
        apis: ["Shape", "Path.addArc", "TimelineView", "scaleEffect(_:anchor:)", "transition(.scale)"],
        tags: ["wifi", "connect", "signal", "status", "无线网络", "连接", "信号", "状态"],
        params: [
            .slider("chase", L("Chase step", "追逐间隔"), 0.08...0.4, default: 0.18, unit: "s"),
            .slider("search", L("Search time", "搜索时长"), 0.6...4.0, default: 1.8, unit: "s"),
            .slider("damping", L("Pop damping", "弹出阻尼"), 0.3...1.0, default: 0.45),
        ]
    ) { ctx in
        WifiConnectDemo(ctx: ctx)
    }
}

private enum WifiState: Equatable {
    case off
    case searching
    case connected
}

/// One arc of the Wi-Fi fan, centred on the dot at the bottom of the rect.
private struct WifiArc: Shape {
    let level: Int

    func path(in rect: CGRect) -> Path {
        let origin = CGPoint(x: rect.midX, y: rect.maxY - 8)
        let step: CGFloat = (rect.height - 16) / 3
        let radius: CGFloat = step * CGFloat(level + 1)
        var path = Path()
        path.addArc(center: origin, radius: radius, startAngle: .degrees(225), endAngle: .degrees(315), clockwise: false)
        return path
    }
}

private struct WifiConnectDemo: View {
    let ctx: DemoContext
    @State private var state: WifiState
    @State private var token = 0

    init(ctx: DemoContext) {
        self.ctx = ctx
        // On the detail stage start disconnected, so the intro tap plays search → connect → badge pop.
        _state = State(initialValue: ctx.isPreview || ctx.isStill ? .connected : .off)
    }

    var body: some View {
        VStack(spacing: 18) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: state != .searching)) { timeline in
                glyph(chase: chaseCount(timeline.date))
            }
            labels
            DemoHint(text: L("Tap to connect / disconnect", "点击连接 / 断开"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { tap() }
        .autoplay(ctx.isPreview, every: 3.2) { tap() }
    }

    private func chaseCount(_ date: Date) -> Int {
        guard state == .searching else { return state == .connected ? 3 : 0 }
        let step: Double = max(ctx["chase"], 0.02)
        return Int(date.timeIntervalSinceReferenceDate / step) % 4
    }

    private func glyph(chase: Int) -> some View {
        ZStack(alignment: .bottom) {
            ForEach(0..<3, id: \.self) { level in
                WifiArc(level: level)
                    .stroke(level < chase ? Palette.blue : Color.primary.opacity(0.15), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .scaleEffect(state == .connected ? 1 : 0.88, anchor: .bottom)
                    .animation(popAnimation(level), value: state)
            }
            Circle()
                .fill(state == .off ? Color.primary.opacity(0.25) : Palette.blue)
                .frame(width: 12, height: 12)
                .padding(.bottom, 2)
                .animation(.easeOut(duration: 0.2), value: state)
        }
        .frame(width: 140, height: 110)
        .overlay(alignment: .topTrailing) {
            if state == .connected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Palette.green)
                    .background(Circle().fill(Palette.elevated).padding(2))
                    .offset(x: 10, y: -4)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
        }
    }

    private var labels: some View {
        VStack(spacing: 4) {
            Text(verbatim: "Studio 5G")
                .font(.headline)
            Text(statusText, ctx.language)
                .font(.subheadline)
                .foregroundStyle(state == .connected ? Palette.green : Color.secondary)
                .contentTransition(.numericText())
        }
    }

    private var statusText: LocalizedText {
        switch state {
        case .off: return L("Not connected", "未连接")
        case .searching: return L("Searching…", "正在搜索…")
        case .connected: return L("Connected", "已连接")
        }
    }

    private func popAnimation(_ level: Int) -> Animation {
        guard state == .connected else { return .easeOut(duration: 0.25) }
        return .spring(response: 0.35, dampingFraction: ctx["damping"]).delay(Double(level) * 0.06)
    }

    private func tap() {
        token += 1
        switch state {
        case .off:
            Haptics.tap(.light)
            withAnimation(.snappy) { state = .searching }
            let current = token
            let muted = Haptics.isMuted || ctx.isPreview
            DispatchQueue.main.asyncAfter(deadline: .now() + ctx["search"]) {
                guard current == token, state == .searching else { return }
                if !muted { Haptics.success() }
                withAnimation(.spring(response: 0.35, dampingFraction: ctx["damping"])) { state = .connected }
            }
        case .searching, .connected:
            Haptics.tap(.light)
            withAnimation(.snappy) { state = .off }
        }
    }
}
