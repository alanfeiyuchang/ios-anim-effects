import SwiftUI

// MARK: - Easing helpers

private func spinFrac(_ x: Double) -> Double { x - floor(x) }

private func spinEaseInOut(_ x: Double) -> Double {
    let u = min(max(x, 0), 1)
    return u < 0.5 ? 4 * u * u * u : 1 - pow(-2 * u + 2, 3) / 2
}

/// A phase (in cycles) that advances at `rate` per second and stays continuous when the rate changes,
/// so dragging a speed slider speeds the loop up instead of teleporting it.
private struct SpinnerPhaseClock {
    var anchorDate = Date()
    var anchorPhase: Double = 0

    func phase(at date: Date, rate: Double) -> Double {
        anchorPhase + date.timeIntervalSince(anchorDate) * rate
    }

    mutating func rebase(at date: Date, oldRate: Double) {
        anchorPhase = phase(at: date, rate: oldRate)
        anchorDate = date
    }
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
            "Three 14 pt dots in indigo, violet and pink sit in a row with 8 pt gaps. Each dot hops on a half-sine arc — rising ~16 pt and falling back within the first half of a 1.1 s cycle, then resting — with a ~155 ms (14% of a cycle) stagger so the motion travels left to right like a wave; at the top of a hop a dot reaches 100% scale and full opacity, at rest it shrinks to 85% and dims to 50%. By default the row lives in a real chat thread: an incoming bubble with a 6 pt tail corner, a hairline border and soft shadow that breathes 1.00 ↔ 1.03 on a 1.1 s ease-in-out each way, beneath a gradient outgoing message and a 'Mia is typing…' caption. Light, friendly and never frantic.",
            "三颗 14 pt 圆点（靛蓝、紫罗兰、粉色）横向排列，间距 8 pt。每颗圆点在 1.1 秒周期的前半段沿半正弦弧线起跳约 16 pt 再落回，后半段静止；相邻圆点错开约 155 毫秒（14% 个周期），形成从左向右传递的波浪；跳到最高点时恢复 100% 大小与完全不透明，静止时缩到 85%、透明度降到 50%。默认放在真实的聊天场景里：一枚带 6 pt 尖角、细描边与柔和投影的接收气泡，在 1.00 ↔ 1.03 之间轻轻“呼吸”，单程 1.1 秒；上方是一条渐变的已发送消息和“米娅正在输入…”小字。轻盈友好，绝不急躁。"
        ),
        implementation: L(
            "A TimelineView evaluates a staggered half-sine per dot every frame and maps it to offset, scale and opacity.",
            "TimelineView 每帧为每颗圆点计算错峰的半正弦值，并映射到位移、缩放与透明度。"
        ),
        apis: ["TimelineView(.animation)", "offset(y:)", "UnevenRoundedRectangle", "phaseAnimator"],
        tags: ["dots", "typing", "bounce", "chat", "三点", "正在输入", "跳动", "聊天"],
        params: [
            .slider("speed", L("Speed", "速度"), 0.4...2.0, default: 0.9),
            .slider("height", L("Hop height", "跳跃高度"), 4...30, default: 16, decimals: 0, unit: "pt"),
            .slider("size", L("Dot size", "圆点大小"), 8...22, default: 14, decimals: 0, unit: "pt"),
            .toggle("bubble", L("Chat context", "聊天场景"), default: true),
        ]
    ) { ctx in
        DotBounceDemo(ctx: ctx)
    }
}

private struct DotBounceDemo: View {
    let ctx: DemoContext

    var body: some View {
        let row = DotBounceRow(size: ctx.cg("size"), speed: ctx["speed"], height: ctx.cg("height"), preview: ctx.isPreview)
        Group {
            if ctx.bool("bubble") {
                DotChatThread(row: row, language: ctx.language)
            } else {
                row.scaleEffect(1.6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A short conversation so the typing indicator reads in context (and fills the thumbnail).
private struct DotChatThread: View {
    let row: DotBounceRow
    let language: AppLanguage

    private var zh: Bool { language == .zh }

    private var incomingShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 6, bottomTrailingRadius: 22, topTrailingRadius: 22, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(zh ? "今晚的发布会你来吗？" : "Coming to the launch tonight?")
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Palette.primary,
                    in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 6, topTrailingRadius: 20, style: .continuous)
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            HStack(alignment: .bottom, spacing: 8) {
                Text(verbatim: "MJ")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .top, endPoint: .bottom), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text(zh ? "米娅正在输入…" : "Mia is typing…")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 6)
                    typingBubble
                }
                Spacer(minLength: 0)
            }
        }
        .frame(width: 290)
    }

    private var typingBubble: some View {
        row
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Palette.elevated, in: incomingShape)
            .overlay { incomingShape.stroke(Palette.stroke, lineWidth: 1) }
            .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            .phaseAnimator([false, true]) { content, swell in
                content.scaleEffect(swell ? 1.03 : 1, anchor: .bottomLeading)
            } animation: { _ in
                .easeInOut(duration: 1.1)
            }
    }
}

