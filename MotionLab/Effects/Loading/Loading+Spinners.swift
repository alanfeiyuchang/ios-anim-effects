import SwiftUI

// MARK: - Easing helpers

private func spinFrac(_ x: Double) -> Double { x - floor(x) }

private func spinEaseInOut(_ x: Double) -> Double {
    let u = min(max(x, 0), 1)
    return u < 0.5 ? 4 * u * u * u : 1 - pow(-2 * u + 2, 3) / 2
}

// MARK: - Three-dot bounce

extension Effect {
    static let loadingDotBounce = Effect(
        id: "loading.dot-bounce",
        category: .loading,
        interaction: .loop,
        name: L("Three-Dot Bounce", "三点跳动"),
        summary: L("Three dots hop in a staggered wave — also a chat typing indicator.", "三颗圆点错峰跳跃，也可作聊天“正在输入”。"),
        prompt: L(
            "Three 14 pt dots in indigo, violet and pink sit in a row with 8 pt gaps. Each dot hops on a half-sine arc — rising ~16 pt and falling back within the first half of a 1.1 s cycle, then resting — with a ~155 ms (14% of a cycle) stagger so the motion travels left to right like a wave. At the top of each hop a dot grows to 100% and full opacity; at rest it shrinks to 85% and dims to 50%. Optionally the row sits inside a tail-cornered chat bubble as a typing indicator. The rhythm is light, friendly and never frantic.",
            "三颗 14 pt 圆点（靛蓝、紫罗兰、粉色）横向排列，间距 8 pt。每颗圆点在 1.1 秒周期的前半段沿半正弦弧线起跳约 16 pt 再落回，后半段静止；相邻圆点错开约 155 毫秒（14% 个周期），形成从左向右传递的波浪。跳到最高点时圆点恢复 100% 大小与完全不透明，静止时缩到 85% 并降到 50% 透明度。可选择将其放入带尖角的聊天气泡中，作为“对方正在输入”提示。节奏轻盈、友好，绝不急躁。"
        ),
        implementation: L(
            "A TimelineView evaluates a staggered half-sine per dot every frame and maps it to offset, scale and opacity.",
            "TimelineView 每帧为每颗圆点计算错峰的半正弦值，并映射到位移、缩放与透明度。"
        ),
        apis: ["TimelineView(.animation)", "offset(y:)", "UnevenRoundedRectangle"],
        tags: ["dots", "typing", "bounce", "chat", "三点", "正在输入", "跳动", "聊天"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.4...2.0, default: 0.9),
            .slider("height", L("Hop height", "跳跃高度"), 4...30, default: 16, decimals: 0, unit: "pt"),
            .slider("size", L("Dot size", "圆点大小"), 8...22, default: 14, decimals: 0, unit: "pt"),
            .toggle("bubble", L("Chat bubble", "聊天气泡"), default: false),
        ]
    ) { ctx in
        DotBounceDemo(ctx: ctx)
    }
}

private struct DotBounceDemo: View {
    let ctx: DemoContext

