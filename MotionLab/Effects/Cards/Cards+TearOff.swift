import SwiftUI

extension Effect {
    static let cardsTearOff = Effect(
        id: "cards.tear-off",
        category: .cards,
        interaction: .gesture,
        name: L("Tear-Off Calendar", "撕页日历"),
        summary: L("Pull a day-calendar sheet down: it bends on its binding, tears free and tumbles away.", "向下拉日历页：纸页沿装订处弯折，撕下后翻滚着飞走。"),
        prompt: L(
            "A 200×220 pt day-calendar pad with a dark binding strip and punched holes shows a big date. Dragging the top sheet downward bends it forward around the binding in perspective — up to 55° at 180 pt of pull — while it twists up to 6° from the top-left corner and a shade darkens its lower half, as if paper were peeling. Releasing past 90 pt tears it off with a haptic: the sheet falls 420 pt with an ease-in over 0.55 s, rotating 25° and fading out, and the next day's date is already waiting underneath. Short pulls spring back onto the binding (response 0.4 s, damping 0.6). Tactile, nostalgic and satisfying.",
            "一本 200×220 pt 的日历撕页本，顶部是深色装订条和打孔，页面上印着大大的日期。向下拖动最上面的纸页时，它以装订处为轴在透视中向前弯折——拉动 180 pt 时最多 55°——同时从左上角扭转最多 6°，下半部分逐渐加深阴影，就像纸张正在被撕开。拉过 90 pt 松手即撕下，伴随触感：纸页以缓入曲线在 0.55 秒内下落 420 pt，旋转 25° 并淡出，下面已是第二天的日期。拉动不足时则以弹簧（响应 0.4 秒、阻尼 0.6）贴回装订处。可触、怀旧、令人满足。"
        ),
        implementation: L(
            "The pull distance drives rotation3DEffect around the x-axis anchored at the top plus a small rotationEffect anchored at the top-leading corner; a torn sheet animates a separate fall state with easeIn before the day index advances.",
            "拉动距离驱动以顶部为锚点绕 x 轴的 rotation3DEffect，以及以左上角为锚点的轻微 rotationEffect；撕下的纸页使用独立的下落状态做缓入动画，之后日期序号前进。"
        ),
        apis: ["rotation3DEffect(_:axis:anchor:perspective:)", "rotationEffect(_:anchor:)", "DragGesture", "contentTransition(.numericText())"],
        tags: ["calendar", "tear", "peel", "page", "日历", "撕页", "翻页", "纸张"],
        params: [
            .slider("bend", L("Max bend", "最大弯折"), 20...80, default: 55, step: 1, decimals: 0, unit: "°"),
            .slider("threshold", L("Tear threshold", "撕下阈值"), 50...160, default: 90, step: 5, decimals: 0, unit: "pt"),
        ]
    ) { ctx in
        CardsTearOffDemo(ctx: ctx)
    }
}

private struct CardsTearOffDemo: View {
    let ctx: DemoContext
    @State private var day = 23
    @State private var pull: CGFloat = 0
    @State private var falling = false

    var body: some View {
        VStack(spacing: 22) {
            pad
            DemoHint(text: L("Pull the page down to tear it off", "向下拉动纸页将其撕下"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .autoplay(ctx.isPreview, every: 1.8) { autoTear() }
    }

    private var pad: some View {
        let progress = min(pull / 180, 1)
        let bend = Double(progress) * ctx["bend"]
        let twist = Double(progress) * 6
        return ZStack(alignment: .top) {
            CardsCalendarSheet(day: day + 1, language: ctx.language, shade: 0)
            CardsCalendarSheet(day: day, language: ctx.language, shade: Double(progress))
                .rotation3DEffect(.degrees(falling ? 70 : bend), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.5)
                .rotationEffect(.degrees(falling ? 25 : twist), anchor: .topLeading)
                .offset(y: falling ? 420 : 0)
                .opacity(falling ? 0 : 1)
                .gesture(drag)
            CardsCalendarBinding()
        }
        .frame(width: 200, height: 232, alignment: .top)
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !falling else { return }
                pull = max(value.translation.height, 0)
            }
            .onEnded { _ in
                guard !falling else { return }
                if pull > ctx.cg("threshold") {
                    tear()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { pull = 0 }
                }
            }
    }

    private func tear() {
        Haptics.tap(.rigid)
        withAnimation(.easeIn(duration: 0.55)) { falling = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                day = day >= 30 ? 1 : day + 1
                pull = 0
                falling = false
            }
        }
    }

    private func autoTear() {
        guard !falling else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { pull = 120 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { tear() }
    }
}

private struct CardsCalendarSheet: View {
    let day: Int
    let language: AppLanguage
    /// 0…1: how far the sheet is bent; darkens its lower half.
    let shade: Double

    private static let weekdays: [LocalizedText] = [
        L("Sunday", "星期日"), L("Monday", "星期一"), L("Tuesday", "星期二"), L("Wednesday", "星期三"),
        L("Thursday", "星期四"), L("Friday", "星期五"), L("Saturday", "星期六"),
    ]

    var body: some View {
        VStack(spacing: 2) {
            Text(L("SEPTEMBER", "九月"), language)
                .font(.system(size: 13, weight: .heavy))
                .tracking(2)
                .foregroundStyle(Palette.red)
            Text(verbatim: "\(day)")
                .font(.system(size: 88, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
            Text(Self.weekdays[(day + 1) % 7], language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
        .frame(width: 200, height: 220)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            LinearGradient(colors: [.clear, Color.black.opacity(0.28 * shade)], startPoint: .center, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
        .padding(.top, 12)
    }
}

private struct CardsCalendarBinding: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x3A3F55), Color(hex: 0x1B1D2B)], startPoint: .top, endPoint: .bottom))
            .frame(width: 208, height: 26)
            .overlay {
                HStack(spacing: 22) {
                    ForEach(0..<6, id: \.self) { _ in
                        Circle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 7, height: 7)
                    }
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}
