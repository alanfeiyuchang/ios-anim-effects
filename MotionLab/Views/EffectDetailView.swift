import SwiftUI
import UIKit

struct EffectDetailView: View {
    /// The effect on screen. Starts as the pushed effect and changes in place when another
    /// variation of its family is picked (strip or header swipe); every per-effect state resets then.
    @State private var effect: Effect

    @Environment(\.appLanguage) private var language
    @Environment(FavoritesStore.self) private var favorites
    @Environment(RecentsStore.self) private var recents
    @Environment(AppNavigator.self) private var navigator
    @State private var params: ParamValues
    @State private var resetToken = 0
    @State private var copied = false
    @State private var copyFeedback: Task<Void, Never>?
    /// The inline nav-bar title only fades in once the large in-page title has scrolled away.
    @State private var showsNavTitle = false
    /// Bumped each time the effect becomes a favorite (heart bounce + burst).
    @State private var favoriteBursts = 0
    /// Bumped on share taps (icon bounce).
    @State private var shareTaps = 0
    /// Bumped on copy (checkmark bounce).
    @State private var copies = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// +1 when the last variation switch moved forward, -1 backward (stage slide direction).
    @State private var swapDirection: CGFloat = 1
    /// Visible height of the scroll view (without bars and insets) and the stage's top edge in the
    /// page content: the stage shrinks (down to `StageMetrics.detailMinHeight`) so it fits above the fold.
    @State private var visibleHeight: CGFloat = 0
    @State private var stageTop: CGFloat = 0

    private static let contentSpace = "detail.content"

    init(effect: Effect) {
        _effect = State(initialValue: effect)
        _params = State(initialValue: effect.defaultParams)
    }

    private var isFavorite: Bool { favorites.contains(effect.id) }

    /// Every variation in this effect's family (the effect included), in category order.
    private var variations: [Effect] { EffectFamilies.variations(of: effect) }

    /// Up to four neighbours from the same category that are not already in the variations strip,
    /// starting right after this effect.
    private var related: [Effect] {
        let siblings = EffectLibrary.effects(in: effect.category)
        guard siblings.count > 1, let index = siblings.firstIndex(where: { $0.id == effect.id }) else { return [] }
        let inFamily = Set(variations.map(\.id))
        var picked: [Effect] = []
        for step in 1..<siblings.count {
            let candidate = siblings[(index + step) % siblings.count]
            if inFamily.contains(candidate.id) { continue }
            picked.append(candidate)
            if picked.count == 4 { break }
        }
        return picked
    }

