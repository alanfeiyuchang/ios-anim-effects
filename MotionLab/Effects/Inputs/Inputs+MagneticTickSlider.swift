import SwiftUI

extension Effect {
    static let inputsMagneticTickSlider = Effect(
        id: "inputs.magnetic-tick-slider",
        category: .inputs,
        interaction: .gesture,
        name: L("Magnetic Tick Slider", "磁吸刻度滑块"),
        summary: L("The thumb clings to each stop, then jumps to the next once you pull far enough.", "滑块会吸附在每个刻度上，拉过一半才跳到下一格。"),
        prompt: L(
            "A Text Size card: a 260 pt track with 7 stops, a 28 pt white thumb and a live \"Aa\" preview. The thumb does not follow the finger linearly — each stop is a magnet: within half a step, the thumb is pulled toward the nearest tick with a smoothstep falloff, so it lingers on the stop, then leaps across the midpoint on a tight interactive spring (response 0.18 s, damping 0.7) and clicks onto the next one with a selection haptic. Ticks under the thumb magnify like a dock (up to +10 pt within 40 pt), the active tick turns indigo, and the preview text scales smoothly to the new size. On release the thumb settles onto its stop on a bouncy spring (response 0.35 s, damping 0.6). Precise and reassuring: you can feel the grid.",
            "“文字大小”卡片：260pt 轨道分 7 档，配 28pt 白色滑块与实时“Aa”预览。滑块并不线性跟手——每个档位都是磁铁：半格范围内按 smoothstep 衰减被吸向最近刻度，于是在档位上“赖着不走”；越过中点后以紧致的交互弹簧（响应 0.18 秒、阻尼 0.7）一跃吸到下一档，并伴随选择触觉。附近刻度像程序坞一样放大（40pt 内最多加长 10pt），当前刻度变靛蓝，预览文字平滑缩放。松手后以弹性弹簧（响应 0.35 秒、阻尼 0.6）落定。能“摸到”网格。"
        ),
        implementation: L(
            "The raw finger position is stored and the displayed thumb x is derived by pulling it toward the nearest stop with a smoothstep weight; each drag update runs in an interactiveSpring transaction so the leap between stops animates.",
            "保存手指原始位置，再以 smoothstep 权重把它拉向最近档位得到滑块显示位置；每次拖动更新都放在 interactiveSpring 事务中，因此档位间的跳跃带有动画。"
        ),
        apis: ["DragGesture", "interactiveSpring(response:dampingFraction:)", "scaleEffect", "smoothstep"],
        tags: ["slider", "snap", "magnetic", "detent", "滑块", "吸附", "磁吸", "刻度"],
        params: [
            .slider("stops", L("Stops", "档位数"), 3...11, default: 7, step: 1, decimals: 0),
            .slider("strength", L("Magnet strength", "磁力"), 0...1, default: 0.9),
            .slider("response", L("Settle response", "落定响应"), 0.15...0.8, default: 0.35, unit: "s"),
        ]
    ) { ctx in
        MagneticTickSliderDemo(ctx: ctx)
    }
}

private struct MagneticTickSliderDemo: View {
    let ctx: DemoContext
    @State private var fingerX: CGFloat = 86.7
    @State private var dragging = false
    @State private var lastStop = 2
    @State private var previewStep = 0
    @State private var previewDirection: CGFloat = 1
    /// The detail intro's scripted nudge; cancelled by the first real touch and on disappear.
    @State private var introTask: Task<Void, Never>?
    /// Resets on system cancellation too (Control Center pull, incoming call), so a cancelled touch still releases.
    @GestureState private var touching = false

    private let width: CGFloat = 260

    private var stops: Int { max(ctx.int("stops"), 2) }
    private var spacing: CGFloat { width / CGFloat(stops - 1) }

    private func nearestStop(_ x: CGFloat) -> Int {
        Int((x / spacing).rounded()).clamped(to: 0...(stops - 1))
    }

