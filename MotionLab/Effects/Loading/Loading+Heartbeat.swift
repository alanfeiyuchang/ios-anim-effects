import SwiftUI

// MARK: - ECG heartbeat

extension Effect {
    static let loadingHeartbeat = Effect(
        id: "loading.heartbeat",
        category: .loading,
        interaction: .loop,
        name: L("ECG Heartbeat", "心电脉冲"),
        summary: L("A monitor-style trace redraws itself as a write head sweeps, and the heart beats on every spike.", "监护仪式的波形随扫描头重绘，每个尖峰都让心形跳动一次。"),
        prompt: L(
            "A 'Measuring heart rate' card holds a 260 × 90 pt strip over a faint 13 pt grid. A write head sweeps left to right, redrawing a PQRST trace — small P bump, sharp R spike that nearly touches the top of the strip, S dip and rounded T wave — at 72 BPM, 2.5 beats per strip width. The line behind the head fades from 100% to 0% over one full sweep, and a small gap ahead of the head erases the old trace, exactly like a bedside monitor. A red heart pops 1.0 → 1.25 → 1.0 in 0.3 s each time the head crosses an R peak, and the BPM readout sits beside it. Clinical, rhythmic, alive.",
            "一张“正在测量心率”卡片中是一条 260 × 90 pt 的波形带，底部铺着 13 pt 的淡色网格。扫描头从左向右移动，以 72 BPM 重绘 PQRST 波形——小小的 P 波、几乎触到波形带顶部的尖锐 R 峰、S 谷与圆润的 T 波——每个带宽容纳 2.5 拍。扫描头身后的线条在一整次扫描内从 100% 渐隐到 0%，扫描头前方留出一小段空隙抹掉旧波形，与床旁监护仪一模一样。每当扫描头越过 R 峰，红色心形在 0.3 秒内 1.0 → 1.25 → 1.0 跳动一次，旁边是 BPM 读数。专业、有节律、充满生命感。"
        ),
        implementation: L(
            "A TimelineView drives a Canvas that walks the strip in 2 pt steps, evaluating a piecewise PQRST function and stroking short segments whose opacity depends on their age behind the head.",
            "TimelineView 驱动 Canvas 以 2 pt 步长遍历波形带，计算分段 PQRST 函数，并按距扫描头的“年龄”设置每一小段描边的透明度。"
        ),
        apis: ["TimelineView", "Canvas", "GraphicsContext.stroke", "scaleEffect"],
        tags: ["ecg", "heartbeat", "pulse", "health", "心电图", "心跳", "脉搏", "健康"],
        params: [
            .slider("bpm", L("Heart rate", "心率"), 40...160, default: 72, step: 1, decimals: 0, unit: " BPM"),
            .slider("beats", L("Beats per strip", "每屏拍数"), 1.5...5, default: 2.5, decimals: 1),
            .toggle("grid", L("Grid", "网格"), default: true),
        ]
    ) { ctx in
        HeartbeatDemo(ctx: ctx)
    }
}

private struct HeartbeatDemo: View {
    let ctx: DemoContext

