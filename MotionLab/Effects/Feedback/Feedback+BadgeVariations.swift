import SwiftUI

// MARK: - Fly to cart

extension Effect {
    static let feedbackCartFly = Effect(
        id: "feedback.cart-fly",
        category: .feedback,
        interaction: .tap,
        name: L("Fly to Cart", "飞入购物袋"),
        summary: L("A product thumbnail arcs into the bag, which wiggles as its badge ticks up.", "商品缩略图沿弧线飞进购物袋，购物袋一晃，角标随之加一。"),
        prompt: L(
            "A product page: a 150 pt gradient product tile, name and price, an 'Add to Bag' pill, and a bag icon in the top-right corner with a red count badge. On tap a copy of the tile lifts off and flies along a quadratic arc — rising about 80 pt above the straight path — to the bag in 0.6 s ease-in, shrinking to 18% and tilting 20° as it accelerates. On arrival it vanishes into the bag, the bag wiggles (-12°, 10°, -6°, 0°) and swells to 115%, and the badge rolls to the new number while popping 1.0 → 1.35 → 1.0 on a bouncy spring, with a medium haptic. Tactile, spatial, satisfying.",
            "一个商品页：150 pt 的渐变商品图块、名称与价格、“加入购物袋”胶囊按钮，右上角是带红色数字角标的购物袋图标。点击后图块的副本腾空而起，沿二次曲线弧线——比直线路径高出约 80 pt——以 0.6 秒缓入飞向购物袋，加速途中缩小到 18% 并倾斜 20°。抵达时它消失在袋中，购物袋左右摇晃（-12°、10°、-6°、0°）并膨胀到 115%，角标滚动到新数字，同时以弹跳弹簧在 1.0 → 1.35 → 1.0 间弹一下，伴随中等触感。有触感、有空间感、令人满足。"
        ),
        implementation: L(
            "Each flight is a fresh view (id) with an Animatable modifier that places it on a quadratic Bézier by progress; keyframeAnimators keyed on the arrival count wiggle the bag and pop the badge.",
            "每次飞行都是一个新的视图（id），其 Animatable 修饰器按进度把它放在二次贝塞尔曲线上；以到达次数为触发器的 keyframeAnimator 让购物袋摇晃、角标弹跳。"
        ),
        apis: ["Animatable", "ViewModifier", "position(x:y:)", "keyframeAnimator(initialValue:trigger:)", "contentTransition(.numericText)"],
        tags: ["cart", "add to bag", "fly", "badge", "购物车", "加入购物袋", "飞入", "角标"],
        params: [
            .slider("duration", L("Flight time", "飞行时长"), 0.3...1.2, default: 0.6, decimals: 2, unit: "s"),
            .slider("arc", L("Arc height", "弧线高度"), 0...160, default: 80, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        CartFlyDemo(ctx: ctx)
    }
}

private struct CartPose {
    var angle: Double = 0
    var scale: CGFloat = 1
}

private struct CartFlyDemo: View {
    let ctx: DemoContext
    @State private var count = 2
    @State private var arrivals = 0
    @State private var flightID = 0
    @State private var flying = false

    private let size = CGSize(width: 300, height: 320)
    private let tileCenter = CGPoint(x: 150, y: 132)
    private let bagCenter = CGPoint(x: 268, y: 30)

    var body: some View {
        let zh = ctx.language == .zh
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                Color.clear
                bag.position(bagCenter)
                productTile.position(tileCenter)
                VStack(spacing: 4) {
                    Text(zh ? "云朵跑鞋" : "Cloud Runner")
                        .font(.headline)
                    Text(zh ? "¥899" : "$129")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .position(x: 150, y: 236)
                Button(action: add) {
                    Label(zh ? "加入购物袋" : "Add to Bag", systemImage: "bag.badge.plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 46)
                        .background(Palette.primary, in: Capsule())
                }
                .buttonStyle(.plain)
                .position(x: 150, y: 292)
                if flying {
                    CartFlyingThumb(start: tileCenter, end: bagCenter, arc: ctx.cg("arc"), duration: ctx["duration"])
                        .id(flightID)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: size.width, height: size.height)
            DemoHint(text: L("Tap Add to Bag", "点击“加入购物袋”"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.5) { add() }
    }

    private var productTile: some View {
        CartProductFace(side: 150)
            .shadow(color: Palette.coral.opacity(0.3), radius: 16, y: 8)
    }

    private var bag: some View {
        Image(systemName: "bag.fill")
            .font(.system(size: 26))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
            .overlay(alignment: .topTrailing) {
                Text("\(count)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(count)))
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Palette.red, in: Capsule())
                    .keyframeAnimator(initialValue: CGFloat(1), trigger: arrivals) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            CubicKeyframe(1.35, duration: 0.12)
                            SpringKeyframe(1.0, duration: 0.45, spring: .bouncy)
                        }
                    }
                    .offset(x: 6, y: -4)
            }
            .keyframeAnimator(initialValue: CartPose(), trigger: arrivals) { content, pose in
                content
                    .rotationEffect(.degrees(pose.angle), anchor: .top)
                    .scaleEffect(pose.scale)
            } keyframes: { _ in
                KeyframeTrack(\.angle) {
                    CubicKeyframe(-12, duration: 0.08)
                    CubicKeyframe(10, duration: 0.1)
                    CubicKeyframe(-6, duration: 0.1)
                    CubicKeyframe(0, duration: 0.12)
                }
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.15, duration: 0.1)
                    SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                }
            }
    }

    private func add() {
        guard !flying else { return }
        let duration = ctx["duration"]
        let live = !ctx.isPreview
        if live { Haptics.tap() }
        flightID += 1
        flying = true
        Task {
            try? await Task.sleep(for: .seconds(duration))
            flying = false
            withAnimation(.snappy(duration: 0.3)) {
                count = count >= 9 ? 1 : count + 1
            }
            arrivals += 1
            if live { Haptics.tap(.medium) }
        }
    }
}

/// Places the view on a quadratic Bézier from `start` to `end`, lifted by `arc`.
private struct CartArc: ViewModifier, Animatable {
    var progress: CGFloat
    let start: CGPoint
    let end: CGPoint
    let arc: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let t: CGFloat = progress
        let control = CGPoint(x: start.x + (end.x - start.x) * 0.25, y: min(start.y, end.y) - arc)
        let a: CGFloat = (1 - t) * (1 - t)
        let b: CGFloat = 2 * (1 - t) * t
        let c: CGFloat = t * t
        let x: CGFloat = a * start.x + b * control.x + c * end.x
        let y: CGFloat = a * start.y + b * control.y + c * end.y
        return content
            .scaleEffect(1 - 0.82 * t)
            .rotationEffect(.degrees(Double(20 * t)))
            .opacity(t > 0.96 ? 0 : 1)
            .position(x: x, y: y)
    }
}

