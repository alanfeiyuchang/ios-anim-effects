import SwiftUI

extension Effect {
    static let showcaseLiftStatus = Effect(
        id: "showcase.lift-status",
        category: .showcase,
        interaction: .state,
        name: L("Live Lift Status", "缆车实时状态"),
        summary: L("A pulsing LIVE pill over lift rows whose wait times roll and flash as data streams in.", "脉冲“LIVE”标签下，缆车排队时间随数据推送滚动刷新并闪亮提示。"),
        prompt: L(
            "A dark LIFTS widget topped by a LIVE capsule whose red-orange dot emits a ring that expands to ~2.8× and fades every 1.4 s, next to an \"open\" count that rolls when it changes. Below, four lift rows each show a cable-car glyph, name, a tinted status chip (lime Open, orange Hold, grey Closed) and a wait time. Every couple of seconds one row receives new data: its wait time rolls to the new value with a numeric digit transition, the row background flashes a 14% orange wash that fades out over 0.6 s, and occasionally the chip morphs color and label. Tapping a row cycles its status with a light haptic. Calm but unmistakably live.",
            "深色“缆车”小组件顶部是 LIVE 胶囊：橙红色圆点每 1.4 秒向外扩散一圈约 2.8 倍并淡出的光环，旁边的“开放数”变化时滚动刷新。下方四行缆车，每行包含缆车图标、名称、带底色的状态标签（青柠“开放”、橙色“暂停”、灰色“关闭”）与排队时间。每隔约两秒会有一行收到新数据：排队时间以数字逐位滚动到新值，整行背景闪过 14% 的橙色光晕并在 0.6 秒内褪去，偶尔状态标签的颜色与文字也会随之形变。点击某行可循环切换状态并伴随轻触感。安静，但一眼就知道是实时的。"
        ),
        implementation: L(
            "A long-running .task loop mutates one random row inside withAnimation so numericText and the chip's interpolated colour animate; a flash id drives the row highlight, and a TimelineView draws the pulsing live dot.",
            "常驻的 .task 循环在 withAnimation 中随机修改一行数据，使 numericText 与状态标签颜色插值动画；flash 标记驱动整行高亮，TimelineView 绘制脉冲直播点。"
        ),
        apis: ["task", "contentTransition(.numericText(value:))", "contentTransition(.interpolate)", "TimelineView", "withAnimation"],
        tags: ["live", "status", "realtime", "pulse", "实时", "状态", "脉冲", "缆车"],
        params: [
            .slider("interval", L("Update interval", "刷新间隔"), 1...5, default: 2.2, unit: "s"),
            .toggle("flash", L("Row flash", "行高亮闪烁"), default: true),
            .slider("pulse", L("Pulse period", "脉冲周期"), 0.6...3.0, default: 1.4, unit: "s"),
        ]
    ) { ctx in
        SportLiftDemo(ctx: ctx)
    }
}

private struct LiftRow: Identifiable {
    let id: Int
    let name: String
    var status: Int   // 0 open, 1 hold, 2 closed
    var wait: Int
}

private struct SportLiftDemo: View {
    let ctx: DemoContext
    @State private var lifts: [LiftRow] = [
        LiftRow(id: 0, name: "Hungerburg", status: 0, wait: 4),
        LiftRow(id: 1, name: "Seegrube", status: 0, wait: 9),
        LiftRow(id: 2, name: "Hafelekar", status: 1, wait: 15),
        LiftRow(id: 3, name: "Frau Hitt", status: 2, wait: 0),
    ]
    @State private var flash: Int?
    @State private var demoStep = 0
    @State private var flashTask: Task<Void, Never>?

    private var openCount: Int { 10 + lifts.filter { $0.status == 0 }.count }

