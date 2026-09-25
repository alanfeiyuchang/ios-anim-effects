import SwiftUI
import UIKit

/// Every demo is authored against this square canvas; previews scale it down.
enum StageMetrics {
    static let previewCanvas: CGFloat = 340
    static let detailHeight: CGFloat = 400
    /// The detail stage may shrink to fit above the fold, but never below the authored canvas.
    static let detailMinHeight: CGFloat = 340
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
    /// Shifts the demo inside its frame as the thumbnail moves through a horizontal scroll view
    /// (Featured carousel). Off with Reduce Motion.
    var parallax = false
    /// Off for a live layer stacked over a still (preview strips): the still's stage shows through,
    /// so a demo mid-entrance never blends a bare stage over the finished frame.
    var showsBackground = true
    @Environment(\.appLanguage) private var language
    @Environment(\.previewMotionEnabled) private var motionEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @Environment(\.urgentSnapshots) private var urgent
    @Environment(\.previewsForcedOnScreen) private var forcedOnScreen
    /// Starts off: lazy grids build cells slightly outside the viewport, and those must not mount
    /// their live demo. `onScrollVisibilityChange` reports `true` on first layout for visible cells.
    @State private var scrolledOnScreen = false
    private var isOnScreen: Bool { scrolledOnScreen || forcedOnScreen }
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
                    // A soft shimmer skeleton (reads as "loading", never as an empty tile) until
                    // the still is ready.
                    StillPlaceholder().task(id: key, priority: urgent ? .userInitiated : .medium) {
                        // Let the grid's first frame land, then wait for a free render slot so a
                        // screenful of new cards never rasterises in one scroll frame. Urgent tiles
                        // (the first cards of a page, the detail page's Variations row) go first.
                        await SnapshotGate.waitForTurn(urgent: urgent)
                        guard !Task.isCancelled else { return }
                        let started = ContinuousClock.now
                        renderSnapshot(key: key, pixelsPerPoint: scale * displayScale)
                        SnapshotGate.didRender(taking: ContinuousClock.now - started)
                    }
                }
            }
            .transition(.opacity)
            .modifier(PreviewParallax(enabled: parallax && !reduceMotion))
        }
        .aspectRatio(1, contentMode: .fit)
        .background { if showsBackground { StageBackground() } }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(StageRim(cornerRadius: cornerRadius))
        .animation(.easeInOut(duration: 0.25), value: isOnScreen)
        .onScrollVisibilityChange(threshold: 0.01) { visible in
            if scrolledOnScreen != visible { scrolledOnScreen = visible }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var context: DemoContext {
        DemoContext(params: effect.defaultParams, isPreview: true, language: language)
    }

    private func liveDemo(scale: CGFloat, size: CGSize, autoplay: Bool) -> some View {
        let side = StageMetrics.previewCanvas
        return EffectDemoView(effect: effect, context: context)
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
        let image = PreviewStill.render(
            effect: effect,
            language: language,
            colorScheme: colorScheme,
            pixelsPerPoint: pixelsPerPoint
        )
        if let image {
            PreviewSnapshotCache.shared.insert(image, for: key)
            // The still cross-fades in over the placeholder.
            withAnimation(.easeOut(duration: 0.25)) {
                snapshot = image
                snapshotKey = key
            }
        } else {
            failedKey = key
        }
    }
}

/// The still-thumbnail pipeline, shared by `PreviewStage` and the CI still audit
/// (`CatalogTools.auditStills`), so the audit measures exactly what the grid shows.
enum PreviewStill {
    /// Rasterises `effect`'s resting frame (default params, preview size) on the authored canvas.
    /// Returns nil when `ImageRenderer` cannot draw it.
    @MainActor
    static func render(
        effect: Effect,
        language: AppLanguage,
        colorScheme: ColorScheme,
        pixelsPerPoint: CGFloat
    ) -> UIImage? {
        guard pixelsPerPoint > 0 else { return nil }
        let side: CGFloat = StageMetrics.previewCanvas
        var still = DemoContext(params: effect.defaultParams, isPreview: true, language: language)
        still.isStill = true
        let content = effect.makeDemo(still)
            .frame(width: side, height: side)
            .environment(\.demoAutoplayEnabled, false)
            // Materials and glass cannot be rasterised: `DemoMaterial` swaps in a translucent fill.
            .environment(\.demoIsStill, true)
            .environment(\.appLanguage, language)
            .environment(\.locale, language.locale)
            .environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: side, height: side)
        renderer.scale = pixelsPerPoint
        renderer.isOpaque = false
        return renderer.uiImage
    }
}

