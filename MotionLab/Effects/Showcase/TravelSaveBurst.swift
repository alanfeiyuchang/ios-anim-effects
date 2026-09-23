import SwiftUI

extension Effect {
    static let showcaseSaveBurst = Effect(
        id: "showcase.save-burst",
        category: .showcase,
        interaction: .tap,
        name: L("Save to Trip Burst", "收藏迸发"),
        summary: L(
            "Double-tap a photo or hit the bookmark: a big bookmark pops, sparks burst, a toast slides in.",
            "双击照片或点书签：大书签弹出、火花迸射，并滑入收藏提示。"
        ),
        prompt: L(
            "A tall destination photo card (Lago di Braies) has a frosted bookmark button next to its title and save count. Double-tapping the photo pops a 64 pt orange-gradient bookmark at the touch point: it springs from 20% scale and −18° to 100% (response 0.3 s, damping 0.5), then after 150 ms drifts up 50 pt while shrinking to 80% and fading out over 350 ms. Meanwhile the small button swaps to a filled orange bookmark with a symbol bounce, and 10 alternating orange and lime sparks fly radially 38 pt outward over 600 ms ease-out, shrinking to 20% and fading. The save count rolls up by one and a success haptic fires. A dark “Saved to Summer ’26” toast with a thumbnail slides down from the top edge and dismisses itself after 1.6 s. It feels celebratory yet refined.",
            "竖版目的地照片卡片（布拉耶斯湖）的标题旁有一枚磨砂书签按钮。双击照片，触点处弹出 64pt 橙色渐变大书签：从 20%、−18° 以弹簧（响应 0.3 秒、阻尼 0.5）弹到 100%，150 毫秒后 350 毫秒内上飘 50pt、缩到 80% 淡出。同时小按钮变为实心橙色书签并弹跳，10 颗橙与青柠相间的火花以 600 毫秒缓出径向飞出 38pt，缩到 20% 淡出。收藏数加一并触发成功触感，“已收藏到 2026 夏日”提示从顶部滑下，1.6 秒后收起。"
        ),
        implementation: L(
            "The big bookmark and the spark ring are keyed with .id(counter), so each save re-creates them; the bookmark runs one keyframeAnimator timeline (pop, 150 ms hold, float) and the ring replays its onAppear animation; the toast is dismissed by .task(id:) after a sleep, and the button uses contentTransition(.symbolEffect(.replace)) + symbolEffect(.bounce).",
            "大书签和火花环使用 .id(计数器)，每次收藏都会重建；大书签按一条 keyframeAnimator 时间线（弹出、停留 150 毫秒、上飘）播放，火花环重播 onAppear 动画；提示条由 .task(id:) 延时后收起；按钮使用 contentTransition(.symbolEffect(.replace)) 与 symbolEffect(.bounce)。"
        ),
        apis: ["onTapGesture(count:coordinateSpace:perform:)", "keyframeAnimator", "symbolEffect(.bounce)", "task(id:)", "contentTransition(.numericText)"],
        tags: ["bookmark", "save", "double tap", "burst", "particles", "收藏", "书签", "双击", "粒子"],
        params: [
            .slider("particles", L("Spark count", "火花数量"), 6...16, default: 10, step: 1, decimals: 0),
            .slider("radius", L("Burst radius", "迸发半径"), 24...60, default: 38, decimals: 0, unit: "pt"),
            .toggle("toast", L("Show toast", "显示提示条"), default: true),
        ]
    ) { ctx in
        TravelSaveBurstDemo(ctx: ctx)
    }
}

// MARK: - Demo

private struct TravelSavePop: Equatable {
    let id: Int
    let location: CGPoint
}

private struct TravelSaveBurstDemo: View {
    let ctx: DemoContext
    @State private var saved = false
    @State private var burstID = 0
    @State private var pop: TravelSavePop?
    @State private var toast = false