    var body: some View {
        // Built once per body pass and shared by the share button, the prompt card and the copy action.
        let fullPrompt = effect.fullPrompt(language, params: params)
        let variations = self.variations
        let swap = VariationSwapTransition(direction: swapDirection, reduceMotion: reduceMotion)
        let stageHeight = fittedStageHeight
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(variations: variations)
                    if variations.count > 1, let family = EffectFamilies.family(for: effect) {
                        VariationStrip(
                            family: family,
                            variations: variations,
                            currentID: effect.id,
                            onSelect: { item in showVariation(item, in: variations) },
                            onStep: { step in stepVariation(by: step, in: variations) }
                        )
                        .appearEntrance(delay: 0.08, distance: 10, blur: 0)
                    }
                    ZStack {
                        stage(fullPrompt: fullPrompt, height: stageHeight)
                            // A new variation slides in; the old one sinks away (see VariationSwapTransition).
                            .id(effect.id)
                            .transition(swap)
                    }
                    // Reset lives inside the stage (a small glass button), so nothing the demo needs
                    // sits below it where the fold or a bar could cover it.
                    .overlay(alignment: .topTrailing) {
                        resetButton
                            .appearEntrance(delay: 0.3, distance: 0, scale: 0.6, blur: 0)
                    }
                    // Rises into place with a spring as the page arrives.
                    .appearEntrance(delay: 0.12, distance: 36, scale: 0.94, blur: 0)
                    // Measured outside the entrance's offset/scale, in page-content coordinates.
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .named(Self.contentSpace)).minY
                    } action: { top in
                        if abs(top - stageTop) > 0.5 { stageTop = top }
                    }
                    if !effect.params.isEmpty { parameters.scrollReveal() }
                    promptCard(fullPrompt).id("prompt").scrollReveal()
                    implementationCard.scrollReveal()
                    if !effect.tags.isEmpty { tagsCard.scrollReveal() }
                    relatedCard
                }
                .padding()
                // Comfortable reading width on iPad; centred.
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
                .coordinateSpace(.named(Self.contentSpace))
            }
            .shellPageScroll()
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.containerSize.height - geometry.contentInsets.top - geometry.contentInsets.bottom
            } action: { _, height in
                if abs(height - visibleHeight) > 0.5 { visibleHeight = height }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 72
            } action: { _, isPastTitle in
                withAnimation(.easeInOut(duration: 0.2)) { showsNavTitle = isPastTitle }
            }
            .task {
                // `-ML_anchor <id>` (screenshots): scrolling in the push's own transaction is dropped
                // because the content has not been laid out yet, so jump once the page has settled,
                // and once more after the stage has fitted itself to the fold (which moves everything
                // below it).
                guard let anchor = LaunchOptions.takeDetailAnchor() else { return }
                for delay in [350, 900] {
                    try? await Task.sleep(for: .milliseconds(delay))
                    guard !Task.isCancelled else { return }
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { reader.scrollTo(anchor, anchor: .top) }
                }
            }
        }
        .background(Palette.pageBackground)
        // The stage is the page: the floating tab bar (and the search orb) step aside so they never
        // cover its bottom edge, its hint or its controls.
        .toolbarVisibility(.hidden, for: .tabBar)
        .navigationTitle(effect.name(language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(effect.name, language)
                    .font(.headline)
                    .lineLimit(1)
                    .opacity(showsNavTitle ? 1 : 0)
                    .accessibilityHidden(!showsNavTitle)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: fullPrompt) {
                    Image(systemName: "square.and.arrow.up")
                        .symbolEffect(.bounce.up, value: shareTaps)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    Haptics.tap()
                    if !reduceMotion { shareTaps += 1 }
                })
                .accessibilityLabel(Text(Strings.sharePrompt, language))
                Button(action: toggleFavorite) {
                    HeartBurstIcon(isFavorite: isFavorite, burst: favoriteBursts)
                }
                .accessibilityLabel(Text(isFavorite ? Strings.removeFavorite : Strings.addFavorite, language))
            }
        }
        .onAppear {
            // Let the stage and the page entrance have the main thread before thumbnails rasterise.
            // Kept short: the Variations row's small stills sit above the fold and should not wait long.
            SnapshotGate.hold(for: .milliseconds(450))
            Haptics.quiet(for: 2.5)
            recents.record(effect.id)
        }
        .onDisappear {
            copyFeedback?.cancel()
            copied = false
        }
    }

    // MARK: Sections

    private func header(variations: [Effect]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8) {
                RouteLink(route: Route.category(effect.category)) {
                    Label {
                        Text(effect.category.title, language)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: effect.category.symbol)
                            .fixedSymbolLocale()
                            .foregroundStyle(LinearGradient(colors: effect.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((effect.category.gradient.first ?? Palette.ember).opacity(0.16), in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.edge))
                    .contentShape(Capsule())
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityHint(Text(Strings.openCategory, language))
                .appearEntrance(index: 0, delay: 0.05, distance: 8, scale: 0.9, blur: 3)
                Button {
                    Haptics.selection()
                    navigator.search(interaction: effect.interaction)
                } label: {
                    Label(effect.interaction.title(language), systemImage: effect.interaction.symbol)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(.secondary)
                        .background(Palette.chipOnPage, in: Capsule())
                        .overlay(Capsule().strokeBorder(Palette.edge))
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityHint(Text(Strings.showInteraction, language))
                .appearEntrance(index: 1, delay: 0.05, distance: 8, scale: 0.9, blur: 3)
                if let requirement = effect.requirement {
                    Text(verbatim: "\(Strings.requires(language)) \(requirement)")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Palette.violet.opacity(0.15), in: Capsule())
                        .foregroundStyle(Palette.violetText)
                        .appearEntrance(index: 2, delay: 0.05, distance: 8, scale: 0.9, blur: 3)
                }
            }
            Text(effect.name, language)
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
                .modifier(VariationStepActions(enabled: variations.count > 1, language: language) { step in
                    stepVariation(by: step, in: variations)
                })
                .appearEntrance(index: 1, distance: 10)
            Text(effect.summary, language)
                .font(.body)
                .foregroundStyle(.secondary)
                .appearEntrance(index: 2, distance: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // Swipe the title area sideways to step through the family's variations.
        .simultaneousGesture(variationSwipe(variations: variations), including: variations.count > 1 ? .all : .subviews)
    }

    private func variationSwipe(variations: [Effect]) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 60, abs(dx) > abs(dy) * 1.6 else { return }
                stepVariation(by: dx < 0 ? 1 : -1, in: variations)
            }
    }

    /// Stage height that keeps the whole stage above the fold when the page opens: the full
    /// `detailHeight` when it fits, never less than `detailMinHeight` (the demos' authored canvas).
    private var fittedStageHeight: CGFloat {
        guard visibleHeight > 0, stageTop > 0 else { return StageMetrics.detailHeight }
        let available: CGFloat = visibleHeight - stageTop - 12
        return min(max(available, StageMetrics.detailMinHeight), StageMetrics.detailHeight)
    }

    /// The live demo. Each demo draws its own specific instruction (`DemoHint`) inside the stage.
    private func stage(fullPrompt: String, height: CGFloat) -> some View {
        EffectDemoView(effect: effect, context: DemoContext(params: params, isPreview: false, language: language))
            // Tap-driven demos play once on arrival (and again after Reset, which rebuilds the view).
            .environment(\.demoIntroPlay, true)
            .id(resetToken)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(StageBackground())
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.stage, style: .continuous))
            .overlay(StageRim(cornerRadius: CornerRadius.stage))
            .glossCard(cornerRadius: CornerRadius.stage)
            // A container named "<name>, <summary>" with the interaction type as the hint and
            // Reset / Copy Prompt as custom actions; the demo's own controls (legend chips, range
            // pickers, buttons) stay individually reachable inside it.
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(verbatim: "\(effect.name(language))\(Strings.listSeparator(language))\(effect.summary(language))"))
            .accessibilityHint(Text(verbatim: "\(Strings.interactionFilter(language))\(Strings.labelSeparator(language))\(effect.interaction.title(language))"))
            .accessibilityAction(named: Text(Strings.reset, language)) { resetDemo() }
            .accessibilityAction(named: Text(Strings.copyPrompt, language)) { copyPrompt(fullPrompt) }
    }

    /// Small glass button in the stage's top-trailing corner; the arrow makes one full
    /// counter-clockwise turn per reset, settling with a spring.
    private var resetButton: some View {
        let turns: Double = reduceMotion ? 0 : Double(resetToken) * -360
        return Button(action: resetDemo) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .rotationEffect(.degrees(turns))
                .animation(.spring(response: 0.6, dampingFraction: 0.72), value: resetToken)
                .frame(width: 34, height: 34)
                .modifier(GlassCircleBackground())
                // 44 pt hit target around the 34 pt disc.
                .padding(5)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableCardStyle())
        .padding(5)
        .accessibilityLabel(Text(Strings.reset, language))
        .accessibilityHint(Text(Strings.resetDemo, language))
    }

    private var parameters: some View {
        DetailSection(title: Strings.parameters(language), symbol: "slider.horizontal.3") {
            VStack(spacing: 16) {
                ForEach(effect.params) { spec in
                    ParamControl(spec: spec, value: Binding(
                        get: { params[spec.id] },
                        set: { params[spec.id] = $0 }
                    ))
                }
                Button(Strings.resetParams(language)) {
                    Haptics.tap()
                    withAnimation(.snappy) { params = effect.defaultParams }
                }
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .disabled(params == effect.defaultParams)
            }
        }
    }

    private func promptCard(_ fullPrompt: String) -> some View {
        DetailSection(title: Strings.prompt(language), symbol: "text.quote") {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.promptHint, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: fullPrompt)
                    .font(.callout)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .padding(.leading, 4)
                    .background(Palette.ember.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .leading) {
                        Capsule().fill(Palette.accentFill).frame(width: 3).padding(.vertical, 10)
                    }
                copyButton(fullPrompt)
            }
        }
    }

    /// Full-width "Copy Prompt" bar that, once copied, contracts into a green "✓ Copied" pill
    /// (width, corner radius, colour and glyph all morph on one spring), then expands back.
    private func copyButton(_ fullPrompt: String) -> some View {
        let copied = self.copied
        let maxWidth: CGFloat? = copied ? nil : CGFloat.infinity
        let radius: CGFloat = copied ? 24 : CornerRadius.chip
        let fill: AnyShapeStyle = copied ? AnyShapeStyle(Palette.successStrong) : AnyShapeStyle(Palette.accentFill)
        let ink: Color = copied ? Color.white : Palette.onAccent
        let glow: Color = copied ? Palette.green.opacity(0.35) : Palette.accentGlow
        return Button {
            copyPrompt(fullPrompt)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: copies)
                    .accessibilityHidden(true)
                Text(verbatim: copied ? Strings.copied(language) : Strings.copyPrompt(language))
                    .contentTransition(.interpolate)
            }
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 22)
            .frame(maxWidth: maxWidth)
            .padding(.vertical, 12)
            .foregroundStyle(ink)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: glow, radius: 10, y: 5)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? Animation.easeInOut(duration: 0.2) : ShellMotion.pop, value: copied)
    }

    private var implementationCard: some View {
        DetailSection(title: Strings.implementation(language), symbol: "chevron.left.forwardslash.chevron.right") {
            VStack(alignment: .leading, spacing: 12) {
                Text(effect.implementation, language)
                    .font(.callout)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(Strings.apis, language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                FlowLayout(spacing: 6) {
                    ForEach(effect.apis, id: \.self) { api in
                        TagLabel(text: api, monospaced: true)
                    }
                }
            }
        }
    }

    private var tagsCard: some View {
        DetailSection(title: Strings.tags(language), symbol: "tag") {
            FlowLayout(spacing: 6) {
                // Only the tags written in the reading language (all tags still feed search).
                ForEach(effect.displayTags(language), id: \.self) { tag in
                    Button {
                        Haptics.selection()
                        navigator.search(tag)
                    } label: {
                        TagLabel(text: "#\(tag)")
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel(Text(verbatim: tag))
                    .accessibilityHint(Text(Strings.searchTag, language))
                }
            }
        }
    }

    @ViewBuilder
    private var relatedCard: some View {
        let items = related
        if !items.isEmpty {
            DetailSection(title: Strings.moreInCategory(language), symbol: effect.category.symbol) {
                VStack(spacing: 8) {
                    // Rows cascade in one after another as they scroll into view.
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        EffectLink(effect: item, source: "related") {
                            RelatedEffectRow(effect: item)
                        }
                        .scrollReveal(delay: 0.06 + ShellMotion.stagger(index, step: 0.07), distance: 18, scale: 0.97, blur: 3)
                    }
                    RouteLink(route: Route.category(effect.category)) {
                        HStack(spacing: 4) {
                            Text(Strings.seeAll, language)
                            Text(verbatim: "·")
                            Text(verbatim: Strings.effectCount(EffectLibrary.effects(in: effect.category).count, language))
                            Image(systemName: "chevron.right").font(.caption.weight(.bold))
                        }
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 4)
                    }
                }
            }
            .scrollReveal()
        }
    }

    // MARK: Actions

    /// Moves `step` places through the family (wrapping around).
    private func stepVariation(by step: Int, in variations: [Effect]) {
        guard variations.count > 1, let index = variations.firstIndex(where: { $0.id == effect.id }) else { return }
        let count = variations.count
        let next = variations[((index + step) % count + count) % count]
        showVariation(next, in: variations, direction: CGFloat(step > 0 ? 1 : -1))
    }

    /// Swaps the page to another variation in place: the stage slides, texts cross-fade and
    /// parameters, copy state and the demo restart from the new effect's defaults.
    private func showVariation(_ next: Effect, in variations: [Effect], direction: CGFloat? = nil) {
        guard next.id != effect.id else { return }
        let from = variations.firstIndex(where: { $0.id == effect.id }) ?? 0
        let to = variations.firstIndex(where: { $0.id == next.id }) ?? 0
        swapDirection = direction ?? (to >= from ? 1 : -1)
        copyFeedback?.cancel()
        copied = false
        Haptics.selection()
        // The new variation plays its arrival silently, like a freshly opened page.
        Haptics.quiet(for: 2.5)
        withAnimation(reduceMotion ? Animation.easeInOut(duration: 0.2) : Animation.smooth(duration: 0.42)) {
            effect = next
            params = next.defaultParams
        }
        recents.record(next.id)
        UIAccessibility.post(notification: .announcement, argument: next.name(language))
    }

    private func resetDemo() {
        Haptics.tap()
        resetToken += 1
        Haptics.quiet(for: 2.5)
    }

    private func toggleFavorite() {
        let adding = !isFavorite
        withAnimation(ShellMotion.pop) { favorites.toggle(effect.id) }
        if adding {
            favoriteBursts += 1
            Haptics.tap(.medium)
        } else {
            Haptics.tap(.light)
        }
    }

    private func copyPrompt(_ fullPrompt: String) {
        UIPasteboard.general.string = fullPrompt
        Haptics.success()
        UIAccessibility.post(notification: .announcement, argument: Strings.promptCopied(language))
        copied = true
        copies += 1
        copyFeedback?.cancel()
        copyFeedback = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            copied = false
        }
    }
}

