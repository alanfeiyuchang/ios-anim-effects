import SwiftUI

struct BrowseView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(RecentsStore.self) private var recents
    /// Rolled once per appearance so the dice target is stable while the page is visible.
    @State private var randomID = EffectLibrary.all.randomElement()?.id

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                featured
                if !recents.ids.isEmpty { recent }
                categories
            }
            .padding(.bottom, 32)
            .animation(.smooth, value: recents.ids)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(Strings.appTitle(language))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let randomID {
                    NavigationLink(value: Route.effect(randomID)) {
                        Image(systemName: "dice.fill")
                    }
                    .accessibilityLabel(Strings.random(language))
                }
            }
        }
        .onAppear { randomID = EffectLibrary.all.randomElement()?.id }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.appSubtitle, language)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                StatPill(value: "\(EffectLibrary.all.count)", label: Strings.effects(language))
                StatPill(value: "\(EffectCategory.allCases.count)", label: Strings.categories(language))
            }
        }
        .padding(.horizontal)
    }

    private var featured: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: Strings.featured(language))
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(EffectLibrary.featured) { effect in
                        EffectLink(effect: effect) {
                            FeaturedCard(effect: effect)
                        }
                        .scrollTransition(axis: .horizontal) { [reduceMotion] content, phase in
                            content
                                .scaleEffect(phase.isIdentity || reduceMotion ? 1 : 0.92)
                                .opacity(phase.isIdentity ? 1 : 0.7)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: Strings.recent(language)) {
                Button(Strings.clear(language)) {
                    Haptics.tap()
                    recents.clear()
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(recents.effects) { effect in
                        EffectLink(effect: effect) {
                            CompactEffectCard(effect: effect)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .transition(.opacity)
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: Strings.categories(language))
            LazyVGrid(columns: categoryColumns, spacing: 14) {
                ForEach(EffectCategory.allCases) { category in
                    let count = EffectLibrary.effects(in: category).count
                    NavigationLink(value: Route.category(category)) {
                        CategoryTile(category: category, count: count)
                    }
                    .buttonStyle(PressableCardStyle())
                    .accessibilityLabel(Text(verbatim: "\(category.title(language)), \(Strings.effectCount(count, language))"))
                    .accessibilityHint(Text(category.subtitle, language))
                }
            }
            .padding(.horizontal)
        }
    }

    private var categoryColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: 14)]
            : [GridItem(.adaptive(minimum: 160), spacing: 14)]
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Palette.primary)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// Gradient rounded-square badge with the category's SF Symbol.
struct CategoryIcon: View {
    let category: EffectCategory
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            )
            .shadow(color: (category.gradient.last ?? .clear).opacity(0.3), radius: size * 0.15, y: size * 0.08)
            .accessibilityHidden(true)
    }
}

private struct FeaturedCard: View {
    let effect: Effect
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreviewStage(effect: effect, cornerRadius: 22)
                .frame(width: 240, height: 240)
            VStack(alignment: .leading, spacing: 3) {
                Text(effect.category.title, language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LinearGradient(colors: effect.category.gradient, startPoint: .leading, endPoint: .trailing))
                    .lineLimit(1)
                Text(effect.name, language)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6)
        }
        .padding(10)
        .frame(width: 260)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

/// Small card used in the "Recently Viewed" row.
private struct CompactEffectCard: View {
    let effect: Effect
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PreviewStage(effect: effect, cornerRadius: 16)
                .frame(width: 128, height: 128)
            Text(effect.name, language)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 128, alignment: .leading)
                .padding(.horizontal, 2)
        }
        .padding(8)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct CategoryTile: View {
    let category: EffectCategory
    let count: Int
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                CategoryIcon(category: category)
                Spacer()
                Text("\(count)")
                    .font(.footnote.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.06), in: Capsule())
            }
            Text(category.title, language)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                .minimumScaleFactor(0.8)
            Text(category.subtitle, language)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6 : 2, reservesSpace: !dynamicTypeSize.isAccessibilitySize)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                Color(uiColor: .secondarySystemGroupedBackground)
                RadialGradient(
                    colors: [(category.gradient.first ?? Palette.indigo).opacity(0.16), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 150
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct CategoryView: View {
    let category: EffectCategory
    @Environment(\.appLanguage) private var language
    @State private var interaction: EffectInteraction?

    private var allEffects: [Effect] { EffectLibrary.effects(in: category) }

    private var effects: [Effect] {
        allEffects.filter { interaction == nil || $0.interaction == interaction }
    }

    private var availableInteractions: [EffectInteraction] {
        let used = Set(allEffects.map(\.interaction))
        return EffectInteraction.allCases.filter { used.contains($0) }
    }

    var body: some View {
        let all = allEffects
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 14) {
                    CategoryIcon(category: category, size: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(Strings.effectCount(all.count, language))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(LinearGradient(colors: category.gradient, startPoint: .leading, endPoint: .trailing))
                        Text(category.subtitle, language)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(title: Strings.all(language), count: all.count, isSelected: interaction == nil) { interaction = nil }
                        ForEach(availableInteractions) { item in
                            Chip(title: item.title(language),
                                 symbol: item.symbol,
                                 count: all.filter { $0.interaction == item }.count,
                                 isSelected: interaction == item) {
                                interaction = interaction == item ? nil : item
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                EffectGrid(effects: effects)
                    .padding(.horizontal)
                    .animation(.smooth, value: interaction)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(category.title(language))
    }
}
