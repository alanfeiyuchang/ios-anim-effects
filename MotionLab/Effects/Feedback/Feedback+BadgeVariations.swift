import SwiftUI

// MARK: - Streak flame

extension Effect {
    static let feedbackStreakFlame = Effect(
        id: "feedback.streak-flame",
        category: .feedback,
        interaction: .tap,
        name: L("Streak Ignite", "连胜点燃"),
        summary: L("Checking in re-lights a cold flame with a burst of rising embers and a filled day dot.", "签到让熄灭的火苗重新燃起，余烬升腾，今天的圆点被点亮。"),
        prompt: L(
            "A streak card shows a 54 pt flame, a large rounded day count with 'day streak', and a row of seven 26 pt day dots — six filled amber, today's an empty ring. Before check-in the flame is cold: fully desaturated at 45% opacity. Tapping 'Check in' ignites it: the flame dips to 85%, surges to 135% and settles on a bouncy spring while wiggling ±6°, regains an amber → coral → red gradient with a warm glow, and releases 12 embers that rise about 60 pt over 0.9 s, drifting sideways and fading. The count rolls from 6 to 7, today's dot fills and pops 0 → 1.2 → 1.0, and a success haptic plays. Warm, motivating, habit-forming.",
            "一张连胜卡片上有一簇 54 pt 的火苗、大号圆体天数与“天连胜”，以及一排七个 26 pt 的日期圆点——六个已填充琥珀色，今天的是空心圆环。签到前火苗是“冷”的：完全去饱和、透明度 45%。点击“签到”将其点燃：火苗先缩到 85%，再冲到 135%，以弹跳弹簧落定并左右摆动 ±6°，恢复琥珀 → 珊瑚 → 红色渐变与温暖的辉光，同时迸出 12 颗余烬，在 0.9 秒内向上飘约 60 pt、边飘边横移淡出。天数从 6 滚动到 7，今天的圆点被填满并 0 → 1.2 → 1.0 弹出，伴随成功触感。温暖、激励人心、让人想坚持。"
        ),
        implementation: L(
            "A keyframeAnimator keyed on the ignite count scales and wiggles the flame; embers are value records rendered by a TimelineView from their age; saturation and a numericText count animate with the checked flag.",
            "以点燃次数为触发器的 keyframeAnimator 缩放并摆动火苗；余烬是值记录，由 TimelineView 按“年龄”渲染；饱和度与 numericText 天数随签到状态动画。"
        ),
        apis: ["keyframeAnimator(initialValue:trigger:)", "TimelineView", "saturation(_:)", "contentTransition(.numericText)"],
        tags: ["streak", "flame", "check-in", "habit", "连胜", "火焰", "签到", "习惯"],
        params: [
            .slider("embers", L("Embers", "余烬数"), 0...24, default: 12, step: 1, decimals: 0),
            .slider("surge", L("Ignite surge", "点燃膨胀"), 1.1...1.6, default: 1.35, decimals: 2),
        ]
    ) { ctx in
        StreakFlameDemo(ctx: ctx)
    }
}

private struct FlamePose {
    var scale: CGFloat = 1
    var angle: Double = 0
}

private struct Ember: Identifiable {
    let id: Int
    let born: Date
    let drift: CGFloat
    let rise: CGFloat
    let size: CGFloat
}

private struct StreakFlameDemo: View {
    let ctx: DemoContext
    @State private var checked = false
    @State private var ignites = 0
    @State private var embers: [Ember] = []
    @State private var nextEmber = 0