/// Compact row for the "More in This Category" list (no live preview, so it stays cheap).
private struct RelatedEffectRow: View {
    let effect: Effect
    @Environment(\.appLanguage) private var language

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: effect.interaction.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(colors: effect.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(effect.name, language)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let requirement = effect.requirement {
                        RequirementBadge(text: requirement)
                    }
                }
                Text(effect.summary, language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.chipOnCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .fixedSymbolLocale()
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 30, height: 30)
                    .background(Palette.ember.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glossCard(cornerRadius: CornerRadius.section)
    }
}

struct ParamControl: View {
    let spec: ParamSpec
    @Binding var value: Double
    @Environment(\.appLanguage) private var language

    var body: some View {
        switch spec.kind {
        case .slider(let range, let step):
            VStack(spacing: 6) {
                HStack {
                    Text(spec.name, language).font(.subheadline)
                    Spacer()
                    Text(spec.formatted(value, language))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: value))
                        // Digits roll like an odometer as the slider moves (and on "Restore defaults").
                        .animation(.snappy(duration: 0.22), value: spec.formatted(value, language))
                }
                .accessibilityHidden(true)
                Group {
                    if let step {
                        Slider(value: $value, in: range, step: step)
                    } else {
                        Slider(value: $value, in: range)
                    }
                }
                .accessibilityLabel(Text(spec.name, language))
                .accessibilityValue(Text(verbatim: spec.formatted(value, language)))
                // Stepped sliders tick like detents; continuous ones stay silent.
                .sensoryFeedback(.selection, trigger: step == nil ? 0 : value)
            }
        case .toggle:
            Toggle(isOn: Binding(get: { value > 0.5 }, set: { value = $0 ? 1 : 0 })) {
                Text(spec.name, language).font(.subheadline)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: value > 0.5)
        case .choice(let options):
            VStack(alignment: .leading, spacing: 8) {
                Text(spec.name, language).font(.subheadline)
                    .accessibilityHidden(true)
                Picker(spec.name(language), selection: Binding(get: { Int(value.rounded()) }, set: { value = Double($0) })) {
                    ForEach(options.indices, id: \.self) { index in
                        Text(options[index], language).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: Int(value.rounded()))
            }
        }
    }
}

/// VoiceOver "Next / Previous variation" actions on the detail title (only when the family has siblings).
private struct VariationStepActions: ViewModifier {
    let enabled: Bool
    let language: AppLanguage
    let step: (Int) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content
                .accessibilityAction(named: Text(Strings.nextVariation, language)) { step(1) }
                .accessibilityAction(named: Text(Strings.previousVariation, language)) { step(-1) }
                .accessibilityHint(Text(Strings.swipeVariations, language))
        } else {
            content
        }
    }
}
