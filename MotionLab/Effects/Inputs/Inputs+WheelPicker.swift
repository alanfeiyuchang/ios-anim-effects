import SwiftUI

extension Effect {
    static let inputsWheelPicker = Effect(
        id: "inputs.wheel-picker",
        category: .inputs,
        interaction: .scroll,
        name: L("3D Time Wheel", "3D 时间滚轮"),
        summary: L(
            "Hour and minute drums that curve away in 3D, snap to each row and tick under your thumb.",
            "小时与分钟滚筒在 3D 中向后弯曲，逐行吸附，并随拇指发出触感。"
        ),
        prompt: L(
            "A wake-up alarm card with two custom drum wheels (hours and minutes) behind a soft selection band. Rows are 36 pt tall; as a row moves away from the center it tilts back around the X axis up to ~60° with perspective, shrinks to ~82% and fades to ~35%, all mapped directly to its scroll position, so the list reads as a cylinder. Top and bottom edges dissolve through a gradient mask. Flicks decelerate naturally and always settle exactly on a row (view-aligned snapping), and every row that crosses the band ticks a selection haptic. The header's “Rings in 8 h 50 min” updates with a numeric roll as the wheels land. Familiar, mechanical and satisfying — a hand-built take on the system wheel.",
            "起床闹钟卡片中是两个自定义滚筒（小时与分钟），背后是一条柔和的选中条。每行高 36pt；行离开中心时，会按滚动位置直接映射，绕 X 轴向后倾斜最多约 60°（带透视），缩小到约 82%，透明度降到约 35%，让列表读起来像一个圆柱。上下边缘通过渐变遮罩自然消隐。快速拨动后自然减速，并总是精确停在某一行（按视图对齐吸附），每一行经过选中条都会触发一次选择触感。标题中的“8 小时 50 分钟后响铃”随滚轮落定以数字滚动更新。熟悉、机械、令人满足——一个手工打造的系统滚轮。"
        ),
        implementation: L(
            "Each drum is a ScrollView + LazyVStack with scrollTargetLayout, .viewAligned snapping, scrollPosition(id:anchor: .center) and vertical contentMargins that center the first and last rows; scrollTransition maps phase.value to rotation3DEffect, scale and opacity, and a Haptics.selection() tick answers each change the finger makes.",
            "每个滚筒是 ScrollView + LazyVStack，配合 scrollTargetLayout、.viewAligned 吸附、scrollPosition(id:anchor: .center)，并用纵向 contentMargins 让首尾行也能居中；scrollTransition 把 phase.value 映射为 rotation3DEffect、缩放与透明度；手指带来的每次变化都触发一次 Haptics.selection() 触感。"
        ),
        apis: ["scrollTransition", "rotation3DEffect", "scrollTargetBehavior(.viewAligned)", "scrollPosition(id:anchor:)"],
        tags: ["picker", "wheel", "time picker", "3d", "滚轮", "选择器", "时间", "闹钟"],
        params: [
            .slider("tilt", L("Drum curvature", "滚筒弧度"), 20...80, default: 60, decimals: 0, unit: "°"),
            .slider("fade", L("Edge fade", "边缘淡出"), 0.2...0.9, default: 0.65),
            .slider("shrink", L("Edge shrink", "边缘缩小"), 0...0.35, default: 0.18),
        ]
    ) { ctx in
        InputWheelPickerDemo(ctx: ctx)
    }
}

private struct InputWheelPickerDemo: View {
    let ctx: DemoContext
    @State private var hour: Int?
    @State private var minute: Int?
    @State private var step = 0
    /// Programmatic moves (first layout, autoplay, the detail intro) set this so they don't tick the haptic.
    @State private var quietUntil = Date.distantPast

    init(ctx: DemoContext) {
        self.ctx = ctx
        // Still snapshots never run `onAppear`, so seed the resting time directly.
        _hour = State(initialValue: ctx.isStill ? 7 : nil)
        _minute = State(initialValue: ctx.isStill ? 25 : nil)
    }

    /// "Now" is fixed so the countdown reads the same for everyone.
    private static let now = 22 * 60 + 35
    private static let previewTimes: [(Int, Int)] = [(6, 45), (9, 10), (7, 30), (5, 55)]

    private var style: InputWheelStyle {
        InputWheelStyle(tilt: ctx["tilt"], fade: ctx["fade"], shrink: ctx["shrink"])
    }

    private var minutesUntil: Int {
        let target = (hour ?? 7) * 60 + (minute ?? 25)
        return (target - Self.now + 1440) % 1440
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
            Spacer(minLength: 0)
            DemoHint(text: L("Flick either wheel", "上下拨动任一滚轮"), ctx: ctx)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Setting the positions after the first layout scrolls both drums to them.
            quietUntil = Date.now.addingTimeInterval(0.6)
            if hour == nil { hour = 7 }
            if minute == nil { minute = 25 }
        }
        .onChange(of: hour) { old, _ in
            if userMoved(old) { Haptics.selection() }
        }
        .onChange(of: minute) { old, _ in
            if userMoved(old) { Haptics.selection() }
        }
        .autoplay(ctx.isPreview, every: 1.6, delay: 0.6) { previewTick() }
    }

    private var card: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(Palette.coral)
                Text(L("Wake-up", "起床闹钟"), ctx.language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text(countdown)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(minutesUntil)))
                    .animation(.snappy, value: minutesUntil)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.07))
                    .frame(height: 38)
                HStack(spacing: 4) {
                    InputWheelColumn(values: Array(0..<24), selection: $hour, style: style)
                    Text(verbatim: ":")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .offset(y: -2)
                    InputWheelColumn(values: Array(0..<60), selection: $minute, style: style)
                }
            }
            .frame(height: 190)
        }
        .padding(18)
        .frame(width: 290)
        .demoCard(cornerRadius: 24)
    }

    private var countdown: String {
        let h = minutesUntil / 60
        let m = minutesUntil % 60
        return ctx.language == .zh ? "\(h) 小时 \(m) 分钟后响铃" : "Rings in \(h) h \(m) min"
    }

    private func userMoved(_ old: Int?) -> Bool {
        !ctx.isPreview && old != nil && Date.now >= quietUntil
    }

    private func previewTick() {
        let time = Self.previewTimes[step % Self.previewTimes.count]
        step += 1
        quietUntil = Date.now.addingTimeInterval(1.1)
        withAnimation(.smooth(duration: 0.8)) {
            hour = time.0
            minute = time.1
        }
    }
}

private struct InputWheelStyle {
    let tilt: Double
    let fade: Double
    let shrink: Double
}

/// One drum: snapping rows that tilt back in 3D as they leave the center band.
private struct InputWheelColumn: View {
    let values: [Int]
    @Binding var selection: Int?
    let style: InputWheelStyle

    private let rowHeight: CGFloat = 36
    private let height: CGFloat = 190
    private let width: CGFloat = 76

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(values, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                        .frame(width: width, height: rowHeight)
                        .scrollTransition(.interactive, axis: .vertical) { content, phase in
                            content
                                .rotation3DEffect(
                                    .degrees(-phase.value * style.tilt),
                                    axis: (x: 1, y: 0, z: 0),
                                    perspective: 0.5
                                )
                                .scaleEffect(1 - abs(phase.value) * style.shrink)
                                .opacity(1 - abs(phase.value) * style.fade)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selection, anchor: .center)
        // Half the viewport minus half a row, so the first and last values can reach the band.
        .contentMargins(.vertical, (height - rowHeight) / 2, for: .scrollContent)
        .frame(width: width, height: height)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.28),
                    .init(color: .black, location: 0.72),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
