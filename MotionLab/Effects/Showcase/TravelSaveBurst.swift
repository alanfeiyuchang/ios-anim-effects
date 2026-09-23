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
            "一张竖版目的地照片卡片（布拉耶斯湖），标题与收藏数旁边是一枚磨砂书签按钮。双击照片时，在触点处弹出一枚 64pt 的橙色渐变大书签：从 20% 缩放、−18° 以弹簧（响应 0.3 秒、阻尼 0.5）弹到 100%，150 毫秒后在 350 毫秒内上飘 50pt、缩到 80% 并淡出。与此同时，小按钮切换为实心橙色书签并做一次符号弹跳，10 颗橙色与青柠色相间的火花以 600 毫秒缓出径向飞出 38pt，边飞边缩到 20% 并淡出。收藏数滚动加一，并触发成功触感。一条带缩略图的暗色「已收藏到 2026 夏日」提示从顶部滑下，1.6 秒后自动收起。整体有庆祝感，但依然克制精致。"
        ),
        implementation: L(
            "The big bookmark and the spark ring are keyed with .id(counter), so each save re-creates them and their onAppear animations replay; the toast is dismissed by .task(id:) after a sleep, and the button uses contentTransition(.symbolEffect(.replace)) + symbolEffect(.bounce).",
            "大书签和火花环使用 .id(计数器)，每次收藏都会重建并重播 onAppear 动画；提示条由 .task(id:) 延时后收起；按钮使用 contentTransition(.symbolEffect(.replace)) 与 symbolEffect(.bounce)。"
        ),
        apis: ["onTapGesture(count:coordinateSpace:perform:)", "withAnimation(_:completion:)", "symbolEffect(.bounce)", "task(id:)", "contentTransition(.numericText)"],
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
            card
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

private struct TravelBigBookmark: View {
    /// 0 = hidden, 1 = popped, 2 = floated away.
    @State private var stage = 0

    var body: some View {
        Image(systemName: "bookmark.fill")
            .font(.system(size: 64, weight: .bold))
            .foregroundStyle(Signature.accentGradient)
            .shadow(color: Signature.accent.opacity(0.6), radius: 16)
            .scaleEffect(stage == 0 ? 0.2 : (stage == 1 ? 1 : 0.8))
            .rotationEffect(.degrees(stage == 0 ? -18 : 0))
            .offset(y: stage == 2 ? -50 : 0)
            .opacity(stage == 2 ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    stage = 1
                } completion: {
                    withAnimation(.easeIn(duration: 0.35).delay(0.15)) { stage = 2 }
                }
            }
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
