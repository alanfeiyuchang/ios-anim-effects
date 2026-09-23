import SwiftUI

enum ShaderEffects {
    static let all: [Effect] = [
        .shaderRipple,
        .shaderWave,
        .shaderPixelate,
        .shaderDissolve,
        .shaderGlitch,
        .shaderMagnifier,
        .shaderSwirl,
        .shaderPlasma,
        .shaderCRT,
        .shaderHalftone,
        .shaderGlassmorphism,
        .shaderLiquidGlassLens,
        .shaderChromatic,
        .shaderKaleidoscope,
        .shaderEdgeScan,
    ]
}

/// Colourful sample artwork that the shader demos distort.
struct ShaderArtwork: View {
    var variant: Int = 0

    private var colors: [Color] {
        variant == 0
            ? [Palette.indigo, Palette.violet, Palette.pink]
            : [Palette.mint, Palette.sky, Palette.blue]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 190, height: 190)
                .offset(x: 80, y: -100)
            Circle()
                .fill((variant == 0 ? Palette.amber : Palette.pink).opacity(0.75))
                .frame(width: 96, height: 96)
                .offset(x: -86, y: 84)
            VStack(spacing: 10) {
                Image(systemName: variant == 0 ? "sparkles" : "drop.fill")
                    .font(.system(size: 60, weight: .semibold))
                Text(variant == 0 ? "MOTION" : "SHADER")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .tracking(4)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .frame(width: 260, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

/// A grid of glyphs — reveals distortion clearly.
struct ShaderGridArtwork: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x14162B), Color(hex: 0x2A2360)], startPoint: .top, endPoint: .bottom)
            Canvas { context, size in
                let step: CGFloat = 22
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                context.stroke(path, with: .color(.white.opacity(0.18)), lineWidth: 1)
            }
            VStack(spacing: 6) {
                Text("Aa 永")
                    .font(.system(size: 64, weight: .bold, design: .serif))
                Text("The quick brown fox · 动效词典")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .opacity(0.8)
            }
            .foregroundStyle(
                LinearGradient(colors: [Palette.sky, Palette.violet, Palette.pink], startPoint: .leading, endPoint: .trailing)
            )
        }
    }
}

// MARK: - Time helper

/// Speed-scaled seconds since the view appeared, refreshed every frame.
/// Time accumulates, so changing `speed` (or resuming after `paused`) never makes the shader jump,
/// and grid previews (`preview: true`) tick at 30 fps to keep the category grid light.
struct ShaderClock<Content: View>: View {
    var paused: Bool = false
    var preview: Bool = false
    var speed: Double = 1
    @ViewBuilder var content: (Double) -> Content
    @State private var clock = BackgroundClock(start: 0)

    var body: some View {
        TimelineView(.animation(minimumInterval: MotionFrameRate.interval(preview: preview), paused: paused)) { timeline in
            content(clock.advance(to: timeline.date.timeIntervalSinceReferenceDate, speed: speed))
        }
    }
}
