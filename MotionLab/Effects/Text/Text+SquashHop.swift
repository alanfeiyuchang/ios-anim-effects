import SwiftUI

extension Effect {
    static let textSquashHop = Effect(
        id: "text.squash-hop",
        category: .text,
        interaction: .loop,
        name: L("Squash & Hop", "挤压弹跳字"),
        summary: L("Letters take turns jumping, stretching in the air and squashing on landing.", "字母轮流起跳，空中拉长、落地压扁。"),
        prompt: L(
            "A playful word in 50 pt heavy rounded letters sits on an implied floor, each letter with a soft elliptical contact shadow. Letters hop one after another in a travelling wave, 90 ms apart, on a 1.1 s cycle: during the first 45% of its cycle a letter rises up to 30 pt on a sine arc while stretching to 112% height and 92% width; on touchdown it squashes to 78% height and 118% width for ~130 ms, anchored to the baseline, then springs back to neutral and rests. Shadows shrink and fade while their letter is airborne. Classic cartoon squash-and-stretch gives the type weight, elasticity and a cheerful rhythm.",
            "一个俏皮的单词以 50 pt 粗圆体排列在一条看不见的地面上，每个字母下方都有一块柔和的椭圆接触阴影。字母以行进波的方式依次起跳，间隔 90 毫秒，周期 1.1 秒：在各自周期的前 45% 里，字母沿正弦弧线升高最多 30 pt，同时纵向拉长到 112%、横向收窄到 92%；落地瞬间以基线为锚点压扁到 78% 高、118% 宽，持续约 130 毫秒，再弹回原形并静止等待。字母腾空时，阴影随之缩小变淡。经典的「挤压与拉伸」让文字有了重量、弹性和欢快的节奏。"
        ),
        implementation: L(
            "A TimelineView(.animation) feeds elapsed time into a pure function that maps each letter's phase to height, x/y scale and shadow size; scale is anchored at .bottom so squashes plant on the baseline.",
            "TimelineView(.animation) 把经过时间传入一个纯函数，将每个字母的相位映射为高度、横纵缩放与阴影大小；缩放以 .bottom 为锚点，使压扁时牢牢贴住基线。"
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

    private var letters: [String] { (ctx.language == .zh ? "蹦蹦跳跳" : "BOUNCY").map { String($0) } }

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: ctx.isPreview))) { timeline in
            let time: Double = timeline.date.timeIntervalSinceReferenceDate
            row(time: time)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(time: Double) -> some View {
        let chars = letters
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(chars.indices, id: \.self) { index in
                letter(chars[index], index: index, pose: pose(time: time, index: index))
            }
        }
        .fixedSize()
        .padding(.top, ctx.cg("height"))
    }

    private func letter(_ char: String, index: Int, pose: HopPose) -> some View {
        let air: CGFloat = ctx.cg("height") > 0 ? pose.lift / ctx.cg("height") : 0
        let colors: [Color] = [Palette.coral, Palette.amber, Palette.mint, Palette.sky, Palette.violet, Palette.pink]
        return VStack(spacing: 4) {
            Text(verbatim: char)
                .font(.system(size: 50, weight: .heavy, design: .rounded))
                .foregroundStyle(colors[index % colors.count].gradient)
                .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
                .offset(y: -pose.lift)
            Ellipse()
                .fill(Color.primary.opacity(0.18 * (1 - air * 0.7)))
                .frame(width: 30 * (1 - air * 0.5), height: 6)
                .blur(radius: 2)
        }
    }

    /// Maps a letter's phase in its cycle to lift and squash/stretch.
    private func pose(time: Double, index: Int) -> HopPose {
        let period: Double = max(ctx["period"], 0.1)
        let shifted: Double = time - Double(index) * 0.09
        let u: Double = (shifted / period).truncatingRemainder(dividingBy: 1)
        let phase: Double = u < 0 ? u + 1 : u
        let height: CGFloat = ctx.cg("height")
        let squash: CGFloat = ctx.cg("squash")
        var result = HopPose()
        if phase < 0.45 {
            let arc = CGFloat(sin(Double.pi * phase / 0.45))
            result.lift = height * arc
            result.scaleY = 1 + 0.12 * arc
            result.scaleX = 1 - 0.08 * arc
        } else if phase < 0.57 {
            let impact = CGFloat(sin(Double.pi * (phase - 0.45) / 0.12))
            result.scaleY = 1 - squash * impact
            result.scaleX = 1 + squash * 0.8 * impact
        } else if phase < 0.7 {
            let recoil = CGFloat(sin(Double.pi * (phase - 0.57) / 0.13))
            result.scaleY = 1 + squash * 0.25 * recoil
            result.scaleX = 1 - squash * 0.15 * recoil
        }
        return result
    }
}
