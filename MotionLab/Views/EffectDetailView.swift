import SwiftUI
import UIKit

struct EffectDetailView: View {
    let effect: Effect

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

    init(effect: Effect) {
        self.effect = effect
        _params = State(initialValue: effect.defaultParams)
    }

    private var isFavorite: Bool { favorites.contains(effect.id) }

    /// Up to four neighbours from the same category, starting right after this effect.
    private var related: [Effect] {
        let siblings = EffectLibrary.effects(in: effect.category)
        guard siblings.count > 1, let index = siblings.firstIndex(where: { $0.id == effect.id }) else { return [] }
        return (1...min(4, siblings.count - 1)).map { siblings[(index + $0) % siblings.count] }
    }

    var body: some View {
        // Built once per body pass and shared by the share button, the prompt card and the copy action.
        let fullPrompt = effect.fullPrompt(language, params: params)
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    VStack(spacing: 10) {
                        stage(fullPrompt: fullPrompt)
                        stageControls
                    }
                    if !effect.params.isEmpty { parameters }
                    promptCard(fullPrompt).id("prompt")
                    implementationCard
                    if !effect.tags.isEmpty { tagsCard }
                    relatedCard
                }
                .padding()
                .padding(.bottom, 24)
                // Comfortable reading width on iPad; centred.
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 72
            } action: { _, isPastTitle in
                withAnimation(.easeInOut(duration: 0.2)) { showsNavTitle = isPastTitle }
            }
            .onAppear {
                if let anchor = LaunchOptions.detailAnchor {
                    reader.scrollTo(anchor, anchor: .top)
                }
            }
        }
        .background(Palette.pageBackground)
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
                }
                .accessibilityLabel(Text(Strings.sharePrompt, language))
                Button {
                    favorites.toggle(effect.id)
                    Haptics.tap(.medium)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? Palette.pink : Palette.accent)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(Text(isFavorite ? Strings.removeFavorite : Strings.addFavorite, language))
            }
        }
        .onAppear { recents.record(effect.id) }
        .onDisappear {
            copyFeedback?.cancel()
            copied = false
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8) {
                NavigationLink(value: Route.category(effect.category)) {
                    Label {
                        Text(effect.category.title, language)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: effect.category.symbol)
                            .foregroundStyle(LinearGradient(colors: effect.category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((effect.category.gradient.first ?? Palette.indigo).opacity(0.16), in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.stroke))
                    .contentShape(Capsule())
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityHint(Text(Strings.openCategory, language))
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
                        .overlay(Capsule().strokeBorder(Palette.stroke))
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableCardStyle())
                .accessibilityHint(Text(Strings.showInteraction, language))
                if let requirement = effect.requirement {
                    Text(verbatim: "\(Strings.requires(language)) \(requirement)")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Palette.violet.opacity(0.15), in: Capsule())
                        .foregroundStyle(Palette.violetText)
                }
            }
            Text(effect.name, language)
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text(effect.summary, language)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    /// The live demo. Each demo draws its own specific instruction (`DemoHint`) inside the stage.
    private func stage(fullPrompt: String) -> some View {
        effect.makeDemo(DemoContext(params: params, isPreview: false, language: language))
            // Tap-driven demos play once on arrival (and again after Reset, which rebuilds the view).
            .environment(\.demoIntroPlay, true)
            .id(resetToken)
            .frame(maxWidth: .infinity)
            .frame(height: StageMetrics.detailHeight)
            .background(StageBackground())
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.stage, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.stage, style: .continuous).strokeBorder(Palette.stroke))
            .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
            // One VoiceOver stop: "<name>, <summary>", the interaction type as the hint, and
            // Reset / Copy Prompt as custom actions. Double-tap still reaches the demo's own control.
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(verbatim: "\(effect.name(language)), \(effect.summary(language))"))
            .accessibilityHint(Text(verbatim: "\(Strings.interactionFilter(language)): \(effect.interaction.title(language))"))
            .accessibilityAction(named: Text(Strings.reset, language)) { resetDemo() }
            .accessibilityAction(named: Text(Strings.copyPrompt, language)) { copyPrompt(fullPrompt) }
    }

    /// Sits under the stage so it never collides with demo content.
    private var stageControls: some View {
        HStack {
            Spacer(minLength: 0)
            Button(action: resetDemo) {
                Label(Strings.reset(language), systemImage: "arrow.counterclockwise")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .symbolEffect(.bounce, value: resetToken)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Palette.chipOnPage, in: Capsule())
                    .overlay(Capsule().strokeBorder(Palette.stroke))
                    .contentShape(Capsule())
            }
            .buttonStyle(PressableCardStyle())
            .fixedSize()
            .accessibilityHint(Text(Strings.resetDemo, language))
        }
        .padding(.horizontal, 4)
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
                    .background(Palette.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .leading) {
                        Capsule().fill(Palette.primary).frame(width: 3).padding(.vertical, 10)
                    }
                Button {
                    copyPrompt(fullPrompt)
                } label: {
                    Label(copied ? Strings.copied(language) : Strings.copyPrompt(language),
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(copied ? AnyShapeStyle(Palette.successStrong) : AnyShapeStyle(Palette.primaryStrong),
                                    in: RoundedRectangle(cornerRadius: CornerRadius.chip, style: .continuous))
                }
                .buttonStyle(PressableCardStyle())
            }
        }
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
                ForEach(effect.tags, id: \.self) { tag in
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
                    ForEach(items) { item in
                        EffectLink(effect: item, source: "related") {
                            RelatedEffectRow(effect: item)
                        }
                    }
                    NavigationLink(value: Route.category(effect.category)) {
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
        }
    }

    // MARK: Actions

    private func resetDemo() {
        resetToken += 1
        Haptics.tap()
    }

    private func copyPrompt(_ fullPrompt: String) {
        UIPasteboard.general.string = fullPrompt
        Haptics.success()
        UIAccessibility.post(notification: .announcement, argument: Strings.promptCopied(language))
        withAnimation(.snappy) { copied = true }
        copyFeedback?.cancel()
        copyFeedback = Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { copied = false }
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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 30, height: 30)
                    .background(Palette.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
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
        .background(Palette.cardBackground, in: RoundedRectangle(cornerRadius: CornerRadius.section, style: .continuous))
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
            }
        case .toggle:
            Toggle(isOn: Binding(get: { value > 0.5 }, set: { value = $0 ? 1 : 0 })) {
                Text(spec.name, language).font(.subheadline)
            }
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
            }
        }
    }
}