    private var zh: Bool { ctx.language == .zh }
    private var saveCount: Int { 2_318 + (saved ? 1 : 0) }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
                DemoHint(text: L("Double-tap the photo to save it", "双击照片即可收藏"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .autoplay(ctx.isPreview, every: 1.5, delay: 0.4) {
            if saved {
                toggleSave()
            } else {
                doubleTap(at: CGPoint(x: 140, y: 130))
            }
        }
        .task(id: burstID) {
            guard burstID > 0 else { return }
            try? await Task.sleep(for: .seconds(1.6))
            // A re-save cancels this task; its early wake-up must not hide the new toast.
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { toast = false }
        }
    }

    private var card: some View {
        ZStack {
            LandscapeArt(seed: 2)
            LinearGradient(
                colors: [Color.black.opacity(0.3), .clear, Color.black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            if let pop {
                TravelBigBookmark()
                    .id(pop.id)
                    .position(pop.location)
            }
        }
        .frame(width: 280, height: 300)
        .overlay(alignment: .bottom) { info }
        .overlay(alignment: .top) { toastView }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .signatureCard()
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture(count: 2, coordinateSpace: .local) { location in
            doubleTap(at: location)
        }
    }

    private var info: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(zh ? "意大利 · 多洛米蒂" : "Italy · Dolomites")
                    .signatureEyebrow()
                Text("Lago di Braies")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 9))
                    Text(saveCount, format: .number)
                        .contentTransition(.numericText(value: Double(saveCount)))
                    Text(zh ? "人收藏" : "saves")
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
            }
            Spacer(minLength: 0)
            saveButton
        }
        .padding(16)
    }

    private var saveButton: some View {
        Button(action: toggleSave) {
            ZStack {
                TravelSparkRing(count: max(ctx.int("particles"), 1), radius: ctx.cg("radius"))
                    .id(burstID)
                    .opacity(burstID == 0 ? 0 : 1)
                Circle()
                    .fill(.ultraThinMaterial)
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(saved ? Signature.accent : Color.white)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: saved)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var toastView: some View {
        if toast {
            HStack(spacing: 10) {
                LandscapeArt(seed: 2)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(zh ? "已收藏到「2026 夏日」" : "Saved to Summer ’26")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Spacer(minLength: 0)
                Text(zh ? "查看" : "View")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Signature.accent)
            }
            .padding(8)
            .padding(.trailing, 6)
            .background(Signature.cardHigh.opacity(0.95), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Signature.hairline))
            .padding(12)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func doubleTap(at location: CGPoint) {
        pop = TravelSavePop(id: (pop?.id ?? 0) + 1, location: location)
        if !saved { toggleSave() }
    }

    private func toggleSave() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { saved.toggle() }
        if saved {
            burstID += 1
            if !ctx.isPreview { Haptics.success() }
            if ctx.bool("toast") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { toast = true }
            }
        } else if !ctx.isPreview {
            Haptics.tap()
        }
    }
}

// MARK: - Pieces

private struct TravelBookmarkFrame {
    var scale: Double = 0.2
    var rotation: Double = -18
    var lift: Double = 0
    var opacity: Double = 0
}

/// One fixed timeline: pop (0–300 ms), hold 150 ms, float away (450–800 ms). Keyframes keep the
/// float-away start exact instead of waiting for the pop spring to settle.
private struct TravelBigBookmark: View {
    @State private var fire = 0

    var body: some View {
        Image(systemName: "bookmark.fill")
            .font(.system(size: 64, weight: .bold))
            .foregroundStyle(Signature.accentGradient)
            .shadow(color: Signature.accent.opacity(0.6), radius: 16)
            .keyframeAnimator(initialValue: TravelBookmarkFrame(), trigger: fire) { content, frame in
                content
                    .scaleEffect(frame.scale)
                    .rotationEffect(.degrees(frame.rotation))
                    .offset(y: frame.lift)
                    .opacity(frame.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    MoveKeyframe(0.2)
                    SpringKeyframe(1, duration: 0.3, spring: Spring(response: 0.3, dampingRatio: 0.5))
                    LinearKeyframe(1, duration: 0.15)
                    CubicKeyframe(0.8, duration: 0.35)
                }
                KeyframeTrack(\.rotation) {
                    MoveKeyframe(-18)
                    SpringKeyframe(0, duration: 0.3, spring: Spring(response: 0.3, dampingRatio: 0.5))
                }
                KeyframeTrack(\.lift) {
                    MoveKeyframe(0)
                    LinearKeyframe(0, duration: 0.45)
                    CubicKeyframe(-50, duration: 0.35)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(1)
                    LinearKeyframe(1, duration: 0.45)
                    CubicKeyframe(0, duration: 0.35)
                }
            }
            .allowsHitTesting(false)
            .onAppear { fire += 1 }
    }
}

private struct TravelSparkRing: View {
    let count: Int
    let radius: CGFloat
    @State private var fired = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Signature.accent.opacity(0.7), lineWidth: 1.5)
                .scaleEffect(fired ? 1.9 : 0.8)
                .opacity(fired ? 0 : 1)
            ForEach(0..<count, id: \.self) { index in
                let angle = Double(index) / Double(count) * 2 * .pi
                let even = index.isMultiple(of: 2)
                Circle()
                    .fill(even ? Signature.accent : Signature.lime)
                    .frame(width: even ? 6 : 4, height: even ? 6 : 4)
                    .scaleEffect(fired ? 0.2 : 1)
                    .offset(
                        x: fired ? CGFloat(cos(angle)) * radius : 0,
                        y: fired ? CGFloat(sin(angle)) * radius : 0
                    )
                    .opacity(fired ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { fired = true }
        }
    }
}
