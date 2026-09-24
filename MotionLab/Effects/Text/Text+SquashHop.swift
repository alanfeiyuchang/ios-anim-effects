import SwiftUI

extension Effect {
    static let textSquashHop = Effect(
        id: "text.squash-hop",
        category: .text,
        interaction: .loop,
        name: L("Squash & Hop", "挤压弹跳字"),
        summary: L("Letters take turns jumping, stretching in the air and squashing on landing.", "字母轮流起跳，空中拉长、落地压扁。"),
        prompt: L(
            "A playful word in 50 pt heavy rounded letters sits on an implied floor, each letter with a soft elliptical contact shadow. Letters hop one after another in a travelling wave, 90 ms apart, on a 1.1 s cycle: a letter crouches for ~90 ms (squashing to 89% height) and snaps up stretched to 112% height and 92% width, rounds out to neutral at the 30 pt apex of its ~0.5 s sine arc, and stretches again as it falls. On touchdown it snaps from tall to flat, 78% height and 118% width for ~130 ms anchored to the baseline, then recoils and rests. Shadows shrink and fade while airborne; tapping a letter makes it hop out of turn with a light tick. Stretch follows speed, squash follows contact: cartoon weight and bounce.",
            "一个俏皮的单词以50 pt粗圆体排列在看不见的地面上，每个字母下方有柔和的椭圆接触阴影。字母以行进波依次起跳，间隔90毫秒，周期1.1秒：先下蹲约90毫秒、压扁到89%高，随即弹起并拉长到112%高、92%宽；沿约0.5秒的正弦弧升到30 pt顶点时恢复原形，下落时再次拉长。落地瞬间由细长猛然压扁为78%高、118%宽，以基线为锚点持续约130毫秒，随后回弹静止。腾空时阴影缩小变淡；点按字母可让它插队起跳并伴随轻触觉。拉伸随速度、挤压随接触，文字有了卡通般的重量与弹性。"
        ),
        implementation: L(
            "A TimelineView(.animation) feeds elapsed time into a pure function that maps each letter's phase to lift and a signed squash/stretch: crouch squash, then stretch = |cos| of the arc (vertical speed), then an impact squash that starts from the stretched pose. Scale is anchored at .bottom; a tapped letter adds an extra hop from its own start time.",
            "TimelineView(.animation) 把经过时间传入纯函数，将每个字母的相位映射为高度与带符号的挤压/拉伸：起跳前下蹲压扁，腾空时拉伸量取弧线的 |cos|（即竖直速度），落地挤压从拉长姿态开始。缩放以 .bottom 为锚点；点按的字母从自己的起始时间叠加一次额外弹跳。"
        ),
        apis: ["TimelineView(.animation)", "scaleEffect(x:y:anchor:)", "offset(y:)", "Ellipse"],
        tags: ["squash", "stretch", "bounce", "hop", "挤压", "拉伸", "弹跳", "卡通"],
        params: [
            .slider("height", L("Hop height", "起跳高度"), 8...50, default: 30, decimals: 0, unit: "pt"),
            .slider("squash", L("Squash amount", "挤压程度"), 0...0.4, default: 0.22),
            .slider("period", L("Cycle", "周期"), 0.6...2.4, default: 1.1, unit: "s"),
        ]
    ) { ctx in
        SquashHopDemo(ctx: ctx)
    }
}

private struct HopPose {
    var lift: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
}

private struct SquashHopDemo: View {
    let ctx: DemoContext
    /// Start time (reference-date seconds) of each letter's tapped, out-of-turn hop.
    @State private var kicks: [Int: Double] = [:]

    private var letters: [String] { (ctx.language == .zh ? "蹦蹦跳跳" : "BOUNCY").map { String($0) } }

    var body: some View {
        VStack(spacing: 22) {
            TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
                let time: Double = timeline.date.timeIntervalSinceReferenceDate
                row(time: time)
            }
            DemoHint(text: L("Tap a letter to make it hop", "点按字母让它起跳"), ctx: ctx)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(time: Double) -> some View {
        let chars = letters
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(chars.indices, id: \.self) { index in
                letter(chars[index], index: index, pose: combinedPose(time: time, index: index))
            }
        }
        .fixedSize()
        .padding(.top, ctx.cg("height") * 2.4)
    }

