import SwiftUI

/// Every demo is authored against this square canvas; previews scale it down.
enum StageMetrics {
    static let previewCanvas: CGFloat = 340
    static let detailHeight: CGFloat = 400
}

/// Live, non-interactive thumbnail of an effect's demo.
struct PreviewStage: View {
    let effect: Effect
    var cornerRadius: CGFloat = 18
    @Environment(\.appLanguage) private var language

    var body: some View {
        GeometryReader { proxy in
            let side = StageMetrics.previewCanvas
            let scale = proxy.size.width / side
            effect.makeDemo(DemoContext(params: effect.defaultParams, isPreview: true, language: language))
                .frame(width: side, height: side)
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(StageBackground())
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Neutral stage behind every demo.
struct StageBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Palette.surface
            RadialGradient(
                colors: [Color.white.opacity(scheme == .dark ? 0.06 : 0.7), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 320
            )
        }
    }
}

struct EffectCard: View {
    let effect: Effect
    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreviewStage(effect: effect)
                .overlay(alignment: .topTrailing) {
                    if favorites.contains(effect.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Palette.pink, in: Circle())
                            .padding(8)
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(effect.name, language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if effect.requirement != nil {
                        Text(effect.requirement ?? "")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Palette.violet.opacity(0.18), in: Capsule())
                            .foregroundStyle(Palette.violet)
                    }
                }
                Text(effect.summary, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .padding(.bottom, 4)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct EffectGrid: View {
    let effects: [Effect]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 14)], spacing: 14) {
            ForEach(effects) { effect in
                EffectLink(effect: effect) {
                    EffectCard(effect: effect)
                }
            }
        }
    }
}

/// Capsule filter chip.
struct Chip: View {
    let title: String
    var symbol: String? = nil
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol).font(.caption.weight(.semibold))
                }
                Text(title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background {
                Capsule().fill(isSelected ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.surface))
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}

/// Small rounded tag label.
struct TagLabel: View {
    let text: String
    var monospaced = false

    var body: some View {
        Text(text)
            .font(monospaced ? .caption.monospaced() : .caption)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Palette.surface, in: Capsule())
            .foregroundStyle(.secondary)
    }
}

/// Simple flow layout for tags and API chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