    var body: some View {
        let zh = ctx.language == .zh
        let days: Int = checked ? 7 : 6
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                ZStack {
                    EmberField(embers: embers, preview: ctx.isPreview)
                        .frame(width: 120, height: 120)
                        .offset(y: -20)
                    flame
                }
                .frame(height: 80)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(days)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: Double(days)))
                    Text(zh ? "天连胜" : "day streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                weekRow(zh: zh)
                Button(action: toggle) {
                    Text(checked ? (zh ? "今日已签到" : "Checked in") : (zh ? "签到" : "Check in"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 220, height: 46)
                        .background(checked ? AnyShapeStyle(Palette.successStrong) : AnyShapeStyle(Palette.sunset), in: Capsule())
                        .contentTransition(.opacity)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .demoCard()
            DemoHint(text: L("Tap Check in", "点击签到"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 2.2, delay: 0.5) { toggle() }
    }

    private var flame: some View {
        let surge: CGFloat = ctx.cg("surge")
        return Image(systemName: "flame.fill")
            .font(.system(size: 54))
            .foregroundStyle(LinearGradient(colors: [Palette.amber, Palette.coral, Palette.red], startPoint: .top, endPoint: .bottom))
            .saturation(checked ? 1 : 0)
            .opacity(checked ? 1 : 0.45)
            .shadow(color: Palette.coral.opacity(checked ? 0.6 : 0), radius: 14)
            .animation(.easeOut(duration: 0.3), value: checked)
            .keyframeAnimator(initialValue: FlamePose(), trigger: ignites) { content, pose in
                content
                    .scaleEffect(pose.scale, anchor: .bottom)
                    .rotationEffect(.degrees(pose.angle), anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.85, duration: 0.08)
                    CubicKeyframe(surge, duration: 0.14)
                    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.angle) {
                    LinearKeyframe(0, duration: 0.1)
                    CubicKeyframe(6, duration: 0.1)
                    CubicKeyframe(-6, duration: 0.12)
                    CubicKeyframe(3, duration: 0.1)
                    CubicKeyframe(0, duration: 0.12)
                }
            }
    }

    private func weekRow(zh: Bool) -> some View {
        let labels: [String] = zh ? ["一", "二", "三", "四", "五", "六", "日"] : ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 4) {
                    dayDot(index)
                    Text(labels[index])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func dayDot(_ index: Int) -> some View {
        let today = index == 6
        let filled = !today || checked
        return ZStack {
            Circle().strokeBorder(Palette.amber.opacity(0.6), lineWidth: 2)
            Circle()
                .fill(Palette.amber.gradient)
                .scaleEffect(filled ? 1 : 0.01)
                .opacity(filled ? 1 : 0)
                .animation(today ? Animation.spring(response: 0.35, dampingFraction: 0.45) : nil, value: filled)
            if filled {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 26, height: 26)
    }

    private func toggle() {
        if checked {
            withAnimation(.smooth(duration: 0.3)) { checked = false }
            return
        }
        let now = Date.now
        embers.removeAll { now.timeIntervalSince($0.born) > 1.0 }
        let count: Int = max(ctx.int("embers"), 0)
        for _ in 0..<count {
            embers.append(Ember(
                id: nextEmber,
                born: now,
                drift: CGFloat.random(in: -26...26),
                rise: CGFloat.random(in: 44...72),
                size: CGFloat.random(in: 3...5.5)
            ))
            nextEmber += 1
        }
        // Prune once they have burnt out so the timeline pauses again.
        Task {
            try? await Task.sleep(for: .seconds(0.95))
            let later = Date.now
            embers.removeAll { later.timeIntervalSince($0.born) > 0.9 }
        }
        ignites += 1
        withAnimation(.snappy(duration: 0.3)) { checked = true }
        if !ctx.isPreview { Haptics.success() }
    }
}

private struct EmberField: View {
    let embers: [Ember]
    let preview: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: embers.isEmpty)) { timeline in
            let now: Date = timeline.date
            Canvas { context, size in
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.75)
                for ember in embers {
                    let age: Double = now.timeIntervalSince(ember.born)
                    guard age >= 0 && age < 0.9 else { continue }
                    let u: CGFloat = CGFloat(age / 0.9)
                    let eased: CGFloat = 1 - (1 - u) * (1 - u)
                    let x: CGFloat = origin.x + ember.drift * eased
                    let y: CGFloat = origin.y - ember.rise * eased
                    let r: CGFloat = ember.size * (1 - 0.5 * u)
                    let color: Color = ember.id % 2 == 0 ? Palette.amber : Palette.coral
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(Double(1 - u))))
                }
            }
        }
        .allowsHitTesting(false)
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
            .onTapGesture { flip(index, byUser: true) }
            .animation(.smooth(duration: 0.35), value: isOnline)
    }

    /// Only a user's own tap buzzes; the ambient status cycle stays silent.
    private func flip(_ index: Int, byUser: Bool) {
        withAnimation(.snappy(duration: 0.3)) { online[index].toggle() }
        pops[index] += 1
        if byUser && online[index] { Haptics.tap(.soft) }
    }

    private func cycle() async {
        var order = 0
        let sequence: [Int] = [1, 4, 2, 1, 4, 2]
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(max(ctx["toggle"], 0.5)))
            guard !Task.isCancelled else { return }
            flip(sequence[order % sequence.count], byUser: false)
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
            "Hearts are value records with a birth time, sway phase, size and color; a TimelineView (paused when none are alive) computes each heart's position, scale and opacity from its age, and a delayed task prunes each heart once its life is over.",
            "每颗心是包含出生时间、摇摆相位、尺寸与颜色的值记录；TimelineView（无心时暂停）按“年龄”计算位置、缩放与透明度，寿命结束后由延迟任务将其清理。"
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
                Label { Text(verbatim: "2.4k") } icon: { Image(systemName: "eye.fill") }
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
        return TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: hearts.isEmpty)) { timeline in
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
        // Prune after the last heart has faded so the timeline pauses instead of ticking forever.
        Task {
            try? await Task.sleep(for: .seconds(life + 0.05))
            let later = Date.now
            hearts.removeAll { later.timeIntervalSince($0.born) > life }
        }
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
        // The sway ramps in over 0.3 s so every heart pops out of the button itself.
        let x: CGFloat = sway * CGFloat(sin(age * 3 + heart.phase)) * CGFloat(min(age / 0.3, 1))
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