    private func letter(_ char: String, index: Int, pose: HopPose) -> some View {
        let height = max(ctx.cg("height"), 1)
        let air: CGFloat = min(pose.lift / height, 1)
        let shadowOpacity: Double = 0.18 * (1 - Double(air) * 0.7)
        let shadowWidth: CGFloat = 30 * (1 - air * 0.5)
        let colors: [Color] = [Palette.coral, Palette.amber, Palette.mint, Palette.sky, Palette.violet, Palette.pink]
        return VStack(spacing: 4) {
            Text(verbatim: char)
                .font(.system(size: 50, weight: .heavy, design: .rounded))
                .foregroundStyle(colors[index % colors.count].gradient)
                .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
                .offset(y: -pose.lift)
            Ellipse()
                .fill(Color.primary.opacity(shadowOpacity))
                .frame(width: shadowWidth, height: 6)
                .blur(radius: 2)
        }
        .contentShape(Rectangle())
        .onTapGesture { kick(index) }
    }

    private func kick(_ index: Int) {
        guard !ctx.isPreview else { return }
        kicks[index] = Date().timeIntervalSinceReferenceDate
        Haptics.tap()
    }

    /// The looping wave plus any tapped hop: lifts add, scale deviations multiply, so a tap
    /// mid-hop never snaps the letter back to the floor.
    private func combinedPose(time: Double, index: Int) -> HopPose {
        let period: Double = max(ctx["period"], 0.1)
        let loop = pose(phase: wrapped((time - Double(index) * 0.09) / period))
        guard let start = kicks[index] else { return loop }
        let elapsed = (time - start) / period
        guard elapsed >= 0, elapsed < 0.8 else { return loop }
        let extra = pose(phase: elapsed)
        var result = loop
        result.lift = loop.lift + extra.lift
        result.scaleX = loop.scaleX * extra.scaleX
        result.scaleY = loop.scaleY * extra.scaleY
        return result
    }

    private func wrapped(_ value: Double) -> Double {
        let u = value.truncatingRemainder(dividingBy: 1)
        return u < 0 ? u + 1 : u
    }

    /// Maps a phase (0…1) of the hop cycle to lift and squash/stretch.
    /// 0–0.08 crouch · 0.08–0.53 airborne · 0.53–0.65 impact · 0.65–0.78 recoil · rest.
    private func pose(phase: Double) -> HopPose {
        let height: CGFloat = ctx.cg("height")
        let squash: CGFloat = ctx.cg("squash")
        let stretch: CGFloat = 0.12
        let crouch: CGFloat = 1 - squash * 0.5
        var scaleY: CGFloat = 1
        var lift: CGFloat = 0
        if phase < 0.08 {
            // Take-off: sink into a squash, then snap up into the full stretch.
            let q = CGFloat(phase / 0.08)
            if q < 0.6 {
                scaleY = 1 - (1 - crouch) * CGFloat(sin(Double.pi / 2 * Double(q / 0.6)))
            } else {
                let t = (q - 0.6) / 0.4
                scaleY = crouch + (1 + stretch - crouch) * t * t
            }
        } else if phase < 0.53 {
            // Airborne: stretch follows vertical speed, so it is round at the apex.
            let a = Double.pi * (phase - 0.08) / 0.45
            lift = height * CGFloat(sin(a))
            scaleY = 1 + stretch * CGFloat(abs(cos(a)))
        } else if phase < 0.65 {
            // Impact: from the stretched pose straight to flat, then release.
            let q = CGFloat((phase - 0.53) / 0.12)
            if q < 0.3 {
                let t = q / 0.3
                scaleY = (1 + stretch) + (-stretch - squash) * (1 - (1 - t) * (1 - t))
            } else {
                let t = (q - 0.3) / 0.7
                scaleY = (1 - squash) + squash * t * t * (3 - 2 * t)
            }
        } else if phase < 0.78 {
            let recoil = CGFloat(sin(Double.pi * (phase - 0.65) / 0.13))
            scaleY = 1 + squash * 0.25 * recoil
        }
        // Keep the volume roughly constant: thin when tall, wide when flat.
        let dy = scaleY - 1
        let scaleX: CGFloat = dy > 0 ? 1 - dy * 0.67 : 1 - dy * 0.82
        return HopPose(lift: lift, scaleX: scaleX, scaleY: scaleY)
    }
}
