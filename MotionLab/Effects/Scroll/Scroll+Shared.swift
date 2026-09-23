import SwiftUI

/// Shared sample content for the Scroll & Lists category.
enum ScrollKit {
    static let titles: [LocalizedText] = [
        L("Aurora", "极光"), L("Nebula", "星云"), L("Lagoon", "泻湖"), L("Ember", "余烬"),
        L("Tundra", "冻原"), L("Monsoon", "季风"), L("Solstice", "至日"), L("Cirrus", "卷云"),
        L("Meridian", "子午线"), L("Halcyon", "翠鸟"), L("Zenith", "天顶"), L("Drift", "漂流"),
    ]

    static let symbols: [String] = [
        "sparkles", "moon.stars.fill", "water.waves", "flame.fill", "snowflake", "cloud.rain.fill",
        "sun.max.fill", "cloud.fill", "globe.europe.africa.fill", "bird.fill", "star.fill", "leaf.fill",
    ]

    static func title(_ index: Int) -> LocalizedText { titles[wrap(index, titles.count)] }

    static func subtitle(_ index: Int) -> LocalizedText {
        let count = 6 + (wrap(index, 97) * 7) % 30
        return L("\(count) items · Updated today", "\(count) 项 · 今日更新")
    }

    static func symbol(_ index: Int) -> String { symbols[wrap(index, symbols.count)] }

    static func colors(_ index: Int) -> [Color] {
        let spectrum = Palette.spectrum
        let k = wrap(index, spectrum.count)
        return [spectrum[k], spectrum[(k + 1) % spectrum.count]]
    }

    static func time(_ index: Int) -> String {
        let i = wrap(index, 997)
        return String(format: "%d:%02d", 8 + i % 4, (i * 13) % 60)
    }

    private static func wrap(_ index: Int, _ count: Int) -> Int { ((index % count) + count) % count }
}

/// A compact list row: gradient icon tile, title, subtitle and optional timestamp.
struct ScrollKitRow: View {
    let index: Int
    let language: AppLanguage
    var showsMeta: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            ScrollKitIcon(index: index)
            VStack(alignment: .leading, spacing: 3) {
                Text(ScrollKit.title(index), language)
                    .font(.subheadline.weight(.semibold))
                Text(ScrollKit.subtitle(index), language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if showsMeta {
                Text(verbatim: ScrollKit.time(index))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.stroke))
    }
}

/// Rounded-square gradient icon with an SF Symbol.
struct ScrollKitIcon: View {
    let index: Int
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: ScrollKit.symbol(index))
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: ScrollKit.colors(index), startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
    }
}

/// Flexible gradient artwork used by carousels. Callers set the frame and clip it.
struct ScrollKitArt: View {
    let index: Int
    let language: AppLanguage
    var showsTitle: Bool = true

    var body: some View {
        LinearGradient(colors: ScrollKit.colors(index), startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay { ScrollKitArtDecor(index: index) }
            .overlay(alignment: .bottomLeading) {
                if showsTitle { caption }
            }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ScrollKit.title(index), language)
                .font(.headline.weight(.bold))
            Text(ScrollKit.subtitle(index), language)
                .font(.caption.weight(.medium))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.28)], startPoint: .top, endPoint: .bottom))
    }
}

private struct ScrollKitArtDecor: View {
    let index: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 150, height: 150)
                .blur(radius: 22)
                .offset(x: 50, y: -60)
            Circle()
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 14)
                .frame(width: 120, height: 120)
                .offset(x: -60, y: 70)
            Image(systemName: ScrollKit.symbol(index))
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .offset(y: -12)
        }
    }
}