/// One flight: a fresh view per launch that animates its own progress along the arc.
private struct CartFlyingThumb: View {
    let start: CGPoint
    let end: CGPoint
    let arc: CGFloat
    let duration: Double
    @State private var progress: CGFloat = 0

    var body: some View {
        CartProductFace(side: 150)
            .modifier(CartArc(progress: progress, start: start, end: end, arc: arc))
            .onAppear {
                withAnimation(.easeIn(duration: duration)) { progress = 1 }
            }
    }
}

private struct CartProductFace: View {
    let side: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Palette.sunset)
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: "shoe.fill")
                    .font(.system(size: side * 0.36, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

// MARK: - Presence ping

extension Effect {
    static let feedbackPresencePing = Effect(
        id: "feedback.presence-ping",
        category: .feedback,
        interaction: .state,
        name: L("Presence Ping", "在线状态涟漪"),
        summary: L("Online dots emit soft radar pings; a teammate going online pops their dot green.", "在线圆点发出柔和的雷达涟漪；同事上线时圆点弹成绿色。"),
        prompt: L(
            "A 'Design team' card shows five 48 pt gradient avatars in an overlapping row, each with a 14 pt status dot ringed in the card color. Online dots are green and emit a ping every 1.6 s — a ring that grows from 100% to 260% while fading from 55% to 0%, staggered 0.3 s between people so the row twinkles rather than blinks. Every 2.6 s one teammate toggles: going online, their avatar regains full saturation, the gray hollow dot fills green and pops 0.6 → 1.3 → 1.0 on a bouncy spring, and the '3 online' count rolls; going offline reverses it and the avatar dims to 45% saturation. Ambient, social, calm.",
            "一张“设计团队”卡片上，五个 48 pt 的渐变头像交叠成一排，每个头像右下角有一颗 14 pt 的状态圆点，外圈描着卡片底色。在线圆点为绿色，每 1.6 秒发出一次涟漪——一圈从 100% 扩到 260%、透明度从 55% 降到 0% 的圆环；成员之间错开 0.3 秒，整排像星光闪烁而不是齐刷刷地闪。每 2.6 秒会有一位同事切换状态：上线时头像恢复饱和度，灰色空心圆点被绿色填满并以弹跳弹簧 0.6 → 1.3 → 1.0 弹一下，“3 人在线”计数滚动；下线则反向，头像饱和度降到 45%。安静的氛围感，带着社交温度。"
        ),
        implementation: L(
            "A TimelineView computes each online member's ping ring from a phase-shifted fraction; status flips animate saturation and the dot fill, and a keyframeAnimator keyed on the flip count pops the changed dot.",
            "TimelineView 按错开的相位为每位在线成员计算涟漪圆环；状态切换以动画改变饱和度与圆点填充，以切换次数为触发器的 keyframeAnimator 让变化的圆点弹一下。"
        ),
        apis: ["TimelineView", "saturation(_:)", "keyframeAnimator(initialValue:trigger:)", "contentTransition(.numericText)"],
        tags: ["presence", "online", "status", "avatar", "在线", "状态", "头像", "涟漪"],
        params: [
            .slider("ping", L("Ping interval", "涟漪间隔"), 0.8...3.0, default: 1.6, decimals: 1, unit: "s"),
            .slider("reach", L("Ping size", "涟漪大小"), 1.6...3.5, default: 2.6, decimals: 1, unit: "×"),
            .slider("toggle", L("Status change", "状态切换间隔"), 1.2...5.0, default: 2.6, decimals: 1, unit: "s"),
        ]
    ) { ctx in
        PresencePingDemo(ctx: ctx)
    }
}

private struct PresenceMember {
    let initials: String
    let colors: [Color]
}

private struct PresencePingDemo: View {
    let ctx: DemoContext
    @State private var online: [Bool] = [true, false, true, true, false]
    @State private var pops: [Int] = [0, 0, 0, 0, 0]

    private let members: [PresenceMember] = [
        PresenceMember(initials: "AK", colors: [Palette.sky, Palette.blue]),
        PresenceMember(initials: "SL", colors: [Palette.mint, Palette.green]),
        PresenceMember(initials: "MJ", colors: [Palette.pink, Palette.violet]),
        PresenceMember(initials: "RT", colors: [Palette.amber, Palette.coral]),
        PresenceMember(initials: "DN", colors: [Palette.indigo, Palette.violet]),
    ]

    var body: some View {
        let zh = ctx.language == .zh
        let onlineCount: Int = online.filter { $0 }.count
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(zh ? "设计团队" : "Design team")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Palette.green).frame(width: 8, height: 8)
                        Text(zh ? "\(onlineCount) 人在线" : "\(onlineCount) online")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .contentTransition(.numericText(value: Double(onlineCount)))
                    }
                    .foregroundStyle(.secondary)
                }
                TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                    let t: Double = timeline.date.timeIntervalSinceReferenceDate
                    HStack(spacing: -12) {
                        ForEach(0..<members.count, id: \.self) { index in
                            avatar(index, t: t)
                        }
                    }
                }
            }
            .frame(width: 256)
            .padding(20)
            .demoCard()
            DemoHint(text: L("Tap an avatar to toggle", "点击头像切换状态"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: ctx["toggle"]) { await cycle() }
    }

    private func avatar(_ index: Int, t: Double) -> some View {
        let member = members[index]
        let isOnline = online[index]
        let period: Double = max(ctx["ping"], 0.3)
        let raw: Double = (t - Double(index) * 0.3) / period
        let u: Double = raw - floor(raw)
        let reach: CGFloat = ctx.cg("reach")
        return Text(member.initials)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(LinearGradient(colors: member.colors, startPoint: .top, endPoint: .bottom), in: Circle())
            .overlay { Circle().stroke(Palette.elevated, lineWidth: 3) }
            .saturation(isOnline ? 1 : 0.45)
            .opacity(isOnline ? 1 : 0.8)
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .stroke(Palette.green, lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .scaleEffect(1 + (reach - 1) * CGFloat(u))
                        .opacity(isOnline ? 0.55 * (1 - u) : 0)
                    Circle()
                        .fill(isOnline ? Palette.green : Palette.elevated)
                        .overlay { Circle().strokeBorder(isOnline ? Palette.green : Color.secondary, lineWidth: 2) }
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(Palette.elevated).padding(-3))
                        .keyframeAnimator(initialValue: CGFloat(1), trigger: pops[index]) { content, scale in
                            content.scaleEffect(scale)
                        } keyframes: { _ in
                            KeyframeTrack(\.self) {
                                MoveKeyframe(0.6)
                                CubicKeyframe(1.3, duration: 0.15)
                                SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                            }
                        }
                }
                .offset(x: 1, y: 1)
            }
            .zIndex(Double(members.count - index))
            .onTapGesture { flip(index) }
            .animation(.smooth(duration: 0.35), value: isOnline)
    }

    private func flip(_ index: Int) {
        withAnimation(.snappy(duration: 0.3)) { online[index].toggle() }
        pops[index] += 1
        if online[index] && !ctx.isPreview { Haptics.tap(.soft) }
    }

    private func cycle() async {
        var order = 0
        let sequence: [Int] = [1, 4, 2, 1, 4, 2]
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(max(ctx["toggle"], 0.5)))
            guard !Task.isCancelled else { return }
            flip(sequence[order % sequence.count])
            order += 1
        }
    }
}