/// Shown in a thumbnail while its still frame waits for a render slot: a soft light sweep over the
/// stage (the thumbnail's own `StageBackground` shows through), so a slow tile reads as "loading".
/// Static (just the empty stage) with Reduce Motion.
private struct StillPlaceholder: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.clear
            if !reduceMotion {
                ShimmerSweep()
                    .opacity(colorScheme == .dark ? 0.22 : 0.7)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct UrgentSnapshotsKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Thumbnails inside mark their still frames as urgent: they render ahead of every other queued
    /// still (see `SnapshotGate.waitForTurn(urgent:)`). Set on the first cards of a page and on the
    /// detail page's Variations row, which are above the fold.
    var urgentSnapshots: Bool {
        get { self[UrgentSnapshotsKey.self] }
        set { self[UrgentSnapshotsKey.self] = newValue }
    }

    /// Thumbnails inside skip the scroll-visibility gate and count as on screen. Set by the trailer, whose
    /// scaled, embedded screens never report scroll visibility; the screens there are short, so the few
    /// cells a lazy stack builds past the viewport cost little.
    var previewsForcedOnScreen: Bool {
        get { self[PreviewsForcedOnScreenKey.self] }
        set { self[PreviewsForcedOnScreenKey.self] = newValue }
    }
}

private struct PreviewsForcedOnScreenKey: EnvironmentKey {
    static let defaultValue = false
}

/// Parallax for thumbnails in a horizontal carousel: the demo is scaled up slightly and slides
/// against the card's own movement, so it reads as a window onto a deeper layer.
private struct PreviewParallax: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content
                .scaleEffect(1.07)
                .visualEffect { effect, proxy in
                    // 26 pt = carousel inset (16) + card padding (10): the resting, snapped position.
                    let minX = proxy.frame(in: .scrollView).minX
                    let shift: CGFloat = min(max((minX - 26) * -0.05, -8), 8)
                    return effect.offset(x: shift)
                }
        } else {
            content
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
        // Liquid Glass does not render in ImageRenderer.
        "buttons.liquid-glass", "morph.liquid-glass", "shader.glassmorphism", "shader.liquid-glass-lens",
    ]

    static func canSnapshot(_ effect: Effect) -> Bool {
        effect.interaction != .scroll && effect.category != .scroll && !liveOnlyIDs.contains(effect.id)
            && !DemoIsolation.needsHost(effect)
    }

    /// "<id>|<language>|<scheme>" of every still rendered this session, at any pixel scale.
    private var rendered: Set<String> = []
    private let lock = NSLock()

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        let pixels = image.size.width * image.scale * image.size.height * image.scale
        cache.setObject(image, forKey: key as NSString, cost: Int(pixels * 4))
        let prefix = Self.prefix(of: key)
        lock.lock()
        rendered.insert(prefix)
        lock.unlock()
    }

    /// Whether a still of `effectID` in this language and colour scheme has been rendered (at any
    /// scale). A preview strip uses it to decide whether a live layer has a still underneath it.
    func hasStill(effectID: String, language: AppLanguage, dark: Bool) -> Bool {
        let prefix = "\(effectID)|\(language.rawValue)|\(dark ? "dark" : "light")"
        lock.lock()
        defer { lock.unlock() }
        return rendered.contains(prefix)
    }

    /// Snapshot keys are "<id>|<language>|<scheme>|<scale>"; drops the scale.
    private static func prefix(of key: String) -> String {
        guard let bar = key.lastIndex(of: "|") else { return key }
        return String(key[..<bar])
    }
}

