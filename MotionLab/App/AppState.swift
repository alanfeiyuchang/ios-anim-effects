import SwiftUI

/// Cross-tab navigation state: the selected tab plus the Search tab's query and filters,
/// so any screen (e.g. a tag on the detail page) can jump into a pre-filled search.
@Observable
final class AppNavigator {
    var tab: Int
    var query = ""
    var category: EffectCategory?
    var interaction: EffectInteraction?
    /// Bumped by `search(_:)` so the Search tab's stack pops back to the results.
    private(set) var searchRevision = 0

    init(tab: Int = LaunchOptions.initialTab) {
        self.tab = tab
    }

    /// Switches to the Search tab with `text` as the query and all filters cleared.
    func search(_ text: String) {
        query = text
        category = nil
        interaction = nil
        searchRevision += 1
        tab = AppTab.search
    }

    var hasActiveFilters: Bool { category != nil || interaction != nil }

    func clearFilters() {
        category = nil
        interaction = nil
    }
}

/// Tab indices (also used by `-ML_tab` for automated screenshots).
enum AppTab {
    static let browse = 0
    static let search = 1
    static let favorites = 2
    static let settings = 3
}

/// Most-recently opened effects, newest first, persisted across launches.
@Observable
final class RecentsStore {
    private static let key = "app.recents"
    private static let limit = 10

    private(set) var ids: [String]

    init() {
        ids = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
    }

    func record(_ id: String) {
        guard ids.first != id else { return }
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        if ids.count > Self.limit { ids.removeLast(ids.count - Self.limit) }
        UserDefaults.standard.set(ids, forKey: Self.key)
    }

    func clear() {
        ids = []
        UserDefaults.standard.removeObject(forKey: Self.key)
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