    private var thumbX: CGFloat {
        let k = nearestStop(fingerX)
        let tickX: CGFloat = CGFloat(k) * spacing
        let d: CGFloat = fingerX - tickX
        let half: CGFloat = spacing / 2
        let p: CGFloat = max(0, 1 - abs(d) / half)
        let smooth: CGFloat = p * p * (3 - 2 * p)
        let pull: CGFloat = ctx.cg("strength") * smooth
        return fingerX - d * pull
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Drag slowly and feel each stop", "慢慢拖动，感受每个档位"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: stops) { _, _ in
            fingerX = CGFloat(nearestStop(fingerX)) * spacing
        }
        .autoplay(ctx.isPreview, every: 0.55, delay: 0.3) {
            // The detail intro plays one full nudge-and-settle cycle so the thumb never stays grabbed.
            if ctx.isPreview { previewTick() } else { introNudge() }
        }
        .onDisappear { stopIntro() }
    }

    private var card: some View {
        let stop = nearestStop(fingerX)
        let scale: CGFloat = 0.7 + CGFloat(stop) / CGFloat(max(stops - 1, 1)) * 0.8
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(L("Text Size", "文字大小"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text(verbatim: "Aa")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.indigo)
                    .scaleEffect(scale, anchor: .trailing)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: stop)
                    .frame(height: 40)
            }
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "textformat.size.smaller")
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Image(systemName: "textformat.size.larger")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 14, weight: .semibold))
            track
        }
        .padding(18)
        .frame(width: width + 36)
        .demoCard(cornerRadius: 24)
    }

    private var track: some View {
        let thumb = thumbX
        let active = nearestStop(fingerX)
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 6)
            Capsule()
                .fill(Palette.primary)
                .frame(width: max(thumb, 6), height: 6)
            ForEach(0..<stops, id: \.self) { index in
                tick(index: index, thumb: thumb, active: active)
            }
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                .frame(width: 28, height: 28)
                .scaleEffect(dragging ? 1.12 : 1)
                .offset(x: thumb - 14)
        }
        .frame(width: width, height: 44)
        .contentShape(Rectangle())
        .gesture(drag)
        .onChange(of: touching) { _, isTouching in
            if !isTouching { endDrag() }
        }
    }

    private func tick(index: Int, thumb: CGFloat, active: Int) -> some View {
        let x: CGFloat = CGFloat(index) * spacing
        let near: CGFloat = max(0, 1 - abs(x - thumb) / 40)
        let height: CGFloat = 8 + 10 * near
        return Capsule()
            .fill(index == active ? Palette.indigo : Color.primary.opacity(0.25))
            .frame(width: 2, height: height)
            .offset(x: x - 1, y: 18)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                stopIntro()
                let x: CGFloat = value.location.x.clamped(to: 0...width)
                withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.7)) {
                    fingerX = x
                    dragging = true
                }
                let stop = nearestStop(x)
                if stop != lastStop {
                    lastStop = stop
                    Haptics.selection()
                }
            }
            .onEnded { _ in endDrag() }
    }

    /// Single cleanup for a lifted or cancelled finger: the thumb snaps onto its stop.
    private func endDrag() {
        guard dragging else { return }
        settle()
    }

    private func settle() {
        let target: CGFloat = CGFloat(nearestStop(fingerX)) * spacing
        withAnimation(.spring(response: ctx["response"], dampingFraction: 0.6)) {
            fingerX = target
            dragging = false
        }
    }

    /// Preview: creep toward the midpoint (the thumb clings), then cross it (the thumb leaps).
    private func introNudge() {
        stopIntro()
        introTask = Task { @MainActor in
            for _ in 0..<3 {
                guard !Task.isCancelled else { return }
                previewTick()
                try? await Task.sleep(for: .seconds(0.55))
            }
            introTask = nil
        }
    }

    private func stopIntro() {
        introTask?.cancel()
        introTask = nil
    }

    private func previewTick() {
        let phase = previewStep % 3
        previewStep += 1
        let current = nearestStop(fingerX)
        if phase == 0 {
            if current >= stops - 1 { previewDirection = -1 }
            if current <= 0 { previewDirection = 1 }
        }
        let direction: CGFloat = previewDirection
        let base: CGFloat = CGFloat(current) * spacing
        switch phase {
        case 0:
            withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.7)) {
                dragging = true
                fingerX = (base + direction * spacing * 0.4).clamped(to: 0...width)
            }
        case 1:
            withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.7)) {
                fingerX = (base + direction * spacing * 0.65).clamped(to: 0...width)
            }
        default:
            settle()
        }
    }
}
