import SwiftUI

/// Shared deck content for the card-swipe variations (gradients, SF Symbols and bilingual captions only).
enum CardsDeck {
    struct Item {
        let title: LocalizedText
        let detail: LocalizedText
        let symbol: String
        let colors: [Color]
    }

    static let items: [Item] = [
        Item(title: L("Kyoto", "京都"), detail: L("Temples · 4 days", "古寺 · 4 天"), symbol: "leaf.fill", colors: [Color(hex: 0xFFB36B), Color(hex: 0xFF5F8F)]),
        Item(title: L("Reykjavík", "雷克雅未克"), detail: L("Aurora · 3 nights", "极光 · 3 晚"), symbol: "sparkles", colors: [Color(hex: 0x4ED6A0), Color(hex: 0x2A9DF4)]),
        Item(title: L("Lisbon", "里斯本"), detail: L("Trams · 5 days", "电车 · 5 天"), symbol: "tram.fill", colors: [Color(hex: 0xFFC247), Color(hex: 0xFF7A45)]),
        Item(title: L("Patagonia", "巴塔哥尼亚"), detail: L("Peaks · 8 days", "山峰 · 8 天"), symbol: "mountain.2.fill", colors: [Color(hex: 0x3AC4FF), Color(hex: 0x4F7CFF)]),
        Item(title: L("Marrakesh", "马拉喀什"), detail: L("Souks · 4 days", "市集 · 4 天"), symbol: "sun.max.fill", colors: [Color(hex: 0xA46BFF), Color(hex: 0x6E7BFF)]),
        Item(title: L("Bali", "巴厘岛"), detail: L("Surf · 6 days", "冲浪 · 6 天"), symbol: "water.waves", colors: [Color(hex: 0x21D4A8), Color(hex: 0x1A9E9A)]),
    ]

    static func item(_ index: Int) -> Item {
        let count = items.count
        return items[((index % count) + count) % count]
    }
}

/// A tall destination card used by the swipe variations: gradient, big glyph and a caption.
struct CardsDeckFace: View {
    let index: Int
    let language: AppLanguage
    var width: CGFloat = 190
    var height: CGFloat = 240

    var body: some View {
        let item = CardsDeck.item(index)
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: width * 0.9, height: width * 0.9)
                .blur(radius: 24)
                .offset(x: width * 0.35, y: -height * 0.35)
            Image(systemName: item.symbol)
                .font(.system(size: width * 0.36, weight: .light))
                .foregroundStyle(Color.white.opacity(0.94))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -height * 0.1)
            LinearGradient(colors: [.clear, .black.opacity(0.42)], startPoint: .center, endPoint: .bottom)
            caption(item)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
    }

    private func caption(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title, language)
                .font(.headline.weight(.bold))
            Text(item.detail, language)
                .font(.caption.weight(.medium))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(14)
    }

    private typealias Item = CardsDeck.Item
}