    var body: some View {
        let zh = ctx.language == .zh
        let bpm: Double = max(ctx["bpm"], 20)
        let beats: Double = max(ctx["beats"], 0.5)
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let t: Double = timeline.date.timeIntervalSinceReferenceDate
            let beatTime: Double = 60 / bpm
            let sweep: Double = beatTime * beats
            let head: Double = (t / sweep).truncatingRemainder(dividingBy: 1)
            // Beat phase under the write head, so the heart pops exactly when the head crosses an R peak.
            let headBeat: Double = (head * beats).truncatingRemainder(dividingBy: 1)
            let sinceR: Double = (headBeat - 0.32 + 1).truncatingRemainder(dividingBy: 1) * beatTime
            VStack(alignment: .leading, spacing: 14) {
                header(zh: zh, bpm: bpm, sinceR: max(sinceR, 0))
                ECGStrip(head: head, beats: beats, grid: ctx.bool("grid"))
                    .frame(width: 260, height: 90)
                Text(zh ? "请保持手指贴合传感器" : "Keep your finger on the sensor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .demoCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func header(zh: Bool, bpm: Double, sinceR: Double) -> some View {
        // Pop 1.0 → 1.25 → 1.0 over the 0.3 s after each R peak.
        let pop: CGFloat = sinceR < 0.3 ? CGFloat(sin(sinceR / 0.3 * .pi)) * 0.25 : 0
        return HStack(alignment: .center, spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 22))
                .foregroundStyle(Palette.red)
                .scaleEffect(1 + pop)
                .shadow(color: Palette.red.opacity(Double(pop) * 2), radius: 8)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(zh ? "正在测量心率" : "Measuring heart rate")
                    .font(.subheadline.weight(.semibold))
                Text("\(Int(bpm.rounded())) BPM")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ECGStrip: View {
    let head: Double
    let beats: Double
    let grid: Bool

    var body: some View {
        Canvas { context, size in
            if grid { drawGrid(context, size: size) }
            let step: CGFloat = 2
            let count: Int = Int(size.width / step)
            let headX: CGFloat = size.width * CGFloat(head)
            var previous: CGPoint?
            for i in 0...count {
                let x: CGFloat = CGFloat(i) * step
                let y: CGFloat = ECGStrip.y(x: x, size: size, beats: beats)
                let point = CGPoint(x: x, y: y)
                var behind: CGFloat = headX - x
                if behind < 0 { behind += size.width }
                let age: Double = Double(behind / size.width)
                if let from = previous, age < 0.94 {
                    var segment = Path()
                    segment.move(to: from)
                    segment.addLine(to: point)
                    context.stroke(segment, with: .color(Palette.red.opacity(1 - age)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                }
                previous = point
            }
            let headY: CGFloat = ECGStrip.y(x: headX, size: size, beats: beats)
            let dot = CGRect(x: headX - 3.5, y: headY - 3.5, width: 7, height: 7)
            context.fill(Path(ellipseIn: dot.insetBy(dx: -4, dy: -4)), with: .color(Palette.red.opacity(0.2)))
            context.fill(Path(ellipseIn: dot), with: .color(Palette.red))
        }
    }

    private func drawGrid(_ context: GraphicsContext, size: CGSize) {
        var path = Path()
        var x: CGFloat = 0
        while x <= size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += 13
        }
        var y: CGFloat = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += 13
        }
        context.stroke(path, with: .color(.primary.opacity(0.06)), lineWidth: 0.5)
    }

    static func y(x: CGFloat, size: CGSize, beats: Double) -> CGFloat {
        let raw: Double = Double(x / size.width) * beats
        let u: Double = raw - floor(raw)
        let value: Double = pqrst(u)
        let baseline: CGFloat = size.height * 0.68
        let amplitude: CGFloat = size.height * 0.62
        return baseline - CGFloat(value) * amplitude
    }

    /// One heartbeat on u ∈ [0, 1): P bump, QRS complex around 0.3, T wave.
    static func pqrst(_ u: Double) -> Double {
        if u > 0.1 && u < 0.2 { return 0.1 * sin((u - 0.1) / 0.1 * .pi) }
        if u >= 0.26 && u < 0.29 { return -0.12 * (u - 0.26) / 0.03 }
        if u >= 0.29 && u < 0.32 { return -0.12 + 1.22 * (u - 0.29) / 0.03 }
        if u >= 0.32 && u < 0.35 { return 1.1 - 1.4 * (u - 0.32) / 0.03 }
        if u >= 0.35 && u < 0.38 { return -0.3 + 0.3 * (u - 0.35) / 0.03 }
        if u > 0.48 && u < 0.66 { return 0.2 * sin((u - 0.48) / 0.18 * .pi) }
        return 0
    }
}