    var body: some View {
        SignatureStage {
            VStack(spacing: 0) {
                Spacer()
                card
                Spacer()
                DemoHint(text: L("Tap a lift to change its status", "点击缆车切换状态"), ctx: ctx)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task { await stream() }
        // Shows the tap interaction too: previews (and the detail intro) cycle one lift's status.
        .autoplay(ctx.isPreview, every: 2.6, delay: 1.2) {
            cycle(demoStep % lifts.count)
            demoStep += 1
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("Lifts", "缆车"), ctx.language)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Spacer(minLength: 0)
                LiftLivePill(open: openCount, period: ctx["pulse"], language: ctx.language, preview: ctx.isPreview)
            }
            VStack(spacing: 4) {
                ForEach(lifts) { lift in
                    LiftRowView(lift: lift, highlighted: flash == lift.id, language: ctx.language)
                        .contentShape(Rectangle())
                        .onTapGesture { cycle(lift.id) }
                }
            }
        }
        .padding(18)
        .frame(width: 300)
        .signatureCard()
    }

    private func cycle(_ id: Int) {
        guard let index = lifts.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.snappy(duration: 0.35)) {
            lifts[index].status = (lifts[index].status + 1) % 3
            lifts[index].wait = lifts[index].status == 2 ? 0 : Int.random(in: 2...18)
        }
        pulseRow(id)
        if !ctx.isPreview { Haptics.tap(.light) }
    }

    private func stream() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(max(ctx["interval"], 0.5)))
            guard !Task.isCancelled else { return }
            let index = Int.random(in: 0..<lifts.count)
            withAnimation(.snappy(duration: 0.4)) {
                if Double.random(in: 0...1) < 0.2 {
                    lifts[index].status = (lifts[index].status + 1) % 3
                }
                if lifts[index].status == 2 {
                    lifts[index].wait = 0
                } else {
                    lifts[index].wait = max(1, lifts[index].wait + Int.random(in: -4...5))
                }
            }
            pulseRow(lifts[index].id)
        }
    }

    private func pulseRow(_ id: Int) {
        guard ctx.bool("flash") else { return }
        withAnimation(.easeOut(duration: 0.12)) { flash = id }
        flashTask?.cancel()
        flashTask = Task {
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled, flash == id else { return }
            withAnimation(.easeOut(duration: 0.6)) { flash = nil }
        }
    }
}

private struct LiftLivePill: View {
    let open: Int
    let period: Double
    let language: AppLanguage
    let preview: Bool

    var body: some View {
        HStack(spacing: 6) {
            SportLiveDot(color: Signature.accentHot, size: 6, period: max(period, 0.3), preview: preview)
                .frame(width: 12, height: 12)
            Text(verbatim: "LIVE")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(Signature.accentHot)
            Text("\(open)/14")
                .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.white)
                .contentTransition(.numericText(value: Double(open)))
            Text(L("open", "开放"), language)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.07)))
        .overlay(Capsule().strokeBorder(Signature.hairline))
    }
}

private struct LiftRowView: View {
    let lift: LiftRow
    let highlighted: Bool
    let language: AppLanguage

    private var statusColor: Color {
        switch lift.status {
        case 0: return Signature.lime
        case 1: return Signature.accent
        default: return Color.white.opacity(0.4)
        }
    }

    private var statusText: String {
        switch lift.status {
        case 0: return L("Open", "开放")(language)
        case 1: return L("Hold", "暂停")(language)
        default: return L("Closed", "关闭")(language)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cablecar.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.8))
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.white.opacity(0.06)))
            Text(lift.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(statusText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
                .contentTransition(.interpolate)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(statusColor.opacity(0.16)))
            waitLabel
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Signature.accent.opacity(highlighted ? 0.14 : 0))
        )
    }

    private var waitLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if lift.status == 2 {
                Text(verbatim: "—")
            } else {
                Text("\(lift.wait)")
                    .contentTransition(.numericText(value: Double(lift.wait)))
            }
            Text(L("min", "分"), language)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Signature.textSecondary)
        }
        .font(Signature.number(15))
        .foregroundStyle(Color.white)
        .frame(width: 46, alignment: .trailing)
    }
}
