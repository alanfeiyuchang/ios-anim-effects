import SwiftUI

extension Effect {
    static let buttonsHoldSegments = Effect(
        id: "buttons.hold-segments",
        category: .buttons,
        interaction: .gesture,
        name: L("Segmented Hold", "分段长按"),
        summary: L("Segments light up one click at a time while you hold, and drain back if you let go.", "按住时分段指示灯逐格点亮、每格一震，松手则逐格熄灭。"),
        prompt: L(
            "A dark 260 × 64 pt capsule reading \"Hold to unlock\" with a padlock glyph, and a row of five 40 × 8 pt segment pills beneath it. While held, the segments light up one by one in amber at equal steps across 1.5 s; each one pops from 60% to 115% width and settles on a snappy spring, flashes a short glow and fires a selection haptic, so progress is felt as discrete clicks rather than a smooth fill. Releasing early drains the lit segments in reverse at 60 ms per step with lighter ticks. When the fifth lights, all segments flash mint, the padlock swings open via a symbol replace, the capsule turns mint and a success haptic fires; after 1.4 s it relocks. Mechanical, countable and safe.",
            "一枚 260 × 64pt 的深色胶囊“长按解锁”，带挂锁图标，下方排着五枚 40 × 8pt 的分段条。按住时，五格在 1.5 秒内等间隔依次亮起琥珀色：每格宽度从 60% 弹到 115% 再以利落弹簧落定，闪一下辉光并触发选择触感，进度是一格一格“咔哒”出来的，而非平滑填充。中途松手，已亮的格子以每格 60 毫秒倒序熄灭，触感更轻。第五格亮起时全部闪成薄荷绿，挂锁通过符号替换弹开，胶囊转为薄荷绿并触发成功触感；1.4 秒后重新上锁。机械、可数、踏实。"
        ),
        implementation: L(
            "onPressingChanged starts an async Task that increments a lit count every duration / 5 seconds (each step springs its segment and ticks a haptic) or, on release, a drain Task that decrements every 60 ms; the fifth step unlocks. Segments pop through a per-index keyframeAnimator.",
            "onPressingChanged 启动一个异步 Task，每隔（时长 / 5）秒点亮一格（每步以弹簧驱动该格并触发触感）；松手时改为每 60 毫秒熄灭一格的 Task；第五格点亮即解锁。每格的弹跳由按序号触发的 keyframeAnimator 实现。"
        ),
        apis: ["onLongPressGesture(minimumDuration:perform:onPressingChanged:)", "Task", "keyframeAnimator", "contentTransition(.symbolEffect(.replace))", "UISelectionFeedbackGenerator"],
        tags: ["hold", "segments", "steps", "unlock", "长按", "分段", "步进", "解锁"],
        params: [
            .slider("duration", L("Hold duration", "按住时长"), 0.8...3.0, default: 1.5, unit: "s"),
            .slider("segments", L("Segments", "分段数"), 3...8, default: 5, step: 1, decimals: 0),
            .slider("drain", L("Drain step", "熄灭间隔"), 0.03...0.2, default: 0.06, unit: "s"),
        ]
    ) { ctx in
        ButtonHoldSegmentsDemo(ctx: ctx)
    }
}

private struct ButtonHoldSegmentsDemo: View {
    let ctx: DemoContext
    @State private var lit = 0
    @State private var unlocked = false
    @State private var pressing = false
    @State private var pops: [Int] = Array(repeating: 0, count: 8)
    @State private var worker: Task<Void, Never>?

    private var total: Int { min(max(ctx.int("segments"), 3), 8) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 18) {
                button
                segments
            }
            Spacer()
            DemoHint(text: L("Hold the button; let go to drain", "按住按钮；松手会回退"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: ctx["duration"] + 2.4, delay: 0.4) { simulate() }
        .onDisappear { worker?.cancel() }
    }

    private var button: some View {
        let tint = unlocked ? Palette.mint : Palette.amber
        return HStack(spacing: 10) {
            Image(systemName: unlocked ? "lock.open.fill" : "lock.fill")
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(tint)
            Text(unlocked ? L("Unlocked", "已解锁") : L("Hold to unlock", "长按解锁"), ctx.language)
                .foregroundStyle(unlocked ? Color.black : Color.white)
                .contentTransition(.opacity)
        }
        .font(.headline)
        .frame(width: 260, height: 64)
        .background {
            Capsule()
                .fill(unlocked ? AnyShapeStyle(Palette.mint.opacity(0.9)) : AnyShapeStyle(Color.adaptive(light: 0x1C1C22, dark: 0x2C2C32)))
        }
        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
        .shadow(color: tint.opacity(pressing || unlocked ? 0.35 : 0.1), radius: 16, y: 8)
        .scaleEffect(pressing && !unlocked ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressing)
        .animation(.smooth(duration: 0.3), value: unlocked)
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: ctx["duration"], maximumDistance: 40) {
            finishHold()
        } onPressingChanged: { isPressing in
            if isPressing { begin() } else { release() }
        }
        .accessibilityAddTraits(.isButton)
    }

    private var segments: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                segment(index)
            }
        }
    }

    private func segment(_ index: Int) -> some View {
        let on = index < lit
        let color = unlocked ? Palette.mint : Palette.amber
        return Capsule()
            .fill(on ? color : Color.primary.opacity(0.12))
            .frame(width: 40, height: 8)
            .shadow(color: color.opacity(on ? 0.7 : 0), radius: 5)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: pops[index]) { content, scale in
                content.scaleEffect(x: scale, y: 1)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    MoveKeyframe(0.6)
                    CubicKeyframe(1.15, duration: 0.1)
                    SpringKeyframe(1, duration: 0.3, spring: .snappy)
                }
            }
            .animation(.snappy(duration: 0.2), value: on)
            .animation(.smooth(duration: 0.3), value: unlocked)
    }

    private func begin() {
        guard !unlocked else { return }
        pressing = true
        worker?.cancel()
        let step = ctx["duration"] / Double(total)
        let muted = Haptics.isMuted
        worker = Task { @MainActor in
            while lit < total {
                try? await Task.sleep(for: .seconds(step))
                guard !Task.isCancelled, lit < pops.count else { return }
                pops[lit] += 1
                lit += 1
                if !muted { Haptics.selection() }
            }
            unlock(muted: muted)
        }
    }

    private func release() {
        pressing = false
        guard !unlocked else { return }
        worker?.cancel()
        let step = ctx["drain"]
        let muted = Haptics.isMuted
        worker = Task { @MainActor in
            while lit > 0 {
                try? await Task.sleep(for: .seconds(step))
                guard !Task.isCancelled else { return }
                lit -= 1
                if !muted { Haptics.tap(.soft) }
            }
        }
    }

    /// The gesture may complete a hair before the stepping task: light whatever is left and unlock.
    private func finishHold() {
        guard !unlocked else { return }
        worker?.cancel()
        while lit < total && lit < pops.count {
            pops[lit] += 1
            lit += 1
        }
        unlock(muted: Haptics.isMuted)
    }

    private func unlock(muted: Bool) {
        guard !unlocked else { return }
        pressing = false
        unlocked = true
        if !muted { Haptics.success() }
        worker = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            unlocked = false
            lit = 0
        }
    }

    private func simulate() {
        guard !unlocked, !pressing else { return }
        Haptics.isMuted = true
        begin()
        Haptics.isMuted = false
    }
}
