import SwiftUI

// MARK: - Family

/// A group of variations of the same UI element or pattern (e.g. every slider, every spinner),
/// shown as the level between a category and its effects.
///
/// Families are declared per category in `MotionLab/Families/<Category>Families.swift`
/// (`static let all: [EffectFamily]`) together with a `membership` table mapping effect ids to
/// family ids, so effect files never need to know about families.
struct EffectFamily: Identifiable, Hashable {
    /// "<category rawValue>.<kebab-slug>", globally unique (e.g. "inputs.slider").
    let id: String
    let category: EffectCategory
    let name: LocalizedText
    /// One line on what the variations have in common.
    let summary: LocalizedText
    /// SF Symbol drawn on the family badge.
    let symbol: String

    /// Catch-all family for effects whose membership line is missing or points to an unknown family
    /// (or to a family of another category). Only shown when it actually has members.
    static func fallback(for category: EffectCategory) -> EffectFamily {
        EffectFamily(
            id: "\(category.rawValue).more",
            category: category,
            name: L("More", "更多"),
            summary: L("Effects that are not grouped into a family yet.", "尚未归入系列的动效。"),
            symbol: category.symbol
        )
    }
}

// MARK: - Registry

/// All families, with lookups in both directions. Built once, lazily.
///
/// Rules:
/// - Every effect belongs to exactly one family. The first membership line for an effect id wins;
///   an effect without a valid line lands in its category's fallback "More" family.
/// - A family's effects keep the order of the category list (`XxxEffects.all`).
/// - Families keep their declaration order within a category; families without members are hidden.
enum EffectFamilies {
    /// Every category's family file, in `EffectCategory` order.
    private static let declaredFamilies: [[EffectFamily]] = [
        ShowcaseFamilies.all,
        ButtonsFamilies.all,
        InputsFamilies.all,
        LoadingFamilies.all,
        FeedbackFamilies.all,
        MorphFamilies.all,
        NavigationFamilies.all,
        CardsFamilies.all,
        ScrollFamilies.all,
        TextFamilies.all,
        IconsFamilies.all,
        GesturesFamilies.all,
        ChartsFamilies.all,
        BackgroundsFamilies.all,
        ShadersFamilies.all,
    ]

    private static let declaredMembership: [[String: String]] = [
        ShowcaseFamilies.membership,
        ButtonsFamilies.membership,
        InputsFamilies.membership,
        LoadingFamilies.membership,
        FeedbackFamilies.membership,
        MorphFamilies.membership,
        NavigationFamilies.membership,
        CardsFamilies.membership,
        ScrollFamilies.membership,
        TextFamilies.membership,
        IconsFamilies.membership,
        GesturesFamilies.membership,
        ChartsFamilies.membership,
        BackgroundsFamilies.membership,
        ShadersFamilies.membership,
    ]

    private static let index = FamilyIndex(
        declared: declaredFamilies.flatMap { $0 },
        membership: declaredMembership,
        effects: EffectLibrary.all
    )

    /// Every non-empty family, grouped by category in `EffectCategory` order.
    static var all: [EffectFamily] { index.families }

    static func family(id: String) -> EffectFamily? { index.byID[id] }

    /// The family an effect belongs to (always set for catalog effects).
    static func family(for effect: Effect) -> EffectFamily? { index.familyByEffect[effect.id] }

    static func family(forEffectID id: String) -> EffectFamily? { index.familyByEffect[id] }

    /// Members of a family in category-list order.
    static func effects(in family: EffectFamily) -> [Effect] { index.effectsByFamily[family.id] ?? [] }

    static func effects(inFamily id: String) -> [Effect] { index.effectsByFamily[id] ?? [] }

    /// Non-empty families of a category, in declaration order.
    static func families(in category: EffectCategory) -> [EffectFamily] { index.byCategory[category] ?? [] }

    /// All variations of the effect's family, the effect itself included (just `[effect]` if unknown).
    static func variations(of effect: Effect) -> [Effect] {
        guard let family = family(for: effect) else { return [effect] }
        let members = effects(in: family)
        return members.isEmpty ? [effect] : members
    }

