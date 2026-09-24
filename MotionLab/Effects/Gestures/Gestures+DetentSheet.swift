import SwiftUI

extension Effect {
    static let gesturesDetentSheet = Effect(
        id: "gestures.detent-sheet",
        category: .gestures,
        interaction: .gesture,
        name: L("Velocity Detent Sheet", "速度感知分段面板"),
        summary: L("A Maps-style sheet that projects your flick forward and lands on the right detent.", "地图式底部面板：根据甩动速度预测落点，停在合适的档位。"),
        prompt: L(
            "Inside a 230×320 pt phone frame with 34 pt continuous corners, a map-like background sits under a bottom sheet with three detents: peek (74 pt visible), half (52%) and full (26 pt from the top). The sheet tracks the finger 1:1 and rubber-bands 40 pt past the outer detents. On release it does not pick the detent nearest where the finger stopped; it projects the position forward by velocity × 0.2 s and springs (response 0.42 s, damping 0.82) to the detent closest to that projection, so a short, fast flick skips straight from peek to full. As the sheet rises the background dims up to 30% and recedes to 94% scale, and a selection haptic ticks when the detent changes. Fluid, predictive and native.",
            "230×320 pt的手机框（34 pt连续圆角）里，地图式背景上叠着一个底部面板，共三个档位：收起（露出74 pt）、半屏（52%）和全屏（距顶26 pt）。面板1:1跟手，越过两端档位后带40 pt橡皮筋阻尼。松手时并不停到离手指最近的档位，而是按速度× 0.2秒预测落点，再以弹簧（响应0.42秒、阻尼0.82）停到离预测点最近的一档，所以短促一甩就能从收起直达全屏。面板升起时背景最多压暗30%、后退到94%，换档时有一下选择触感。流畅可预判。"
        ),
        implementation: L(
            "A DragGesture on the sheet only adds a rubber-banded translation to the current detent's top; onEnded projects top + velocity × projection and springs to the nearest detent, and the backdrop reads the same fraction for dimming and scale.",
            "仅挂在面板上的 DragGesture 在当前档位的顶部位置上叠加带橡皮筋的位移；onEnded 计算 顶部 + 速度 × 预测时长，并以弹簧吸附到最近档位；背景用同一比例计算压暗与缩放。"
        ),
        apis: ["DragGesture.Value.velocity", "rubberBand", "offset(y:)", "spring(response:dampingFraction:)", "Haptics.selection"],
        tags: ["bottom sheet", "detent", "fling", "velocity", "底部面板", "档位", "甩动", "速度预测"],
        params: [
            .slider("projection", L("Velocity projection", "速度预测时长"), 0.0...0.4, default: 0.2, unit: "s"),
            .slider("response", L("Spring response", "弹簧响应"), 0.25...0.8, default: 0.42, unit: "s"),
            .slider("damping", L("Damping", "阻尼"), 0.5...1.0, default: 0.82),
        ]
    ) { ctx in
        DetentSheetDemo(ctx: ctx)
    }
}

private enum SheetDetent: Int, CaseIterable {
    case peek, half, full

    func top(in height: CGFloat) -> CGFloat {
        switch self {
        case .peek: return height - 74
        case .half: return height * 0.48
        case .full: return 26
        }
    }
}

private struct DetentSheetDemo: View {
    let ctx: DemoContext
    @State private var detent: SheetDetent = .peek
    @State private var translation: CGFloat = 0
    @State private var autoStep = 0
    /// True while a real finger drags the sheet.
    @State private var held = false
    /// The scripted flick, cancelled on the first real touch.
    @State private var script: Task<Void, Never>?
    /// Resets on system cancellation too, so a stolen touch never leaves the sheet between detents.
    @GestureState private var pressing = false

    private let size = CGSize(width: 230, height: 320)

