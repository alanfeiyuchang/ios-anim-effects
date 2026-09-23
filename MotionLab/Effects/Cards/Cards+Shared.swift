import SwiftUI

/// Shared artwork for the Cards category (no image assets — gradients, shapes and SF Symbols only).
enum CardsArt {
    static let themes: [[Color]] = [
        [Color(hex: 0x5B5BFF), Color(hex: 0x9B5CFF), Color(hex: 0xFF6FB5)],  // Aurora
        [Color(hex: 0x2B2F45), Color(hex: 0x1B1D2B), Color(hex: 0x0E0F18)],  // Midnight
        [Color(hex: 0xFFB35C), Color(hex: 0xFF6B6B), Color(hex: 0xD9468F)],  // Sunset
        [Color(hex: 0x2BD9FE), Color(hex: 0x3A7BFF), Color(hex: 0x5B3BFF)],  // Ocean
        [Color(hex: 0x21D4A8), Color(hex: 0x1A9E9A), Color(hex: 0x215F8F)],  // Mint
        [Color(hex: 0xE9C98A), Color(hex: 0xB8894A), Color(hex: 0x6E4B2A)],  // Gold
    ]

    static let names = ["Aurora", "Midnight", "Sunset", "Ocean", "Mint", "Gold"]

    static func colors(_ index: Int) -> [Color] { themes[wrap(index, themes.count)] }
    static func name(_ index: Int) -> String { names[wrap(index, names.count)] }

    private static func wrap(_ index: Int, _ count: Int) -> Int { ((index % count) + count) % count }
}

/// A glossy payment-card illustration, designed at 250×158 pt and scaled to `width`.
struct CardsCreditCard: View {
    var theme: Int = 0
    var width: CGFloat = 250
    var last4: String = "4821"
    /// Parallax shift of the inner light blobs (used by tilt effects).
    var shift: CGSize = .zero

    var body: some View {
        face
            .frame(width: 250, height: 158)
            .scaleEffect(width / 250)
            .frame(width: width, height: width * 158 / 250)
    }

    private var face: some View {
        CardsCreditContent(name: CardsArt.name(theme), last4: last4)
            .padding(18)
            .frame(width: 250, height: 158)
            .background { CardsCreditBackground(colors: CardsArt.colors(theme), shift: shift) }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            }
    }
}

private struct CardsCreditContent: View {
    let name: String
    let last4: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 13, weight: .bold))
                Text(verbatim: name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer(minLength: 0)
                Image(systemName: "wave.3.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.85)
            }
            Spacer(minLength: 0)
            CardsChip()
            Text(verbatim: "••••  ••••  ••••  \(last4)")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .padding(.top, 12)
            HStack {
                Text(verbatim: "ALEX MORGAN")
                Spacer(minLength: 0)
                Text(verbatim: "09/29")
            }
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.2)
            .opacity(0.8)
            .padding(.top, 6)
        }
        .foregroundStyle(.white)
    }
}

private struct CardsChip: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0xF7E3A1), Color(hex: 0xC9A24B)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 34, height: 25)
            .overlay {
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.18))
                            .frame(height: 0.8)
                    }
                }
                .padding(.horizontal, 4)
            }
    }
}

private struct CardsCreditBackground: View {
    let colors: [Color]
    let shift: CGSize

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 220, height: 220)
                .blur(radius: 30)
                .offset(x: 110 + shift.width, y: -90 + shift.height)
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 22)
                .frame(width: 190, height: 190)
                .offset(x: -125 - shift.width * 0.5, y: 85 - shift.height * 0.5)
        }
    }
}
