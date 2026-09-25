import SwiftUI

// MARK: - The real app, as a screen recording

/// What the embedded app screens show on one frame (see `TrailerFind.frame`). Equatable, so the screens
/// only update when something they show changes (not on every trailer frame).
struct TrailerAppFrame: Equatable {
    var showsBrowse: Bool
    var showsSearch: Bool
    /// Search fades in over Browse in 0.15 s, like a tab switch.
    var searchOpacity: Double
    /// Browse's scroll offset (device points).
    var browseScroll: CGFloat
    /// Characters of the query typed so far.
    var typed: Int
    /// The Signature Interactions chip is selected.
    var filtered: Bool
    /// The tab bar's search button is selected.
    var searchSelected: Bool
}

/// The app's real Browse and Search screens (`BrowseView`, `SearchView`, each in its own
/// `NavigationStack`), laid out on a 402 × 874 pt iPhone screen: status-bar space on top (the drawn phone
/// adds the status bar and the Dynamic Island over it) and a floating tab bar at the bottom. The phone
/// scales the whole screen uniformly into its display.
///
/// The screens are driven like a screen recording: Browse's scroll view follows `browseScroll` through a
/// `ScrollPosition`, and Search reads the app's own `AppNavigator` (query and category filter), which
/// `TrailerSearchScreen` sets as the script types and taps. Nothing here is interactive.
struct TrailerAppScreen: View, Equatable {
    let state: TrailerAppFrame

    var body: some View {
        let size = TrailerFind.deviceSize
        ZStack(alignment: .top) {
            Palette.pageBackground
            if state.showsBrowse {
                TrailerBrowseScreen(scroll: state.browseScroll)
                    .padding(.top, TrailerFind.statusBar)
            }
            if state.showsSearch {
                ZStack(alignment: .top) {
                    Palette.pageBackground
                    TrailerSearchScreen(typed: state.typed, filtered: state.filtered)
                        .padding(.top, TrailerFind.statusBar)
                }
                .opacity(state.searchOpacity)
            }
            // The page ink behind the status bar fades into the navigation bar below it.
            LinearGradient(
                colors: [Palette.pageBackground, Palette.pageBackground.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: TrailerFind.statusBar + 10)
            .allowsHitTesting(false)
            TrailerTabBar(searchSelected: state.searchSelected)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, .dark)
        .environment(\.appLanguage, .zh)
        .environment(\.locale, AppLanguage.zh.locale)
        // Scaled into the drawn phone, the screens never report scroll visibility, so thumbnails would
        // stay blank; count them all as on screen.
        .environment(\.previewsForcedOnScreen, true)
        .allowsHitTesting(false)
    }
}

/// `BrowseView` in a navigation stack, scrolled by the script.
private struct TrailerBrowseScreen: View {
    let scroll: CGFloat
    @State private var position = ScrollPosition(edge: .top)

    var body: some View {
        NavigationStack {
            BrowseView()
                .scrollPosition($position)
                .navigationDestination(for: Route.self) { _ in
                    Color.clear
                }
        }
        .ignoresSafeArea()
        .onChange(of: scroll, initial: true) { _, value in
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                position.scrollTo(y: value)
            }
        }
    }
}

/// `SearchView` in a navigation stack. The script types the query into the app's `AppNavigator` (the
/// search field is bound to it) and selects the Signature Interactions category, exactly what the search
/// field and the category chip do when a person uses them.
private struct TrailerSearchScreen: View {
    let typed: Int
    let filtered: Bool
    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        NavigationStack {
            SearchView()
                .navigationDestination(for: Route.self) { _ in
                    Color.clear
                }
        }
        .ignoresSafeArea()
        .onAppear {
            navigator.interaction = nil
            navigator.category = nil
            applyQuery()
            applyFilter(animated: false)
        }
        .onChange(of: typed) {
            applyQuery()
        }
        .onChange(of: filtered) {
            applyFilter(animated: true)
        }
    }

    private func applyQuery() {
        let characters: [Character] = Array(TrailerData.query)
        let count: Int = min(max(typed, 0), characters.count)
        navigator.query = String(characters.prefix(count))
    }

    private func applyFilter(animated: Bool) {
        let category: EffectCategory? = filtered ? .showcase : nil
        guard navigator.category != category else { return }
        if animated {
            // Same animation the chip itself uses when tapped.
            withAnimation(ShellMotion.selection) { navigator.category = category }
        } else {
            navigator.category = category
        }
    }
}

/// The floating tab bar (iOS 26 style: a glass capsule with Browse, Favorites and Settings, and the
/// search button on its own), with the app's own tab titles and symbols.
private struct TrailerTabBar: View {
    let searchSelected: Bool

    var body: some View {
        let height = TrailerFind.tabBarHeight
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                item(symbol: "square.grid.2x2.fill", title: Strings.browse.zh, selected: !searchSelected)
                item(symbol: "heart.fill", title: Strings.favorites.zh, selected: false)
                item(symbol: "gearshape.fill", title: Strings.settings.zh, selected: false)
            }
            .padding(4)
            .frame(height: height)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75))
            Image(systemName: "magnifyingglass")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(searchSelected ? Palette.accent : Color.white)
                .frame(width: height, height: height)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75))
        }
        .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, TrailerFind.tabBarBottom)
    }

    private func item(symbol: String, title: String, selected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
            Text(verbatim: title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(selected ? Palette.accent : Color.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Capsule()
                .fill(Color.white.opacity(selected ? 0.1 : 0))
        }
    }
}