    var body: some View {
        let top = displayedTop
        let peekTop = SheetDetent.peek.top(in: size.height)
        let fullTop = SheetDetent.full.top(in: size.height)
        let fraction = ((peekTop - top) / (peekTop - fullTop)).clamped(to: 0...1)

        VStack(spacing: 12) {
            ZStack(alignment: .top) {
                SheetBackdrop()
                    .scaleEffect(1 - 0.06 * fraction)
                    .overlay(Color.black.opacity(0.3 * Double(fraction)))
                sheet
                    .offset(y: top)
                    .gesture(dragGesture)
            }
            .frame(width: size.width, height: size.height)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(Palette.stroke, lineWidth: 1))
            .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
            DemoHint(text: L("Flick the sheet up or down", "上下甩动面板"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.5) { simulate() }
        .onChange(of: pressing) { _, isPressing in
            if !isPressing { endHold() }
        }
        .onDisappear { script?.cancel() }
    }

    private var displayedTop: CGFloat {
        let raw = detent.top(in: size.height) + translation
        let minTop = SheetDetent.full.top(in: size.height)
        let maxTop = SheetDetent.peek.top(in: size.height)
        if raw < minTop { return minTop + rubberBand(raw - minTop, limit: 40) }
        if raw > maxTop { return maxTop + rubberBand(raw - maxTop, limit: 40) }
        return raw
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.primary.opacity(0.25))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            Text(L("Nearby", "附近地点"), ctx.language)
                .font(.headline)
            ForEach(0..<5, id: \.self) { index in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Palette.spectrum[index % Palette.spectrum.count].gradient)
                        .frame(width: 32, height: 32)
                    PlaceholderLines(count: 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(width: size.width, height: size.height)
        .demoGlass(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous), material: .regularMaterial)
        .shadow(color: .black.opacity(0.18), radius: 12, y: -2)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { value in
                if !held {
                    held = true
                    script?.cancel()
                    script = nil
                }
                translation = value.translation.height
            }
            .onEnded { value in
                guard held else { return }
                held = false
                let projected = displayedTop + value.velocity.height * ctx.cg("projection")
                settle(at: nearestDetent(to: projected), haptic: true)
            }
    }

    /// System cancellation (no `onEnded`): zero the translation by settling on the closest detent.
    private func endHold() {
        guard held else { return }
        held = false
        settle(at: nearestDetent(to: displayedTop), haptic: false)
    }

    private func nearestDetent(to y: CGFloat) -> SheetDetent {
        var best = SheetDetent.peek
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for candidate in SheetDetent.allCases {
            let d = abs(candidate.top(in: size.height) - y)
            if d < bestDistance {
                bestDistance = d
                best = candidate
            }
        }
        return best
    }

    private func settle(at target: SheetDetent, haptic: Bool) {
        let changed = target != detent
        withAnimation(.spring(response: ctx["response"], dampingFraction: ctx["damping"])) {
            detent = target
            translation = 0
        }
        if changed && haptic && !ctx.isPreview { Haptics.selection() }
    }

    /// Cycles peek → full → half → peek: a quick pre-pull toward the target, then the settle spring.
    private func simulate() {
        guard !held else { return }
        let order: [SheetDetent] = [.full, .half, .peek]
        let target = order[autoStep % order.count]
        autoStep += 1
        let pull: CGFloat = target.top(in: size.height) - detent.top(in: size.height)
        withAnimation(.easeOut(duration: 0.22)) { translation = pull * 0.55 }
        script?.cancel()
        script = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.24))
            guard !Task.isCancelled else { return }
            settle(at: target, haptic: false)
        }
    }
}

private struct SheetBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.mint.opacity(0.55), Palette.sky.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.7))
                    .frame(width: 380, height: index % 2 == 0 ? 10 : 6)
                    .rotationEffect(.degrees(Double(index) * 47 - 30))
                    .offset(x: CGFloat(index) * 22 - 30, y: CGFloat(index) * 50 - 90)
            }
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white, Palette.red)
                .offset(x: 20, y: -40)
        }
        .frame(width: 230, height: 320)
    }
}