/// Spaces out snapshot renders so they never starve the main thread:
/// - after each `ImageRenderer` pass the next one waits at least twice as long as that pass took
///   (min 20 ms), so the UI always gets most of the frames even when a demo is expensive to draw;
/// - `hold(for:)` pauses all renders while a page plays its entrance (the detail page calls it),
///   so thumbnails in the Variations row never compete with the stage and the page's own motion;
/// - no render starts while any scroll view is moving (`pausesSnapshotsWhileScrolling()` reports
///   scroll phases here), and the first one after a scroll waits for the deceleration to settle.
///   A scroll token that never reports `.idle` again (an interrupted programmatic scroll, a view torn
///   down without `onDisappear`) stops blocking after `staleScroll`, so stills can never stall forever;
/// - urgent renders (above-the-fold thumbnails) take every free slot before normal ones.
@MainActor
enum SnapshotGate {
    private static var nextSlot = ContinuousClock.now
    /// Scroll views currently tracking, decelerating or animating, with the time they started.
    private static var activeScrolls: [UUID: ContinuousClock.Instant] = [:]
    /// Urgent renders currently waiting for a slot; normal renders yield to them.
    private static var urgentWaiting = 0
    /// A scroll that has not reported `.idle` for this long is treated as stuck.
    private static let staleScroll: Duration = .seconds(2.5)

    static func beginScroll(_ id: UUID) {
        activeScrolls[id] = ContinuousClock.now
    }

    static func endScroll(_ id: UUID) {
        guard activeScrolls.removeValue(forKey: id) != nil else { return }
        if activeScrolls.isEmpty { hold(for: .milliseconds(150)) }
    }

    /// Whether a live (not stale) scroll is in progress; stale tokens are dropped.
    private static var isScrolling: Bool {
        guard !activeScrolls.isEmpty else { return false }
        let cutoff = ContinuousClock.now - staleScroll
        activeScrolls = activeScrolls.filter { $0.value > cutoff }
        return !activeScrolls.isEmpty
    }

    static func waitForTurn(urgent: Bool = false) async {
        if urgent { urgentWaiting += 1 }
        defer { if urgent { urgentWaiting -= 1 } }
        await Task.yield()
        let clock = ContinuousClock()
        while !Task.isCancelled {
            if isScrolling || (!urgent && urgentWaiting > 0) {
                try? await Task.sleep(for: .milliseconds(urgent ? 40 : 80))
                continue
            }
            let now = clock.now
            if now >= nextSlot {
                nextSlot = now + .milliseconds(20)
                return
            }
            try? await Task.sleep(until: nextSlot, clock: clock)
        }
    }

    static func didRender(taking duration: Duration) {
        let breathing = max(duration * 2, .milliseconds(20))
        let candidate = ContinuousClock.now + breathing
        if candidate > nextSlot { nextSlot = candidate }
    }

    static func hold(for duration: Duration) {
        let candidate = ContinuousClock.now + duration
        if candidate > nextSlot { nextSlot = candidate }
    }
}

/// Neutral stage behind every demo.
struct StageBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Palette.stage
            RadialGradient(
                // Dark mode lifts the centre a little more, so dark demos keep a readable edge.
                colors: [Color.white.opacity(scheme == .dark ? 0.10 : 0.6), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 320
            )
        }
    }
}

