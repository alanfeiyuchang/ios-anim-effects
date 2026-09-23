import SwiftUI

extension Effect {
    static let inputsInchwormToggle = Effect(
        id: "inputs.inchworm-toggle",
        category: .inputs,
        interaction: .tap,
        name: L("Inchworm Toggle", "尺蠖开关"),
        summary: L("The knob reaches ahead with its front edge, then pulls its tail after it.", "旋钮先伸出前端，再把尾部拽过去，像尺蠖一样爬行。"),
        prompt: L(
            "A wide 104 × 52 pt pill switch for Low Power Mode with a 42 pt white knob. Instead of sliding, the knob crawls like an inchworm: on tap its leading edge shoots to the far end on a fast spring (response 0.3 s, damping 0.72) so the knob becomes a long capsule spanning the track and thins to 36 pt, then after ~140 ms its trailing edge catches up on a softer spring (response 0.42 s, damping 0.62) and the knob rounds out again with a small overshoot. The track fills with an amber-to-coral gradient as the head arrives and a light haptic ticks on landing; switching off crawls back the same way, tail-first reversed. Organic, a little cheeky, clearly directional.",
            "“低电量模式”设置行里有一枚 104 × 52pt 的宽胶囊开关，白色旋钮直径 42pt。旋钮并不平移，而是像尺蠖一样爬行：点击后它的前缘先以快速弹簧（响应 0.3 秒、阻尼 0.72）冲到另一端，整个旋钮被拉成横跨轨道的长胶囊并变细到 36pt；约 140 毫秒后尾缘再以更柔和的弹簧（响应 0.42 秒、阻尼 0.62）跟上，旋钮重新缩回圆形并带一点过冲。头部到达时轨道渐变为琥珀到珊瑚色，落定时给出一次轻触觉；关闭时以同样的方式反向爬回。有机、俏皮，方向感清晰。"
        ),
        implementation: L(
            "The knob is a Capsule positioned by two stored edges; the head edge is set in one spring transaction and the tail edge in a second one after a short Task delay, so the frame stretches and contracts.",
            "旋钮是一个由前后两条边缘定位的 Capsule：前缘在第一个弹簧事务中更新，尾缘在短暂 Task 延迟后于第二个事务中更新，于是 frame 先拉长再收缩。"
        ),
        apis: ["Capsule", "frame(width:height:)", "spring(response:dampingFraction:)", "Task.sleep"],
        tags: ["toggle", "switch", "inchworm", "stretch", "开关", "尺蠖", "拉伸", "爬行"],
        params: [
            .slider("lag", L("Tail lag", "尾部延迟"), 0.04...0.3, default: 0.14, unit: "s"),
            .slider("head", L("Head response", "前缘响应"), 0.15...0.6, default: 0.3, unit: "s"),
            .slider("tail", L("Tail response", "尾部响应"), 0.2...0.8, default: 0.42, unit: "s"),
        ]
    ) { ctx in
        InchwormToggleDemo(ctx: ctx)
    }
}

private struct InchwormToggleDemo: View {
    let ctx: DemoContext
    @State private var isOn = false
    @State private var leftEdge: CGFloat = 5
    @State private var rightEdge: CGFloat = 47
    @State private var stretched = false
    @State private var generation = 0

    private let trackWidth: CGFloat = 104
    private let trackHeight: CGFloat = 52
    private let inset: CGFloat = 5
    private var knob: CGFloat { trackHeight - inset * 2 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
            Spacer()
            DemoHint(text: L("Tap the switch", "点击开关"), ctx: ctx)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.4, delay: 0.4) { toggle() }
    }

    private var card: some View {
        HStack(spacing: 12) {
            Image(systemName: isOn ? "battery.25percent" : "battery.75percent")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(L("Low Power", "低电量模式"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(isOn ? L("Saving energy", "正在省电") : L("Off", "已关闭"), ctx.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
            track
        }
        .padding(16)
        .frame(width: 310)
        .demoCard(cornerRadius: 24)
    }

    private var track: some View {
        let width: CGFloat = max(rightEdge - leftEdge, 1)
        let height: CGFloat = stretched ? knob - 6 : knob
        return ZStack(alignment: .leading) {
            Capsule().fill(Color.primary.opacity(0.12))
            Capsule()
                .fill(LinearGradient(colors: [Palette.amber, Palette.coral], startPoint: .leading, endPoint: .trailing))
                .opacity(isOn ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isOn)
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                .frame(width: width, height: height)
                .offset(x: leftEdge)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Capsule())
        .onTapGesture { toggle() }
    }

    private func toggle() {
        generation += 1
        let current = generation
        let turningOn = !isOn
        let head = Animation.spring(response: ctx["head"], dampingFraction: 0.72)
        let tail = Animation.spring(response: ctx["tail"], dampingFraction: 0.62)
        let offStart: CGFloat = inset
        let muted = ctx.isPreview || Haptics.isMuted
        let onStart: CGFloat = trackWidth - inset - knob
        withAnimation(head) {
            isOn = turningOn
            stretched = true
            if turningOn {
                rightEdge = trackWidth - inset
            } else {
                leftEdge = offStart
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(ctx["lag"]))
            guard current == generation else { return }
            if !muted { Haptics.tap() }
            withAnimation(tail) {
                stretched = false
                if turningOn {
                    leftEdge = onStart
                } else {
                    rightEdge = offStart + knob
                }
            }
        }
    }
}
