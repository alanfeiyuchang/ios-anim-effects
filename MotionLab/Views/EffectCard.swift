import SwiftUI
import UIKit

/// Every demo is authored against this square canvas; previews scale it down.
enum StageMetrics {
    static let previewCanvas: CGFloat = 340
    static let detailHeight: CGFloat = 400
}

/// Non-interactive thumbnail of an effect's demo.
///
/// Performance / accessibility policy:
/// - When previews may animate, the live demo is only mounted while the thumbnail is on screen,
///   so a long grid never keeps dozens of timelines and autoplay loops running off-screen.
/// - When "Animate previews" is off or Reduce Motion is on, the demo is rendered once into a
///   still image (`PreviewSnapshotCache`) and shown as a plain `Image`, so demos with their own
///   `TimelineView` / `phaseAnimator` loops truly stand still. Demos built on UIKit-backed views
///   that `ImageRenderer` cannot draw (scroll views, text fields) stay live with autoplay off.
struct PreviewStage: View {
    let effect: Effect
    var cornerRadius: CGFloat = CornerRadius.thumbnail
    @Environment(\.appLanguage) private var language
    @Environment(\.previewMotionEnabled) private var motionEnabled
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var isOnScreen = true
    /// Last snapshot this view rendered (kept so an NSCache eviction never blanks a visible card).
    @State private var snapshot: UIImage?
    @State private var snapshotKey: String?
    /// Key whose render returned nil; the live (non-autoplaying) demo is shown instead.
    @State private var failedKey: String?

    var body: some View {
        GeometryReader { proxy in
            let side = StageMetrics.previewCanvas
            let scale = proxy.size.width / side
            let key = makeSnapshotKey(pixelsPerPoint: scale * displayScale)
            Group {
                if motionEnabled {
                    if isOnScreen {
                        liveDemo(scale: scale, size: proxy.size, autoplay: true)
                    }
                } else if !PreviewSnapshotCache.canSnapshot(effect) || failedKey == key {
                    if isOnScreen {
                        liveDemo(scale: scale, size: proxy.size, autoplay: false)
                    }
                } else if let image = cachedSnapshot(for: key) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else if isOnScreen && proxy.size.width > 0 {
                    Color.clear.task(id: key) {
                        // Let the grid's first frame land before rasterising.
                        await Task.yield()
                        guard !Task.isCancelled else { return }
                        renderSnapshot(key: key, pixelsPerPoint: scale * displayScale)
                    }
                }
            }
            .transition(.opacity)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(StageBackground())
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .animation(.easeInOut(duration: 0.25), value: isOnScreen)
        .onScrollVisibilityChange(threshold: 0.01) { visible in
            if isOnScreen != visible { isOnScreen = visible }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var context: DemoContext {
        DemoContext(params: effect.defaultParams, isPreview: true, language: language)
    }

    private func liveDemo(scale: CGFloat, size: CGSize, autoplay: Bool) -> some View {
        let side = StageMetrics.previewCanvas
        return effect.makeDemo(context)
            .frame(width: side, height: side)
            .scaleEffect(scale)
            .frame(width: size.width, height: size.height)
            .environment(\.demoAutoplayEnabled, autoplay)
    }

    private func makeSnapshotKey(pixelsPerPoint: CGFloat) -> String {
        // Bucketed so sub-point layout differences reuse the same image.
        let bucket = (pixelsPerPoint * 4).rounded() / 4
        return "\(effect.id)|\(language.rawValue)|\(colorScheme == .dark ? "dark" : "light")|\(bucket)"
    }

    private func cachedSnapshot(for key: String) -> UIImage? {
        if snapshotKey == key, let snapshot { return snapshot }
        return PreviewSnapshotCache.shared.image(for: key)
    }

    /// Renders the demo's resting frame once. Runs on the main actor (ImageRenderer requires it).
    private func renderSnapshot(key: String, pixelsPerPoint: CGFloat) {
        guard pixelsPerPoint > 0 else { return }
        let side = StageMetrics.previewCanvas
        let content = effect.makeDemo(context)
            .frame(width: side, height: side)
            .environment(\.demoAutoplayEnabled, false)
            .environment(\.appLanguage, language)
            .environment(\.locale, language.locale)
            .environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: side, height: side)
        renderer.scale = pixelsPerPoint
        renderer.isOpaque = false
        if let image = renderer.uiImage {
            PreviewSnapshotCache.shared.insert(image, for: key)
            snapshot = image
            snapshotKey = key
        } else {
            failedKey = key
        }
    }
}

/// Still frames of grid thumbnails, keyed by effect id + language + color scheme + pixel scale.
final class PreviewSnapshotCache: @unchecked Sendable {
    static let shared = PreviewSnapshotCache()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 96 * 1024 * 1024
        return cache
    }()

    /// Demos whose content is drawn by UIKit (ScrollView, TextField…) render as placeholders in
    /// `ImageRenderer`, so they are never snapshotted.
    private static let liveOnlyIDs: Set<String> = [
        "inputs.otp-code", "inputs.floating-label", "inputs.password-strength", "inputs.expanding-search",
    ]

    static func canSnapshot(_ effect: Effect) -> Bool {
        effect.interaction != .scroll && effect.category != .scroll && !liveOnlyIDs.contains(effect.id)
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        let pixels = image.size.width * image.scale * image.size.height * image.scale
        cache.setObject(image, forKey: key as NSString, cost: Int(pixels * 4))
    }
}

/// Neutral stage behind every demo.
struct StageBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Palette.stage
            RadialGradient(
                colors: [Color.white.opacity(scheme == .dark ? 0.06 : 0.6), .clear],
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
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
                        .lineLimit(isLarge ? 3 : 1)
                        .minimumScaleFactor(0.85)
                    if let requirement = effect.requirement {
                        RequirementBadge(text: requirement)
                    }
                }
                Text(effect.summary, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isLarge ? 3 : 2, reservesSpace: !isLarge)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .padding(.bottom, 4)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous).strokeBorder(Palette.stroke))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
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
            .background(Palette.violet.opacity(0.16), in: Capsule())
            .foregroundStyle(Palette.violetText)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }
}

