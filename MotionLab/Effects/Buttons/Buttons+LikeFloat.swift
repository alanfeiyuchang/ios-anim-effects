import SwiftUI

extension Effect {
    static let buttonsLikeFloat = Effect(
        id: "buttons.like-float",
        category: .buttons,
        interaction: .tap,
        name: L("Floating Hearts", "飘心点赞"),
        summary: L("Every tap releases a heart that sways up the live stream and fades.", "每次点击都放飞一颗爱心，沿直播画面摇摆上升并淡出。"),
        prompt: L(
            "A live-stream card (landscape video, LIVE badge, viewer count) with a 52 pt circular heart button in its bottom-right corner. Every tap releases a small heart from the button: it pops from 40% to full size in the first 15% of its life, then rises ~170 pt over 1.8 s while swaying left and right on a sine path (±14 pt, each heart with its own phase and frequency), tilting with the sway and fading out over the last 40% of its climb. Hearts get a random colour from a warm palette and slightly different sizes, so rapid tapping builds a lively column. The button itself squashes to 86% and rebounds on each tap with a light haptic, and a tap counter rolls up. Social, energetic, communal.",
            "直播卡片（风景画面、LIVE 标识、观看人数）右下角是一枚 52pt 的圆形爱心按钮。每次点击放飞一颗小爱心：在生命周期前 15% 从 40% 弹到原尺寸，随后 1.8 秒内上升约 170pt，沿正弦路径左右摇摆（±14pt，相位与频率各异），身体随摆动倾斜，最后 40% 行程淡出。爱心从暖色系随机取色、大小略有差异，连点就会堆出一串热闹心流。按钮每次压到 86% 再回弹并轻触一下，计数同步上滚。热烈、有现场感。"
        ),
        implementation: L(
            "Each tap appends a heart with a seed and birth date; a TimelineView (paused when empty) positions every heart from its age — scale pop, sine sway, tilt and fade — and a Task removes it when its life ends. The button pops with a keyframeAnimator.",
            "每次点击追加一颗带种子与诞生时间的爱心；TimelineView（没有爱心时暂停）根据年龄计算每颗爱心的弹出缩放、正弦摇摆、倾斜与淡出，生命结束后由 Task 移除。按钮的弹跳由 keyframeAnimator 实现。"
        ),
        apis: ["TimelineView", "keyframeAnimator", "rotationEffect", "numericText", "Task.sleep"],
        tags: ["like", "hearts", "live", "float", "点赞", "飘心", "直播", "上升"],
        params: [
            .slider("rise", L("Rise height", "上升高度"), 100...220, default: 170, decimals: 0, unit: "pt"),
            .slider("sway", L("Sway", "摇摆幅度"), 0...30, default: 14, decimals: 0, unit: "pt"),
            .slider("life", L("Lifetime", "持续时间"), 1.0...3.0, default: 1.8, unit: "s"),
        ]
    ) { ctx in
        ButtonLikeFloatDemo(ctx: ctx)
    }
}

private struct ButtonFloatingHeart: Identifiable {
    let id: Int
    let born: Date
    let seed: Double
}

private struct ButtonLikeFloatDemo: View {
    let ctx: DemoContext
    @State private var hearts: [ButtonFloatingHeart] = []
    @State private var nextID = 0
    @State private var taps = 0

    private let cardSize = CGSize(width: 290, height: 290)
    private static let colors: [Color] = [Palette.pink, Palette.coral, Palette.amber, Palette.red, Palette.violet]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Tap the heart quickly", "快速连点爱心"), ctx: ctx)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 0.35, delay: 0.3) { tap() }
    }

    private var card: some View {
        ZStack(alignment: .bottomTrailing) {
            LandscapeArt(seed: 1)
            LinearGradient(colors: [.clear, Color.black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
            header
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview), paused: hearts.isEmpty)) { timeline in
                ZStack(alignment: .bottomTrailing) {
                    ForEach(hearts) { heart in
                        floatingHeart(heart, now: timeline.date)
                    }
                }
                .frame(width: cardSize.width, height: cardSize.height, alignment: .bottomTrailing)
            }
            .allowsHitTesting(false)
            button
                .padding(16)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }

    private var header: some View {
        VStack {
            HStack(spacing: 8) {
                Text(verbatim: "LIVE")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Palette.red, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Label {
                    Text(verbatim: "12.4K")
                } icon: {
                    Image(systemName: "eye.fill")
                }
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.35), in: Capsule())
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Sunset session", "日落现场"), ctx.language)
                        .font(.headline)
                    Text(L("\(12_480 + taps) likes", "\(12_480 + taps) 次点赞"), ctx.language)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .contentTransition(.numericText(value: Double(taps)))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                Spacer(minLength: 0)
            }
            .padding(.trailing, 70)
        }
        .padding(16)
        .frame(width: cardSize.width, height: cardSize.height)
    }

    private var button: some View {
        Button(action: tap) {
            Image(systemName: "heart.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [Palette.pink, Palette.coral], startPoint: .top, endPoint: .bottom),
                    in: Circle()
                )
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                .shadow(color: Palette.pink.opacity(0.5), radius: 10, y: 5)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: taps) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack(\.self) {
                        CubicKeyframe(0.86, duration: 0.07)
                        SpringKeyframe(1, duration: 0.35, spring: .bouncy)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L("Send a like", "送出点赞"), ctx.language))
    }

    private func floatingHeart(_ heart: ButtonFloatingHeart, now: Date) -> some View {
        let life = ctx["life"]
        let age = now.timeIntervalSince(heart.born)
        let p = min(max(age / life, 0), 1)
        let pop: Double = min(p / 0.15, 1)
        let scale = CGFloat(0.4 + 0.6 * pop) * CGFloat(0.8 + 0.4 * heart.seed)
        let frequency: Double = 2.2 + heart.seed * 1.6
        let wave: Double = sin(p * frequency * Double.pi + heart.seed * 6)
        let x = CGFloat(wave) * ctx.cg("sway")
        let y = -ctx.cg("rise") * CGFloat(p)
        let fade: Double = p < 0.6 ? 1 : max(0, 1 - (p - 0.6) / 0.4)
        let colorIndex = Int(heart.seed * 100) % Self.colors.count
        return Image(systemName: "heart.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(Self.colors[colorIndex])
            .shadow(color: Color.black.opacity(0.2), radius: 3, y: 1)
            .scaleEffect(scale)
            .rotationEffect(.degrees(wave * 14))
            .offset(x: x, y: y)
            .opacity(fade)
            // Centre the hearts over the 52 pt button that sits 16 pt from the corner.
            .frame(width: 52, height: 52)
            .padding(16)
    }

    private func tap() {
        withAnimation(.snappy) { taps += 1 }
        Haptics.tap()
        let seed = sportHash(Double(nextID) * 1.37)
        let heart = ButtonFloatingHeart(id: nextID, born: Date(), seed: seed)
        nextID += 1
        hearts.append(heart)
        let life = ctx["life"]
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(life + 0.1))
            hearts.removeAll { $0.id == heart.id }
        }
    }
}