// MARK: - Floating hearts

extension Effect {
    static let feedbackFloatingHearts = Effect(
        id: "feedback.floating-hearts",
        category: .feedback,
        interaction: .tap,
        name: L("Floating Hearts", "飘心"),
        summary: L("Every tap releases a heart that pops, sways upward and fades, like a live stream.", "每次点击都放出一颗心，弹出、摇摆着上升再淡出，像直播间一样。"),
        prompt: L(
            "A 280 × 300 pt live-stream card with a pulsing 'LIVE' pill and a viewer count has a heart button in its lower-right corner. Each tap pops a new 24–34 pt heart out of the button — 0 → 115% in 0.15 s — then it rises about 220 pt over 2.2 s on an ease-out curve while swaying on its own sine (±14 pt, random phase) and fading out quadratically; hearts pick pink, red, coral, violet or amber. The button squishes to 88% on each tap, the like count rolls, and a soft haptic ticks. Rapid tapping builds a drifting stream of hearts. Joyful, social, weightless.",
            "一张 280 × 300 pt 的直播卡片，带脉动的“LIVE”标签与观看人数，右下角是一个爱心按钮。每次点击都会从按钮里弹出一颗 24–34 pt 的爱心——0.15 秒内从 0 放大到 115%——随后在 2.2 秒内以缓出曲线上升约 220 pt，同时按各自随机相位的正弦左右摇摆（±14 pt），透明度按平方曲线淡出；颜色在粉、红、珊瑚、紫罗兰、琥珀中随机选择。按钮每次点击压到 88%，点赞数滚动，并伴随轻触感。快速连点会汇成一条飘荡的爱心流。欢快、有社交感、轻盈。"
        ),
        implementation: L(
            "Hearts are value records with a birth time, sway phase, size and color; a TimelineView (paused when none are alive) computes each heart's position, scale and opacity from its age and prunes old ones on the next tap.",
            "每颗心是包含出生时间、摇摆相位、尺寸与颜色的值记录；TimelineView（无心时暂停）按“年龄”计算位置、缩放与透明度，并在下一次点击时清理过期的心。"
        ),
        apis: ["TimelineView(.animation(minimumInterval:paused:))", "Identifiable", "contentTransition(.numericText)", "ButtonStyle"],
        tags: ["hearts", "live", "like", "stream", "飘心", "直播", "点赞", "爱心"],
        params: [
            .slider("life", L("Float time", "上升时长"), 1.0...4.0, default: 2.2, decimals: 1, unit: "s"),
            .slider("sway", L("Sway", "摇摆幅度"), 0...30, default: 14, decimals: 0, unit: "pt"),
            .slider("rise", L("Rise height", "上升高度"), 120...280, default: 220, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        FloatingHeartsDemo(ctx: ctx)
    }
}

private struct FloatHeart: Identifiable {
    let id: Int
    let born: Date
    let phase: Double
    let size: CGFloat
    let color: Color
}

private struct FloatingHeartsDemo: View {
    let ctx: DemoContext
    @State private var hearts: [FloatHeart] = []
    @State private var nextID = 0
    @State private var likes = 1284

    private let colors: [Color] = [Palette.pink, Palette.red, Palette.coral, Palette.violet, Palette.amber]

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                streamBackground
                heartLayer
                heartButton
                    .padding(16)
            }
            .frame(width: 280, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 18, y: 10)
            DemoHint(text: L("Tap the heart repeatedly", "连续点击爱心"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.32, delay: 0.3) { spawn() }
    }

    private var streamBackground: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: 0x2B1A4F), Color(hex: 0x6E3A8C), Color(hex: 0xE0708A)], startPoint: .top, endPoint: .bottom)
            Image(systemName: "music.mic")
                .font(.system(size: 90, weight: .light))
                .foregroundStyle(.white.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                Text(verbatim: "LIVE")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Palette.red, in: Capsule())
                    .phaseAnimator([false, true]) { content, dim in
                        content.opacity(dim ? 0.65 : 1)
                    } animation: { _ in
                        .easeInOut(duration: 0.8)
                    }
                Label("2.4k", systemImage: "eye.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(14)
        }
    }

    private var heartLayer: some View {
        let life: Double = max(ctx["life"], 0.3)
        let sway: CGFloat = ctx.cg("sway")
        let rise: CGFloat = ctx.cg("rise")
        return TimelineView(.animation(minimumInterval: nil, paused: hearts.isEmpty)) { timeline in
            let now: Date = timeline.date
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                ForEach(hearts) { heart in
                    FloatHeartView(heart: heart, now: now, life: life, sway: sway, rise: rise)
                }
            }
            .padding(.trailing, 22)
            .padding(.bottom, 30)
        }
        .allowsHitTesting(false)
    }

    private var heartButton: some View {
        Button(action: spawn) {
            VStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Palette.pink)
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
                Text("\(likes)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(likes)))
            }
        }
        .buttonStyle(HeartSquishStyle())
    }

    private func spawn() {
        let now = Date.now
        let life: Double = max(ctx["life"], 0.3)
        hearts.removeAll { now.timeIntervalSince($0.born) > life }
        let heart = FloatHeart(
            id: nextID,
            born: now,
            phase: Double.random(in: 0...(2 * .pi)),
            size: CGFloat.random(in: 24...34),
            color: colors[nextID % colors.count]
        )
        nextID += 1
        hearts.append(heart)
        withAnimation(.snappy(duration: 0.2)) { likes += 1 }
        if !ctx.isPreview { Haptics.tap(.soft) }
    }
}

private struct FloatHeartView: View {
    let heart: FloatHeart
    let now: Date
    let life: Double
    let sway: CGFloat
    let rise: CGFloat

    var body: some View {
        let age: Double = now.timeIntervalSince(heart.born)
        let u: Double = min(max(age / life, 0), 1)
        let eased: Double = 1 - (1 - u) * (1 - u)
        let pop: Double = age < 0.15 ? age / 0.15 * 1.15 : (age < 0.3 ? 1.15 - (age - 0.15) / 0.15 * 0.15 : 1)
        let x: CGFloat = sway * CGFloat(sin(age * 3 + heart.phase))
        let y: CGFloat = -rise * CGFloat(eased)
        Image(systemName: "heart.fill")
            .font(.system(size: heart.size))
            .foregroundStyle(heart.color)
            .shadow(color: heart.color.opacity(0.4), radius: 4)
            .scaleEffect(CGFloat(pop))
            .opacity(1 - u * u)
            .offset(x: x, y: y)
    }
}

private struct HeartSquishStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