struct EffectGrid: View {
    let effects: [Effect]
    /// Zoom-transition placement name; give each grid on one screen its own.
    var source = "grid"
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
                EffectLink(effect: effect, source: source) {
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
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
                }
            }
            .fixedSize()
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background {
                Capsule().fill(isSelected ? AnyShapeStyle(Palette.primaryStrong) : AnyShapeStyle(Palette.chipOnPage))
            }
            .overlay {
                if !isSelected { Capsule().strokeBorder(Palette.stroke) }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .animation(.snappy, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Small rounded tag label, designed to sit inside a card (`Palette.cardBackground`).
struct TagLabel: View {
    let text: String
    var monospaced = false

    var body: some View {
        Text(text)
            .font(monospaced ? .caption.monospaced() : .caption)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Palette.chipOnCard, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.stroke))
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
/// Sizing and placement share one row-breaking pass, so the measured height always matches
/// what is placed (no chip can wrap in placement without being counted in the height).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    private struct Item {
        let index: Int
        let origin: CGPoint
        let size: CGSize
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let (_, size) = arrange(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        return size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Arrange against the same width that sizing was asked for, falling back to the bounds.
        let (items, _) = arrange(subviews: subviews, maxWidth: proposal.width ?? bounds.width)
        for item in items {
            subviews[item.index].place(
                at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> ([Item], CGSize) {
        // Half a point of slack absorbs sub-point rounding between the two layout passes.
        let tolerance: CGFloat = 0.5
        var items: [Item] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for index in subviews.indices {
            let size = fittedSize(subviews[index], maxWidth: maxWidth)
            if x > 0 && x + size.width > maxWidth + tolerance {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            items.append(Item(index: index, origin: CGPoint(x: x, y: y), size: size))
            widest = max(widest, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = maxWidth.isFinite ? min(widest, maxWidth) : widest
        return (items, CGSize(width: width, height: y + rowHeight))
    }

    /// Ideal size, but never wider than a row (long API names at large text sizes).
    private func fittedSize(_ subview: LayoutSubview, maxWidth: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard maxWidth.isFinite, ideal.width > maxWidth else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }
}
