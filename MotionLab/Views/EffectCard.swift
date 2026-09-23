import SwiftUI
import UIKit

/// Every demo is authored against this square canvas; previews scale it down.
enum StageMetrics {
    static let previewCanvas: CGFloat = 340
    static let detailHeight: CGFloat = 400
}

/// Live, non-interactive thumbnail of an effect's demo.
///
/// Performance / accessibility policy:
/// - The demo is only mounted while the thumbnail is on screen, so a long grid never keeps
///   dozens of timelines and autoplay loops running off-screen.
/// - Autoplay is switched off when "Animate previews" is disabled or Reduce Motion is on,
///   leaving each tap-driven demo at its resting state.
struct PreviewStage: View {
    let effect: Effect
    var cornerRadius: CGFloat = 18
    @Environment(\.appLanguage) private var language
    @Environment(\.previewMotionEnabled) private var motionEnabled
    @State private var isOnScreen = true

    var body: some View {
        GeometryReader { proxy in
            let side = StageMetrics.previewCanvas
            let scale = proxy.size.width / side
            if isOnScreen {
                effect.makeDemo(DemoContext(params: effect.defaultParams, isPreview: true, language: language))
                    .frame(width: side, height: side)
                    .scaleEffect(scale)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .environment(\.demoAutoplayEnabled, motionEnabled)
                    .transition(.opacity)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(StageBackground())
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onScrollVisibilityChange(threshold: 0.01) { visible in
            if isOnScreen != visible { isOnScreen = visible }
        }
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
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.snappy, value: favorites.contains(effect.id))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(effect.name, language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    if let requirement = effect.requirement {
                        RequirementBadge(text: requirement)
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

/// Tiny "iOS 26" style badge next to an effect name.
struct RequirementBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Palette.violet.opacity(0.18), in: Capsule())
            .foregroundStyle(Palette.violet)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

struct EffectGrid: View {
    let effects: [Effect]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        // Accessibility text sizes get one wide column so names and summaries stay readable.
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: 14)]
            : [GridItem(.adaptive(minimum: 158), spacing: 14)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(effects) { effect in
                EffectLink(effect: effect) {
                    EffectCard(effect: effect)
                }
            }
        }
    }
}

/// Long-press menu shared by every effect card: favorite and copy the prompt.
private struct EffectContextMenu: ViewModifier {
    let effect: Effect
    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites

    func body(content: Content) -> some View {
        content.contextMenu {
            let isFavorite = favorites.contains(effect.id)
            Button {
                favorites.toggle(effect.id)
                Haptics.tap(.medium)
            } label: {
                Label(isFavorite ? Strings.removeFavorite(language) : Strings.addFavorite(language),
                      systemImage: isFavorite ? "heart.slash" : "heart")
            }
            Button {
                UIPasteboard.general.string = effect.fullPrompt(language, params: effect.defaultParams)
                Haptics.success()
            } label: {
                Label(Strings.copyPrompt(language), systemImage: "doc.on.doc")
            }
        }
    }
}

extension View {
    /// Adds the standard effect long-press menu (favorite / copy prompt).
    func effectContextMenu(_ effect: Effect) -> some View {
        modifier(EffectContextMenu(effect: effect))
    }
}

/// Capsule filter chip.
struct Chip: View {
    let title: String
    var symbol: String? = nil
    var count: Int? = nil
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol).font(.caption.weight(.semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if let count {
                    Text("\(count)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isSelected ? Color.white.opacity(0.75) : Color.secondary)
                }
            }
            .fixedSize()
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background {
                Capsule().fill(isSelected ? AnyShapeStyle(Palette.primary) : AnyShapeStyle(Palette.surface))
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .animation(.snappy, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Small rounded tag label.
struct TagLabel: View {
    let text: String
    var monospaced = false

    var body: some View {
        Text(text)
            .font(monospaced ? .caption.monospaced() : .caption)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Palette.surface, in: Capsule())
            .foregroundStyle(.secondary)
    }
}

/// Section title with an optional trailing accessory (e.g. a "Clear" button).
struct SectionTitle<Accessory: View>: View {
    let text: String
    var accessory: Accessory

    init(text: String, @ViewBuilder accessory: () -> Accessory) {
        self.text = text
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text)
                .font(.title3.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            accessory
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal)
    }
}

extension SectionTitle where Accessory == EmptyView {
    init(text: String) {
        self.init(text: text) { EmptyView() }
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
            let size = fittedSize(subview, maxWidth: maxWidth)
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
            let size = fittedSize(subview, maxWidth: bounds.width)
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

    /// Ideal size, but never wider than a row (long API names at large text sizes).
    private func fittedSize(_ subview: LayoutSubview, maxWidth: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard maxWidth.isFinite, ideal.width > maxWidth else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }
}
