import SwiftUI

/// Cross-tab navigation state: the selected tab plus the Search tab's query and filters,
/// so any screen (e.g. a tag on the detail page) can jump into a pre-filled search.
@Observable
final class AppNavigator {
    var tab: AppTab
    var query = ""
    var category: EffectCategory?
    var interaction: EffectInteraction?
    /// Bumped by `search(_:)` so the Search tab's stack pops back to the results.
    private(set) var searchRevision = 0

    init(tab: AppTab = LaunchOptions.initialTab) {
        self.tab = tab
    }

    /// Switches to the Search tab with `text` as the query and all filters cleared.
    /// `search("")` shows the whole catalog.
    func search(_ text: String) {
        showSearch(query: text, category: nil, interaction: nil)
    }

    /// Switches to the Search tab listing every effect driven by `interaction`.
    func search(interaction: EffectInteraction) {
        showSearch(query: "", category: nil, interaction: interaction)
    }

    private func showSearch(query: String, category: EffectCategory?, interaction: EffectInteraction?) {
        self.query = query
        self.category = category
        self.interaction = interaction
        searchRevision += 1
        tab = .search
    }

    var hasActiveFilters: Bool { category != nil || interaction != nil }

    func clearFilters() {
        category = nil
        interaction = nil
    }
}

/// The app's tabs. Raw values are the `-ML_tab` launch-argument indices used for screenshots.
enum AppTab: Int, Hashable {
    case browse = 0
    case search = 1
    case favorites = 2
    case settings = 3
}

/// Most-recently opened effects, newest first, persisted across launches.
@Observable
final class RecentsStore {
    private static let key = "app.recents"
    private static let limit = 10

    private(set) var ids: [String]
    /// Off for screenshot runs (`-ML_freshState YES`): every launch starts from the same Browse page.
    private let persists: Bool

    init() {
        persists = !LaunchOptions.freshState
        ids = persists ? (UserDefaults.standard.stringArray(forKey: Self.key) ?? []) : []
    }

    func record(_ id: String) {
        guard ids.first != id else { return }
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        if ids.count > Self.limit { ids.removeLast(ids.count - Self.limit) }
        if persists { UserDefaults.standard.set(ids, forKey: Self.key) }
    }

    func clear() {
        ids = []
        if persists { UserDefaults.standard.removeObject(forKey: Self.key) }
    }

    var effects: [Effect] { ids.compactMap { EffectLibrary.effect(id: $0) } }
}

// MARK: - Preview motion policy

private struct PreviewMotionKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Whether grid thumbnails may auto-play. `false` when the user turned off
    /// "Animate previews" in Settings or the system Reduce Motion setting is on.
    var previewMotionEnabled: Bool {
        get { self[PreviewMotionKey.self] }
        set { self[PreviewMotionKey.self] = newValue }
    }
}
