import SwiftUI

extension Effect {
    static let buttonsEchoPress = Effect(
        id: "buttons.echo-press",
        category: .buttons,
        interaction: .tap,
        name: L("Sonar Echo", "声呐回响"),
        summary: L("Each tap sends staggered outline echoes rippling off the button's edge.", "每次点击，按钮边缘向外发出错峰的描边回响。"),
        prompt: L(
            "A 230 × 60 pt sky-to-blue capsule reading \"Ping my keys\" with a radio-waves glyph, under a small AirTag-style item card. On tap the button dips to 95% and springs back, the glyph bounces, and three hairline copies of the capsule's outline peel off its edge one after another, 140 ms apart. Each echo grows 44 pt outward on every side over 0.8 s with an ease-out curve while its stroke thins from 2.5 to 0.5 pt and fades to zero, so the rings read like sonar pulses leaving the device. The item card's status line flashes \"Playing sound…\" and a medium haptic fires. Rapid taps overlap cleanly. Clean, communicative and precise — a press that visibly reaches out.",
            "一枚 230 × 60pt 的天蓝到蓝色胶囊“让钥匙响铃”，带电波图标，上方是一张 AirTag 式物品卡片。点击后按钮下沉到 95% 再弹回，图标跳一下；三道与按钮同形的细描边每隔 140 毫秒依次从边缘剥离，各自在 0.8 秒内以 ease-out 向四周扩张 44pt，描边从 2.5pt 细到 0.5pt 并淡出，像声呐脉冲向外扩散。物品卡片的状态行闪现“正在播放声音…”，伴随中等触感；快速连点时回响干净叠加。一次看得见“传出去”的按压。"
        ),
        implementation: L(
            "Every tap appends an echo id; each echo is a Capsule stroke whose own KeyframeAnimator holds for its stagger delay and then eases progress 0 → 1, mapping progress to frame growth, line width and opacity. Echo ids are pruned after they finish.",
            "每次点击追加一个回响 id；每道回响是一条 Capsule 描边，拥有自己的 KeyframeAnimator：先按错峰时长停留，再把进度从 0 缓动到 1，并映射为尺寸扩张、线宽与透明度。回响播放结束后移除。"
        ),
        apis: ["KeyframeAnimator", "LinearKeyframe", "Capsule().stroke", "symbolEffect(.bounce)", "keyframeAnimator"],
        tags: ["echo", "sonar", "ripple", "pulse", "回响", "声呐", "涟漪", "脉冲"],
        params: [
            .slider("rings", L("Echo count", "回响数量"), 1...4, default: 3, step: 1, decimals: 0),
            .slider("spread", L("Echo spread", "扩散距离"), 20...70, default: 44, decimals: 0, unit: "pt"),
            .slider("stagger", L("Stagger", "错峰间隔"), 0.05...0.3, default: 0.14, unit: "s"),
        ]
    ) { ctx in
        ButtonEchoPressDemo(ctx: ctx)
    }
}

private struct ButtonEchoPulse: Identifiable {
    let id: Int
}

private struct ButtonEchoPressDemo: View {
    let ctx: DemoContext
    @State private var pulses: [ButtonEchoPulse] = []
    @State private var nextID = 0
    @State private var taps = 0
    @State private var ringing = false

    private let size = CGSize(width: 230, height: 60)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 30) {
                itemCard
                button
            }
            Spacer()
            DemoHint(text: L("Tap the button", "点击按钮"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.3) { ping() }
    }

    private var itemCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.blue)
                .frame(width: 42, height: 42)
                .background(Palette.sky.opacity(0.16), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(L("Keys", "钥匙"), ctx.language)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                ZStack(alignment: .leading) {
                    if ringing {
                        Text(L("Playing sound…", "正在播放声音…"), ctx.language)
                            .foregroundStyle(Palette.blue)
                            .transition(.blurReplace)
                    } else {
                        Text(L("Nearby · 3 m", "附近 · 3 米"), ctx.language)
                            .foregroundStyle(.secondary)
                            .transition(.blurReplace)
                    }
                }
                .font(.caption)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: size.width)
        .demoCard(cornerRadius: 18)
    }

    private var button: some View {
        ZStack {
            ForEach(pulses) { pulse in
                ButtonEchoRings(
                    count: max(ctx.int("rings"), 1),
                    spread: ctx.cg("spread"),
                    stagger: ctx["stagger"],
                    size: size
                )
                .id(pulse.id)
            }
            Button(action: ping) {
                Label(ctx.language == .zh ? "让钥匙响铃" : "Ping my keys", systemImage: "dot.radiowaves.left.and.right")
                    .symbolEffect(.bounce, value: taps)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: size.width, height: size.height)
                    .background(Palette.ocean, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: Palette.blue.opacity(0.35), radius: 14, y: 8)
                    .keyframeAnimator(initialValue: CGFloat(1), trigger: taps) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        KeyframeTrack(\.self) {
                            CubicKeyframe(0.95, duration: 0.08)
                            SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .frame(height: size.height + 100)
    }

    private func ping() {
        Haptics.tap(.medium)
        taps += 1
        let pulse = ButtonEchoPulse(id: nextID)
        nextID += 1
        pulses.append(pulse)
        withAnimation(.smooth(duration: 0.3)) { ringing = true }
        let lifetime = 0.9 + ctx["stagger"] * Double(max(ctx.int("rings"), 1))
        let tag = taps
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(lifetime))
            pulses.removeAll { $0.id == pulse.id }
            if tag == taps {
                withAnimation(.smooth(duration: 0.3)) { ringing = false }
            }
        }
    }
}

/// One tap's worth of echoes; each ring plays once as soon as it appears.
private struct ButtonEchoRings: View {
    let count: Int
    let spread: CGFloat
    let stagger: Double
    let size: CGSize
    @State private var fire = 0

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ring(delay: Double(index) * stagger)
            }
        }
        // Rings overflow this fixed frame, so growing echoes never push the layout around.
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .onAppear { fire += 1 }
    }

    private func ring(delay: Double) -> some View {
        KeyframeAnimator(initialValue: CGFloat(0), trigger: fire) { progress in
            let grow = spread * 2 * progress
            Capsule()
                .stroke(Palette.sky, lineWidth: 2.5 - 2 * progress)
                .frame(width: size.width + grow, height: size.height + grow)
                .opacity(progress > 0 && progress < 1 ? Double(1 - progress) : 0)
        } keyframes: { _ in
            KeyframeTrack(\.self) {
                LinearKeyframe(0, duration: max(delay, 0.001))
                LinearKeyframe(0.001, duration: 0.001)
                CubicKeyframe(1, duration: 0.8)
            }
        }
    }
}
