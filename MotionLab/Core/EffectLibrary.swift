import SwiftUI

/// The full catalog. Each category module exposes `enum XxxEffects { static let all: [Effect] }`.
enum EffectLibrary {
    static let all: [Effect] = {
        let groups: [[Effect]] = [
            ShowcaseEffects.all,
            ButtonEffects.all,
            InputEffects.all,
            LoadingEffects.all,
            FeedbackEffects.all,
            MorphEffects.all,
            NavigationEffects.all,
            CardEffects.all,
            ScrollEffects.all,
            TextEffects.all,
            IconEffects.all,
            GestureEffects.all,
            ChartEffects.all,
            BackgroundEffects.all,
            ShaderEffects.all,
        ]
        return groups.flatMap { $0 }
    }()

    static let byID: [String: Effect] = {
        var dict: [String: Effect] = [:]
        for effect in all {
            assert(dict[effect.id] == nil, "Duplicate effect id \(effect.id)")
            dict[effect.id] = effect
        }
        return dict
    }()

    static func effect(id: String) -> Effect? { byID[id] }

    /// Effects grouped by category, in catalog order. Built once.
    static let byCategory: [EffectCategory: [Effect]] = Dictionary(grouping: all, by: { $0.category })

    static func effects(in category: EffectCategory) -> [Effect] {
        byCategory[category] ?? []
    }

    /// A small hand-picked set for the Browse header; falls back gracefully if ids change.
    static let featured: [Effect] = {
        let ids = [
            "showcase.slide-to-start", "showcase.fog-wipe", "showcase.speed-line",
            "morph.button-to-card", "loading.load-button", "shader.ripple", "cards.tilt-3d",
            "backgrounds.mesh-gradient", "text.numeric-counter", "buttons.magnetic", "navigation.tab-indicator",
        ]
        let picked = ids.compactMap { byID[$0] }
        return picked.count >= 4 ? picked : Array(all.prefix(8))
    }()

    // MARK: Search

    /// Lower-cased search fields for every effect, computed once.
    private static let searchIndex: [EffectSearchEntry] = all.enumerated().map { EffectSearchEntry(effect: $1, order: $0) }

    /// Every query term must match somewhere; results are ranked by where they match
    /// (name > tag > API > category/interaction > summary > implementation, with prefix boosts),
    /// ties keep catalog order. An empty query returns the filtered catalog in order.
    static func search(_ query: String, category: EffectCategory?, interaction: EffectInteraction?) -> [Effect] {
        let terms = query
            .lowercased()
            .split(whereSeparator: { $0 == " " || $0 == "\u{3000}" })
            .map(String.init)
        let pool = searchIndex.filter { entry in
            if let category, entry.effect.category != category { return false }
            if let interaction, entry.effect.interaction != interaction { return false }
            return true
        }
        guard !terms.isEmpty else { return pool.map(\.effect) }

        var ranked: [(entry: EffectSearchEntry, score: Int)] = []
        for entry in pool {
            var total = 0
            var matchesAll = true
            for term in terms {
                guard let score = entry.score(term) else {
                    matchesAll = false
                    break
                }
                total += score
            }
            if matchesAll { ranked.append((entry, total)) }
        }
        ranked.sort { lhs, rhs in
            lhs.score != rhs.score ? lhs.score > rhs.score : lhs.entry.order < rhs.entry.order
        }
        return ranked.map { $0.entry.effect }
    }
}

/// Pre-lowercased search fields for one effect.
struct EffectSearchEntry {
    let effect: Effect
    /// Position in the catalog, used as the tie-breaker.
    let order: Int
    private let names: [String]
    private let nameWords: [String]
    private let tags: [String]
    private let apis: [String]
    private let facets: String
    private let summary: String
    private let summaryWords: [String]
    private let implementation: String

    init(effect: Effect, order: Int) {
        self.effect = effect
        self.order = order
        names = [effect.name.en.lowercased(), effect.name.zh.lowercased()]
        nameWords = names.flatMap(Self.words)
        tags = effect.tags.map { $0.lowercased() }
        // ".symbolEffect" / "@Observable" should match "symbol…" / "observ…" as a prefix too.
        apis = effect.apis.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".@#")) }
        facets = [effect.id, effect.category.title.all, effect.interaction.title.all].joined(separator: " ").lowercased()
        summary = effect.summary.all.lowercased()
        summaryWords = Self.words(summary)
        implementation = effect.implementation.all.lowercased()
    }

    private static func words(_ text: String) -> [String] {
        text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }

    /// Relevance of one term, or `nil` when it matches nowhere.
    func score(_ term: String) -> Int? {
        if names.contains(term) { return 120 }
        if names.contains(where: { $0.hasPrefix(term) }) { return 100 }
        if nameWords.contains(where: { $0.hasPrefix(term) }) { return 85 }
        if names.contains(where: { $0.contains(term) }) { return 70 }
        if tags.contains(term) { return 60 }
        if tags.contains(where: { $0.hasPrefix(term) }) { return 50 }
        if tags.contains(where: { $0.contains(term) }) { return 40 }
        if apis.contains(where: { $0.hasPrefix(term) }) { return 38 }
        if apis.contains(where: { $0.contains(term) }) { return 32 }
        if facets.contains(term) { return 25 }
        if summaryWords.contains(where: { $0.hasPrefix(term) }) { return 18 }
        if summary.contains(term) { return 15 }
        if implementation.contains(term) { return 5 }
        return nil
    }
}