private struct DotBounceRow: View {
    let size: CGFloat
    let speed: Double
    let height: CGFloat
    let preview: Bool
    @State private var clock = SpinnerPhaseClock()

    private let colors: [Color] = [Palette.indigo, Palette.violet, Palette.pink]

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t = clock.phase(at: timeline.date, rate: speed)
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
        .onChange(of: speed) { old, _ in clock.rebase(at: .now, oldRate: old) }
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
            "A 96 pt ring on a faint 8% track above a two-line 'Preparing your library' caption. A gradient arc with round caps grows its head from 4% to 84% of the circumference over the first 55% of each 1.4 s cycle (cubic ease-in-out) while the tail waits, then the tail catches up over the last 55%, so the arc breathes long and short. Each cycle advances the arc 288° so it never lands in the same spot, on top of a slow drift of two turns per five cycles. A blurred copy of the arc glows beneath it and brightens as the arc lengthens, like light pooling in the stroke. Elastic and alive, never mechanical.",
            "直径 96 pt 的圆环，底部是一条 8% 透明度的淡色轨道，下方配两行“正在准备资源库”说明。带圆头的渐变弧线在每个 1.4 秒周期的前 55% 内，以三次缓入缓出让“头部”从周长的 4% 伸展到 84%，尾部按兵不动；随后尾部在后 55% 追上，弧线一长一短地“呼吸”。每个周期整体前进 288°，落点不断变化，同时叠加每五个周期两圈的缓慢漂移。弧线下方有一层模糊副本作辉光，弧线越长辉光越亮，仿佛光在线条里汇聚。富有弹性与生命力，毫无机械感。"
        ),
        implementation: L(
            "A TimelineView computes eased trim(from:to:) values and a cumulative rotation per frame (folded every five cycles to stay continuous); a blurred duplicate of the same trimmed arc, whose opacity follows the arc length, provides the glow.",
            "TimelineView 每帧计算带缓动的 trim(from:to:) 与累积旋转角度（每五个周期折叠一次以保证无缝衔接）；同一段弧线的模糊副本作为辉光，透明度随弧长变化。"
        ),
        apis: ["TimelineView", "trim(from:to:)", "StrokeStyle(lineCap:)", "rotationEffect", "blur(radius:)"],
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
        VStack(spacing: 28) {
            ArcSpinnerView(period: ctx["period"], lineWidth: ctx.cg("width"), colors: colors, preview: ctx.isPreview)
                .frame(width: 96, height: 96)
            VStack(spacing: 4) {
                Text(ctx.language == .zh ? "正在准备资源库" : "Preparing your library")
                    .font(.subheadline.weight(.semibold))
                Text(ctx.language == .zh ? "马上就好" : "This only takes a moment")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ArcSpinnerView: View {
    let period: Double
    let lineWidth: CGFloat
    let colors: [Color]
    let preview: Bool
    @State private var clock = SpinnerPhaseClock()

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let state = ArcSpinnerView.state(clock.phase(at: timeline.date, rate: 1 / max(period, 0.1)))
            let arc = Circle().trim(from: state.from, to: state.to)
            let gradient = LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            let length = Double(state.to - state.from)
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
                arc
                    .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth * 1.6, lineCap: .round))
                    .rotationEffect(.degrees(state.rotation - 90))
                    .blur(radius: lineWidth * 1.5)
                    .opacity(0.2 + 0.45 * length / 0.84)
                arc
                    .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(state.rotation - 90))
            }
        }
        .onChange(of: period) { old, _ in clock.rebase(at: .now, oldRate: 1 / max(old, 0.1)) }
    }

    /// `phase` is measured in cycles; the rotation folds every five cycles to stay continuous.
    static func state(_ phase: Double) -> (from: CGFloat, to: CGFloat, rotation: Double) {
        let local = phase.truncatingRemainder(dividingBy: 5)
        let cycle = floor(local)
        let u = local - cycle
        let head = spinEaseInOut(u / 0.55)
        let tail = spinEaseInOut((u - 0.45) / 0.55)
        let from = 0.8 * tail
        let to = 0.04 + 0.8 * head
        let rotation = cycle * 288 + local / 5 * 720
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
            "Five 14 pt dots of decreasing size (100% down to ~74%), each with a soft glow in its own color, travel around a 40 pt-radius orbit drawn as a faint hairline. Each dot follows the same 1.6 s cubic ease-in-out lap but starts 7.5% of a cycle after the one ahead, so the group clumps at the top, stretches into a comet as it accelerates down the sides, and gathers again. A small gradient core at the center swells to full size exactly when the dots bunch up and shrinks to 70% mid-lap, as if gravity were pulling them home. Hypnotic, with no hard starts or stops.",
            "五颗 14 pt、逐渐变小（从 100% 递减到约 74%）的圆点，各自带同色柔光，沿一条半径 40 pt 的淡色细轨道公转。每颗圆点都走同一条 1.6 秒、三次缓入缓出的圆周，但比前一颗晚出发 7.5% 个周期：它们在顶部挤成一团，沿两侧加速时拉成彗星尾，再重新聚拢。中心有一颗小小的渐变“核心”，在圆点聚拢的瞬间膨胀到满尺寸、在半圈时缩到 70%，仿佛引力正把它们拉回。令人着迷，没有任何生硬的启停。"
        ),
        implementation: L(
            "A TimelineView places each dot with offset + rotationEffect using a per-dot delayed, eased angle; the core's scale is a cosine of the same lap phase.",
            "TimelineView 用 offset + rotationEffect 放置每颗圆点，角度按各自延迟并做缓动；核心的缩放取自同一圈相位的余弦。"
        ),
        apis: ["TimelineView", "rotationEffect", "offset"],
        tags: ["orbit", "dots", "circle", "comet", "轨道", "圆点", "公转", "加载"],
        params: [
            .slider("count", L("Dots", "圆点数"), 3...8, default: 5, step: 1, decimals: 0),
            .slider("period", L("Lap time", "单圈时长"), 0.8...3.0, default: 1.6, decimals: 1, unit: "s"),
            .slider("radius", L("Orbit radius", "轨道半径"), 20...60, default: 40, decimals: 0, unit: "pt"),
            .toggle("color", L("Multicolor", "多彩"), default: true),
        ]
    ) { ctx in
        OrbitDotsView(
            count: max(ctx.int("count"), 1),
            period: ctx["period"],
            radius: ctx.cg("radius"),
            multicolor: ctx.bool("color"),
            preview: ctx.isPreview
        )
        .scaleEffect(1.8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OrbitDotsView: View {
    let count: Int
    let period: Double
    let radius: CGFloat
    let multicolor: Bool
    let preview: Bool
    @State private var clock = SpinnerPhaseClock()

    private let palette: [Color] = [Palette.mint, Palette.sky, Palette.blue, Palette.indigo, Palette.violet, Palette.pink, Palette.coral, Palette.amber]
    private let dot: CGFloat = 14

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t = clock.phase(at: timeline.date, rate: 1 / max(period, 0.1))
            let lap = spinFrac(t)
            ZStack {
                // Faint orbit track so the loader still reads when the dots clump together.
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1.5)
                    .frame(width: radius * 2, height: radius * 2)
                Circle()
                    .fill(multicolor ? AnyShapeStyle(Palette.aurora) : AnyShapeStyle(Color.primary.opacity(0.8)))
                    .frame(width: 16, height: 16)
                    .scaleEffect(0.85 + 0.15 * CGFloat(cos(lap * 2 * .pi)))
                    .shadow(color: (multicolor ? Palette.sky : Color.primary).opacity(0.35), radius: 6)
                ForEach(0..<count, id: \.self) { index in
                    let color = multicolor ? palette[index % palette.count] : Color.primary
                    Circle()
                        .fill(color)
                        .frame(width: dot, height: dot)
                        .shadow(color: color.opacity(0.45), radius: 4)
                        .scaleEffect(1 - CGFloat(index) * 0.065)
                        .offset(y: -radius)
                        .rotationEffect(.radians(OrbitDotsView.angle(t, index: index)))
                }
            }
            .frame(width: radius * 2 + dot, height: radius * 2 + dot)
        }
        .onChange(of: period) { old, _ in clock.rebase(at: .now, oldRate: 1 / max(old, 0.1)) }
    }

    /// `t` is the lap phase in cycles.
    static func angle(_ t: Double, index: Int) -> Double {
        let u = spinFrac(t - Double(index) * 0.075)
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
            "Twelve 3.5 × 11 pt capsule petals radiate 13 pt from a hub, like the iOS activity indicator. A bright head travels clockwise once per second; each petal is fully opaque as the head passes, then fades to 18% over the next 80% of a lap, leaving a comet of light. Stepped mode jumps petal by petal exactly like UIActivityIndicatorView; smooth mode glides. By default it sits at 1.5× in a 148 pt frosted HUD (28 pt continuous corners, 'Loading' caption) floating over a photo grid, so the material visibly blurs what is behind it. Petals follow the label color in light and dark mode. Familiar, native, quietly busy.",
            "十二片 3.5 × 11 pt 的胶囊花瓣以 13 pt 半径围成一圈，形如 iOS 系统加载指示器。高亮头每秒顺时针转一圈：扫过时花瓣全亮，随后在约 80% 圈的时间里淡回 18%，拖出一道光尾。逐格模式一瓣一瓣跳，与 UIActivityIndicatorView 如出一辙；平滑模式则连续滑行。默认放大到 1.5 倍，嵌在 148 pt、28 pt 连续圆角的磨砂 HUD 里（配“正在加载”），浮在照片网格上，材质的模糊一目了然。花瓣颜色跟随系统文字色，深浅模式皆清晰。"
        ),
        implementation: L(
            "Capsules are rotated into a ring; a TimelineView computes each petal's distance behind the moving head and maps it to opacity. The HUD is a regularMaterial rounded rectangle over a gradient photo grid.",
            "胶囊旋转排成一圈，TimelineView 计算每片花瓣落后于高亮头的距离并映射为透明度。HUD 是叠在渐变照片网格上的 regularMaterial 圆角矩形。"
        ),
        apis: ["TimelineView", "Capsule", "rotationEffect", "regularMaterial"],
        tags: ["activity indicator", "petals", "spinner", "hud", "菊花", "花瓣", "系统加载", "旋转"],
        params: [
            .slider("count", L("Petals", "花瓣数"), 8...16, default: 12, step: 1, decimals: 0),
            .slider("period", L("Revolution", "旋转周期"), 0.5...2.0, default: 1.0, decimals: 1, unit: "s"),
            .toggle("stepped", L("Stepped", "逐格跳动"), default: false),
            .toggle("hud", L("Frosted HUD", "磨砂 HUD"), default: true),
        ]
    ) { ctx in
        PetalsDemo(ctx: ctx)
    }
}