    var body: some View {
        let row = DotBounceRow(size: ctx.cg("size"), speed: ctx["speed"], height: ctx.cg("height"))
        Group {
            if ctx.bool("bubble") {
                row
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(
                        Palette.elevated,
                        in: UnevenRoundedRectangle(topLeadingRadius: 26, bottomLeadingRadius: 8, bottomTrailingRadius: 26, topTrailingRadius: 26, style: .continuous)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            } else {
                row.scaleEffect(1.3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DotBounceRow: View {
    let size: CGFloat
    let speed: Double
    let height: CGFloat

    private let colors: [Color] = [Palette.indigo, Palette.violet, Palette.pink]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * speed
            HStack(spacing: size * 0.55) {
                ForEach(0..<3, id: \.self) { index in
                    let lift = DotBounceRow.lift(t, index: index)
                    Circle()
                        .fill(colors[index])
                        .frame(width: size, height: size)
                        .scaleEffect(0.85 + 0.15 * lift)
                        .opacity(0.5 + 0.5 * lift)
                        .offset(y: -height * lift)
                }
            }
            .frame(height: size + height, alignment: .bottom)
        }
    }

    static func lift(_ t: Double, index: Int) -> CGFloat {
        let phase = spinFrac(t - Double(index) * 0.14)
        guard phase < 0.5 else { return 0 }
        return CGFloat(sin(phase / 0.5 * .pi))
    }
}

// MARK: - Arc spinner

extension Effect {
    static let loadingArcSpinner = Effect(
        id: "loading.arc-spinner",
        category: .loading,
        interaction: .loop,
        name: L("Breathing Arc Spinner", "呼吸弧线旋转器"),
        summary: L("A trimmed arc whose head and tail chase each other with easing.", "头尾交替追逐、带缓动的截断圆弧。"),
        prompt: L(
            "A 76 pt ring on a faint 8% track. A gradient arc with round caps grows its head from 4% to 84% of the circumference over the first 55% of each 1.4 s cycle (cubic ease-in-out), while the tail waits, then catches up over the last 55% so the arc breathes long and short. Each cycle the whole arc advances 288° so the rhythm never repeats at the same spot, on top of a slow constant rotation of two turns per five cycles. The overlapping ease makes the stroke feel elastic and alive rather than mechanically rotating.",
            "直径 76 pt 的圆环，底部是一条 8% 透明度的淡色轨道。带圆头的渐变弧线在每个 1.4 秒周期的前 55% 内，以三次缓入缓出让“头部”从周长的 4% 伸展到 84%，尾部先按兵不动，随后在后 55% 追上，使弧线一长一短地“呼吸”。每个周期整体前进 288°，落点不断变化，同时叠加每五个周期两圈的缓慢匀速自转。头尾缓动相互重叠，让线条显得有弹性、有生命，而非机械地打转。"
        ),
        implementation: L(
            "A TimelineView computes eased trim(from:to:) values and a cumulative rotation per frame; the loop is folded every five cycles to stay continuous.",
            "TimelineView 每帧计算带缓动的 trim(from:to:) 与累积旋转角度，每五个周期折叠一次以保证无缝衔接。"
        ),
        apis: ["TimelineView", "trim(from:to:)", "StrokeStyle(lineCap:)", "rotationEffect"],
        tags: ["spinner", "arc", "material", "indeterminate", "旋转", "弧线", "菊花", "加载"],
        params: [
            .slider("period", L("Cycle", "周期"), 0.8...2.5, default: 1.4, decimals: 1, unit: "s"),
            .slider("width", L("Line width", "线宽"), 2...10, default: 6, decimals: 0, unit: "pt"),
            .choice("style", L("Color", "配色"), [L("Aurora", "极光"), L("Sunset", "日落"), L("Mono", "单色")], default: 0),
        ]
    ) { ctx in
        ArcSpinnerDemo(ctx: ctx)
    }
}

private struct ArcSpinnerDemo: View {
    let ctx: DemoContext

    private var colors: [Color] {
        switch ctx.int("style") {
        case 1: return [Palette.amber, Palette.coral, Palette.pink]
        case 2: return [Color.primary, Color.primary]
        default: return [Palette.mint, Palette.sky, Palette.violet]
        }
    }

    var body: some View {
        ArcSpinnerView(period: ctx["period"], lineWidth: ctx.cg("width"), colors: colors)
            .frame(width: 76, height: 76)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ArcSpinnerView: View {
    let period: Double
    let lineWidth: CGFloat
    let colors: [Color]

    var body: some View {
        TimelineView(.animation) { timeline in
            let state = ArcSpinnerView.state(timeline.date.timeIntervalSinceReferenceDate, period: period)
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
                Circle()
                    .trim(from: state.from, to: state.to)
                    .stroke(
                        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(state.rotation - 90))
            }
        }
    }

    static func state(_ time: Double, period: Double) -> (from: CGFloat, to: CGFloat, rotation: Double) {
        let loop = period * 5
        let local = time.truncatingRemainder(dividingBy: loop)
        let cycle = floor(local / period)
        let u = local / period - cycle
        let head = spinEaseInOut(u / 0.55)
        let tail = spinEaseInOut((u - 0.45) / 0.55)
        let from = 0.8 * tail
        let to = 0.04 + 0.8 * head
        let rotation = cycle * 288 + local / loop * 720
        return (CGFloat(from), CGFloat(to), rotation)
    }
}

// MARK: - Orbiting dots

extension Effect {
    static let loadingOrbitDots = Effect(
        id: "loading.orbit-dots",
        category: .loading,
        interaction: .loop,
        name: L("Orbiting Dots", "轨道圆点"),
        summary: L("Dots circle an orbit, bunching up and spreading out with easing.", "圆点沿轨道公转，随缓动聚拢又散开。"),
        prompt: L(
            "Five dots of decreasing size (100% down to ~74%) travel around a 34 pt-radius orbit. Each dot follows the same cubic ease-in-out lap of 1.6 s but starts 7.5% of a cycle after the one ahead, so the group clumps together at the top, stretches into a comet as it accelerates down the sides, and gathers again — the classic 'orbit' loader. Colors step through a cool aurora palette, or stay monochrome. The motion feels gravitational and hypnotic, with no hard starts or stops.",
            "五颗逐渐变小（从 100% 递减到约 74%）的圆点沿半径 34 pt 的轨道公转。每颗圆点都走同一条 1.6 秒、三次缓入缓出的圆周，但比前一颗晚出发 7.5% 个周期：于是它们在顶部挤成一团，沿两侧加速时拉成一条彗星尾，再重新聚拢——经典的“轨道”加载器。颜色依次取自冷调极光色，也可切换为单色。运动带着引力感，令人着迷，没有任何生硬的启停。"
        ),
        implementation: L(
            "A TimelineView places each dot with offset + rotationEffect using a per-dot delayed, eased angle.",
            "TimelineView 用 offset + rotationEffect 放置每颗圆点，角度按各自延迟并做缓动。"
        ),
        apis: ["TimelineView", "rotationEffect", "offset"],
        tags: ["orbit", "dots", "circle", "comet", "轨道", "圆点", "公转", "加载"],
        params: [
            .slider("count", L("Dots", "圆点数"), 3...8, default: 5, step: 1, decimals: 0),
            .slider("period", L("Lap time", "单圈时长"), 0.8...3.0, default: 1.6, decimals: 1, unit: "s"),
            .slider("radius", L("Orbit radius", "轨道半径"), 20...60, default: 34, decimals: 0, unit: "pt"),
            .toggle("color", L("Multicolor", "多彩"), default: true),
        ]
    ) { ctx in
        OrbitDotsView(
            count: max(ctx.int("count"), 1),
            period: ctx["period"],
            radius: ctx.cg("radius"),
            multicolor: ctx.bool("color")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OrbitDotsView: View {
    let count: Int
    let period: Double
    let radius: CGFloat
    let multicolor: Bool

    private let palette: [Color] = [Palette.mint, Palette.sky, Palette.blue, Palette.indigo, Palette.violet, Palette.pink, Palette.coral, Palette.amber]
    private let dot: CGFloat = 12

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    Circle()
                        .fill(multicolor ? palette[index % palette.count] : Color.primary)
                        .frame(width: dot, height: dot)
                        .scaleEffect(1 - CGFloat(index) * 0.065)
                        .offset(y: -radius)
                        .rotationEffect(.radians(OrbitDotsView.angle(t, index: index, period: period)))
                }
            }
            .frame(width: radius * 2 + dot, height: radius * 2 + dot)
        }
    }

    static func angle(_ t: Double, index: Int, period: Double) -> Double {
        let u = spinFrac(t / period - Double(index) * 0.075)
        return spinEaseInOut(u) * 2 * .pi
    }
}

// MARK: - Activity petals

extension Effect {
    static let loadingActivityPetals = Effect(
        id: "loading.activity-petals",
        category: .loading,
        interaction: .loop,
        name: L("Activity Petals", "花瓣指示器"),
        summary: L("The classic iOS petal spinner, smooth or stepped.", "经典 iOS 花瓣式“菊花”，可平滑或逐格。"),
        prompt: L(
            "Twelve rounded capsule petals (3.5 × 11 pt) radiate from the hub, centered 13 pt out, like the iOS activity indicator. A bright 'head' travels clockwise once per second; each petal is fully opaque when the head passes and fades back to an 18% resting opacity over the following ~80% of a lap, producing a trailing comet of light. In stepped mode the head jumps petal by petal, exactly like UIActivityIndicatorView; in smooth mode it glides continuously. The color adapts to the label color so it reads in light and dark mode.",
            "十二片圆角胶囊花瓣（3.5 × 11 pt）以 13 pt 中心半径呈放射状排列，形如 iOS 系统加载指示器。一个“高亮头”每秒顺时针转一圈；它经过时花瓣完全不透明，随后在约 80% 圈的时间里逐渐淡回 18% 的静息透明度，形成一条拖尾光带。逐格模式下高亮头一瓣一瓣跳动，与 UIActivityIndicatorView 完全一致；平滑模式下则连续滑行。颜色跟随系统文字色，浅色与深色模式下都清晰可辨。"
        ),
        implementation: L(
            "Capsules are rotated into a ring; a TimelineView computes each petal's distance behind the moving head and maps it to opacity.",
            "胶囊旋转排成一圈，TimelineView 计算每片花瓣落后于高亮头的距离并映射为透明度。"
        ),
        apis: ["TimelineView", "Capsule", "rotationEffect", "opacity"],
        tags: ["activity indicator", "petals", "spinner", "system", "菊花", "花瓣", "系统加载", "旋转"],
        params: [
            .slider("count", L("Petals", "花瓣数"), 8...16, default: 12, step: 1, decimals: 0),
            .slider("period", L("Revolution", "旋转周期"), 0.5...2.0, default: 1.0, decimals: 1, unit: "s"),
            .slider("scale", L("Size", "大小"), 1.0...3.0, default: 2.2, decimals: 1, unit: "×"),
            .toggle("stepped", L("Stepped", "逐格跳动"), default: false),
        ]
    ) { ctx in
        PetalsView(count: max(ctx.int("count"), 1), period: ctx["period"], stepped: ctx.bool("stepped"))
            .scaleEffect(ctx.cg("scale"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PetalsView: View {
    let count: Int
    let period: Double
    let stepped: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let rawHead = spinFrac(t / period) * Double(count)
            let head = stepped ? floor(rawHead) : rawHead
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: 3.5, height: 11)
                        .offset(y: -13)
                        .rotationEffect(.degrees(Double(index) / Double(count) * 360))
                        .opacity(PetalsView.opacity(head: head, index: index, count: count))
                }
            }
            .frame(width: 50, height: 50)
        }
    }

    static func opacity(head: Double, index: Int, count: Int) -> Double {
        var distance = head - Double(index)
        if distance < 0 { distance += Double(count) }
        let fade = max(0, 1 - distance / (Double(count) * 0.8))
        return 0.18 + 0.82 * fade
    }
}