struct EffectCard: View {
    let effect: Effect
    /// Shared with the family page's Compare cards so a variation's stage flies between layouts.
    var stageNamespace: Namespace.ID? = nil
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        VStack(alignment: .leading, spacing: 10) {
            PreviewStage(effect: effect)
                .modifier(StageGeometryLink(effectID: effect.id, namespace: stageNamespace))
                .overlay(alignment: .topTrailing) {
                    if favorites.contains(effect.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Palette.pink, in: Circle())
                            .shadow(color: Palette.pink.opacity(0.35), radius: 4, y: 2)
                            .padding(8)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                .animation(ShellMotion.pop, value: favorites.contains(effect.id))
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
        .glossCard(cornerRadius: CornerRadius.card, tint: effect.category.gradient.first)
        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }
}

/// Matched geometry between the same variation's stage in two layouts (family Grid ↔ Compare).
struct StageGeometryLink: ViewModifier {
    let effectID: String
    let namespace: Namespace.ID?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let namespace {
            content.matchedGeometryEffect(id: "stage.\(effectID)", in: namespace)
        } else {
            content
        }
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

/// Grid of effect cards.
///
/// Motion: the cards on screen when the grid first appears rise in with a short stagger; cards
/// scrolled into view later are revealed by an animated scroll transition; cards joining or leaving
/// (search results, favorites) scale and fade in and out. Reduce Motion reduces all of it to fades.
/// None of these wrap the cards in a blur: the cards hold live demos, and a blur over animating
/// content would cost an offscreen pass every frame.
struct EffectGrid: View {
    let effects: [Effect]
    /// Zoom-transition placement name; give each grid on one screen its own.
    var source = "grid"
    /// See `EffectCard.stageNamespace`.
    var stageNamespace: Namespace.ID? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Flips once, on first appearance; cards created later start already in place.
    @State private var entered = false

    private var columns: [GridItem] {
        // Accessibility text sizes get one wide column so names and summaries stay readable.
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: 14)]
            : [GridItem(.adaptive(minimum: 158), spacing: 14)]
    }

    var body: some View {
        let entered = self.entered
        let swap = CardSwapTransition(reduceMotion: reduceMotion, blur: 0)
        let stageNamespace = self.stageNamespace
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(Array(effects.enumerated()), id: \.element.id) { index, effect in
                EffectLink(effect: effect, source: source) {
                    EffectCard(effect: effect, stageNamespace: stageNamespace)
                }
                .entrance(entered, delay: ShellMotion.stagger(index, step: 0.05, cap: 8), distance: 22, scale: 0.95, blur: 0)
                .scrollReveal(blur: 0)
                .transition(swap)
                // The first two rows' stills render ahead of the rest.
                .environment(\.urgentSnapshots, index < 4)
            }
        }
        .onAppear {
            if !entered { self.entered = true }
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
///
/// Give every chip in one row the same `namespace` and the selected pill slides from chip to chip
/// (matched geometry) instead of cross-fading; the label colour cross-fades underneath it.
struct Chip: View {
    let title: String
    var symbol: String? = nil
    var count: Int? = nil
    var isSelected: Bool
    /// Shared by the chips of one row so the selection pill travels between them.
    var namespace: Namespace.ID? = nil
    var action: () -> Void
    @State private var bounces = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            Haptics.selection()
            if !isSelected && !reduceMotion { bounces += 1 }
            withAnimation(ShellMotion.selection) { action() }
        } label: {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                        .fixedSymbolLocale()
                        .font(.caption.weight(.semibold))
                        .symbolEffect(.bounce, value: bounces)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if let count {
                    Text(verbatim: "\(count)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isSelected ? Palette.onAccent.opacity(0.72) : Color.secondary)
                        .contentTransition(.numericText(value: Double(count)))
                }
            }
            .fixedSize()
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Palette.onAccent : Color.primary)
            .background {
                ZStack {
                    Capsule()
                        .fill(Palette.chipOnPage)
                        .overlay(Capsule().strokeBorder(Palette.edge))
                        .opacity(isSelected ? 0 : 1)
                    if isSelected { selectionPill }
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .animation(ShellMotion.selection, value: isSelected)
        // The travelling pill draws above neighbouring chips while it slides.
        .zIndex(isSelected ? 1 : 0)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var selectionPill: some View {
        let pill = Capsule()
            .fill(Palette.accentFill)
            .shadow(color: Palette.accentGlow, radius: 6, y: 3)
        if let namespace {
            pill.matchedGeometryEffect(id: "chip.selection", in: namespace)
        } else {
            pill
        }
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
            .overlay(Capsule().strokeBorder(Palette.edge))
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