private struct PetalsDemo: View {
    let ctx: DemoContext

    var body: some View {
        let petals = PetalsView(count: max(ctx.int("count"), 1), period: ctx["period"], stepped: ctx.bool("stepped"), preview: ctx.isPreview)
        Group {
            if ctx.bool("hud") {
                ZStack {
                    PetalsPhotoGrid()
                    VStack(spacing: 16) {
                        petals
                            .scaleEffect(1.5)
                            .frame(width: 76, height: 76)
                        Text(ctx.language == .zh ? "正在加载" : "Loading")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 148, height: 148)
                    .demoGlass(RoundedRectangle(cornerRadius: 28, style: .continuous), material: .regularMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Palette.stroke))
                    .shadow(color: .black.opacity(0.16), radius: 24, y: 12)
                }
            } else {
                petals.scaleEffect(2.4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A soft gradient "photo library" behind the HUD so the material has something to blur.
private struct PetalsPhotoGrid: View {
    private let fills: [[Color]] = [
        [Palette.amber, Palette.coral], [Palette.sky, Palette.blue], [Palette.mint, Palette.sky],
        [Palette.pink, Palette.violet], [Palette.indigo, Palette.violet], [Palette.coral, Palette.pink],
        [Palette.mint, Palette.green], [Palette.amber, Palette.pink], [Palette.blue, Palette.indigo],
    ]
    private let symbols = ["sun.max.fill", "cloud.fill", "leaf.fill", "heart.fill", "moon.stars.fill", "flame.fill", "tree.fill", "sparkles", "drop.fill"]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { column in
                        tile(row * 3 + column)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .opacity(0.9)
    }

    private func tile(_ index: Int) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LinearGradient(colors: fills[index], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 84, height: 84)
            .overlay {
                Image(systemName: symbols[index])
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
    }
}

private struct PetalsView: View {
    let count: Int
    let period: Double
    let stepped: Bool
    let preview: Bool
    @State private var clock = SpinnerPhaseClock()

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview))) { timeline in
            let t = clock.phase(at: timeline.date, rate: 1 / max(period, 0.1))
            let rawHead = spinFrac(t) * Double(count)
            let head = stepped ? floor(rawHead) : rawHead
            ZStack {
                ForEach(0..<count, id: \.self) { index in
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: 3.5, height: 11)
                        // Pin the petal to the top of a 37 pt square (center 13 pt above the hub),
                        // so the rotation pivots around the hub, not the petal's own center.
                        .frame(width: 37, height: 37, alignment: .top)
                        .rotationEffect(.degrees(Double(index) / Double(count) * 360))
                        .opacity(PetalsView.opacity(head: head, index: index, count: count))
                }
            }
            .frame(width: 50, height: 50)
        }
        .onChange(of: period) { old, _ in clock.rebase(at: .now, oldRate: 1 / max(old, 0.1)) }
    }

    static func opacity(head: Double, index: Int, count: Int) -> Double {
        var distance = head - Double(index)
        if distance < 0 { distance += Double(count) }
        let fade = max(0, 1 - distance / (Double(count) * 0.8))
        return 0.18 + 0.82 * fade
    }
}