    // MARK: Search

    /// Families whose name, summary or slug match every query term, best first.
    /// Filters mirror the effect search: a family passes the interaction filter when any member uses it.
    static func search(_ query: String, category: EffectCategory?, interaction: EffectInteraction?) -> [EffectFamily] {
        let terms = EffectLibrary.searchTerms(query)
        guard !terms.isEmpty else { return [] }
        var ranked: [(family: EffectFamily, score: Int, order: Int)] = []
        for (order, family) in all.enumerated() {
            if let category, family.category != category { continue }
            if let interaction, !effects(in: family).contains(where: { $0.interaction == interaction }) { continue }
            var total = 0
            var matchesAll = true
            for term in terms {
                guard let score = matchScore(family, term: term) else {
                    matchesAll = false
                    break
                }
                total += score
            }
            if matchesAll { ranked.append((family: family, score: total, order: order)) }
        }
        ranked.sort { lhs, rhs in
            lhs.score != rhs.score ? lhs.score > rhs.score : lhs.order < rhs.order
        }
        return ranked.map { $0.family }
    }

    private static func matchScore(_ family: EffectFamily, term: String) -> Int? {
        let names = [family.name.en.lowercased(), family.name.zh.lowercased()]
        if names.contains(term) { return 120 }
        if names.contains(where: { $0.hasPrefix(term) }) { return 100 }
        let words: [String] = names.flatMap { name in
            name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        }
        if words.contains(where: { $0.hasPrefix(term) }) { return 85 }
        if names.contains(where: { $0.contains(term) }) { return 70 }
        if family.id.lowercased().contains(term) { return 30 }
        if family.summary.all.lowercased().contains(term) { return 15 }
        return nil
    }
}

/// Precomputed lookups behind `EffectFamilies`.
private struct FamilyIndex {
    let families: [EffectFamily]
    let byID: [String: EffectFamily]
    let familyByEffect: [String: EffectFamily]
    let effectsByFamily: [String: [Effect]]
    let byCategory: [EffectCategory: [EffectFamily]]

    init(declared: [EffectFamily], membership: [[String: String]], effects: [Effect]) {
        // Declared families; a repeated id keeps its first declaration.
        var known: [String: EffectFamily] = [:]
        var order: [EffectFamily] = []
        for family in declared where known[family.id] == nil {
            known[family.id] = family
            order.append(family)
        }

        // Effect id → family id; the first table that mentions an effect wins.
        var assigned: [String: String] = [:]
        for table in membership {
            for (effectID, familyID) in table where assigned[effectID] == nil {
                assigned[effectID] = familyID
            }
        }

        // Walk the catalog in order so members keep their category-list order.
        var members: [String: [Effect]] = [:]
        var lookup: [String: EffectFamily] = [:]
        for effect in effects {
            let family = Self.resolve(effect, assigned: assigned, known: &known, order: &order)
            members[family.id, default: []].append(effect)
            lookup[effect.id] = family
        }

        var grouped: [EffectCategory: [EffectFamily]] = [:]
        var visible: [EffectFamily] = []
        var visibleByID: [String: EffectFamily] = [:]
        for category in EffectCategory.allCases {
            let list = order.filter { family in
                family.category == category && !(members[family.id] ?? []).isEmpty
            }
            grouped[category] = list
            visible.append(contentsOf: list)
            for family in list { visibleByID[family.id] = family }
        }

        families = visible
        byID = visibleByID
        familyByEffect = lookup
        effectsByFamily = members
        byCategory = grouped
    }

    private static func resolve(
        _ effect: Effect,
        assigned: [String: String],
        known: inout [String: EffectFamily],
        order: inout [EffectFamily]
    ) -> EffectFamily {
        if let id = assigned[effect.id], let family = known[id], family.category == effect.category {
            return family
        }
        let fallback = EffectFamily.fallback(for: effect.category)
        if let existing = known[fallback.id] { return existing }
        known[fallback.id] = fallback
        order.append(fallback)
        return fallback
    }
}
