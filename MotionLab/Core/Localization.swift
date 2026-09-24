import SwiftUI

/// App-wide language. The whole UI (and every effect's prompt) switches at runtime.
enum AppLanguage: String, CaseIterable, Identifiable {
    case zh
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        }
    }

    /// `@AppStorage` key for the user's choice.
    static let storageKey = "app.language"

    /// Chinese when the device's first preferred language is Chinese, otherwise English.
    static var systemDefault: AppLanguage {
        (Locale.preferredLanguages.first ?? "").lowercased().hasPrefix("zh") ? .zh : .en
    }

    /// On first launch, stores the system-derived default. An existing choice
    /// (or a `-app.language` launch argument) is left untouched.
    static func registerInitialChoice(in defaults: UserDefaults = .standard) {
        guard defaults.string(forKey: storageKey) == nil else { return }
        defaults.set(systemDefault.rawValue, forKey: storageKey)
    }

    /// Locale injected into the SwiftUI environment so system formatting and
    /// string-catalog lookups follow the in-app language.
    var locale: Locale {
        switch self {
        case .zh: return Locale(identifier: "zh-Hans")
        case .en: return Locale(identifier: "en")
        }
    }
}

/// A bilingual string. Every user-facing string in the catalog is one of these.
struct LocalizedText: Hashable {
    let en: String
    let zh: String

    init(_ en: String, _ zh: String) {
        self.en = en
        self.zh = zh
    }

    init(en: String, zh: String) {
        self.en = en
        self.zh = zh
    }

    func callAsFunction(_ language: AppLanguage) -> String {
        switch language {
        case .en: return en
        case .zh: return zh
        }
    }

    /// Both variants, used for search.
    var all: String { en + " " + zh }
}

/// Short alias used throughout the catalog: `L("Press Scale", "按压缩放")`.
typealias L = LocalizedText

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .zh
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

extension Text {
    init(_ text: LocalizedText, _ language: AppLanguage) {
        self.init(verbatim: text(language))
    }
}

/// UI chrome strings.
enum Strings {
    static let appTitle = L("Motionary", "Motionary")
    static let appSubtitle = L("iOS Motion Dictionary · premium effects you can play with", "动效词典 · 可上手玩的 iOS 高级动效")
    static let browse = L("Browse", "浏览")
    static let search = L("Search", "搜索")
    static let favorites = L("Favorites", "收藏")
    static let settings = L("Settings", "设置")
    static let categories = L("Categories", "分类")
    /// Unit after a number: "15 categories" / "15 个分类".
    static let categoriesUnit = L("categories", "个分类")
    static let categoryFilter = L("Category", "分类")
    static let interactionFilter = L("Interaction", "交互")
    static let showAllEffects = L("Shows every effect in Search", "在搜索中查看全部动效")
    static let jumpToCategories = L("Scrolls to the category list", "跳到分类列表")
    static let showInteraction = L("Shows every effect with this interaction", "查看所有同类交互的动效")
    static let startWithThese = L("Start with these", "从这些开始")
    static let allEffects = L("All Effects", "全部动效")
    static let effects = L("effects", "个动效")
    static let searchPrompt = L("Search effects, APIs, keywords…", "搜索动效、API、关键词…")
    static let parameters = L("Parameters", "参数调节")
    static let prompt = L("Prompt", "提示词")
    static let promptHint = L("A professional description you can hand to a designer, engineer or AI.", "可直接交给设计师、工程师或 AI 的专业描述。")
    static let copied = L("Copied", "已复制")
    static let implementation = L("Implementation", "实现方式")
    static let apis = L("Key APIs", "关键 API")
    static let tags = L("Tags", "标签")
    static let reset = L("Reset", "重置")
    static let resetParams = L("Restore defaults", "恢复默认")
    static let language = L("Language", "语言")
    static let appearance = L("Appearance", "外观")
    static let system = L("System", "跟随系统")
    static let light = L("Light", "浅色")
    static let dark = L("Dark", "深色")
    static let motion = L("Motion", "动态效果")
    static let animatePreviews = L("Animate previews", "列表预览动画")
    static let animatePreviewsFooter = L(
        "When on, grid thumbnails act out their demos on their own. When off, each thumbnail shows a still frame, for calmer lists and longer battery life. Demos on an effect's page always play.",
        "开启后，列表缩略图会自动演示交互；关闭后，缩略图显示为静止画面，列表更安静也更省电。动效详情页中的演示始终可以播放。"
    )
    static let reduceMotionActive = L(
        "Reduce Motion is on in system settings, so grid thumbnails show a still frame. Demos on an effect's page still play when you interact with them.",
        "系统已开启「减弱动态效果」，列表缩略图将显示为静止画面。动效详情页中的演示仍可通过交互播放。"
    )
    static let version = L("Version", "版本")
    static let about = L("About", "关于")
    static let aboutBody = L(
        "Every entry is a live, native SwiftUI implementation. Tweak parameters, study the implementation notes, and copy the prompt to describe the motion precisely.",
        "每个条目都是原生 SwiftUI 实时实现。调节参数、查看实现方式，并复制提示词以精确描述该动效。"
    )
    static let noFavorites = L("No favorites yet", "还没有收藏")
    static let noFavoritesHint = L("Tap the heart on any effect to keep it here.", "在任意动效页点击爱心即可收藏到这里。")
    static let browseEffects = L("Browse Effects", "去逛逛动效")
    static let noResults = L("No matching effects", "没有匹配的动效")
    static let noResultsHint = L("Try another keyword, or clear the filters.", "换个关键词，或清除筛选条件试试。")
    static let clearFilters = L("Clear Filters", "清除筛选")
    static let trySearching = L("Try searching", "试试搜索")
    static let popularAPIs = L("Popular APIs", "常用 API")
    static let all = L("All", "全部")
    static let requires = L("Requires", "需要")
    static let random = L("Surprise me", "随便看看")
    static let featured = L("Featured", "精选")
    static let recent = L("Recently Viewed", "最近浏览")
    static let clear = L("Clear", "清除")
    static let moreInCategory = L("More in This Category", "同类动效")
    static let seeAll = L("See All", "查看全部")
    static let addFavorite = L("Add to Favorites", "加入收藏")
    static let removeFavorite = L("Remove from Favorites", "取消收藏")
    static let favorited = L("Favorited", "已收藏")
    static let sharePrompt = L("Share Prompt", "分享提示词")
    static let copyPrompt = L("Copy Prompt", "复制提示词")
    static let promptCopied = L("Prompt copied to the clipboard", "提示词已复制到剪贴板")
    static let searchTag = L("Search for this tag", "搜索此标签")
    static let openCategory = L("Opens the category", "打开该分类")
    static let resetDemo = L("Restarts the demo from its initial state", "让演示回到初始状态重新开始")

    // MARK: Families & variations

    static let families = L("Families", "系列")
    /// Unit after a number: "85 families" / "85 个系列".
    static let familiesUnit = L("families", "个系列")
    static let variations = L("Variations", "变体")
    static let browseMode = L("Browse by", "浏览方式")
    static let byFamily = L("Families", "按系列")
    static let familyViewMode = L("Layout", "布局")
    static let gridMode = L("Grid", "网格")
    static let compareMode = L("Compare", "对比")
    static let compareHint = L(
        "Every variation plays side by side on one shared clock. Replay All restarts them together.",
        "所有变体按同一节拍并排播放，点「全部重播」可让它们同时重新开始。"
    )
    static let openFamily = L("Shows every variation of this family", "查看该系列的全部变体")
    static let showVariation = L("Switches the page to this variation", "将页面切换到该变体")
    static let nextVariation = L("Next variation", "下一个变体")
    static let previousVariation = L("Previous variation", "上一个变体")
    static let swipeVariations = L("Swipe the title left or right to switch variations", "左右滑动标题即可切换变体")
    static let familyResults = L("Matching Families", "匹配的系列")
    static let allFamilies = L("All Families", "全部系列")
    static let allFamiliesSubtitle = L(
        "Every family of variations in the catalog, grouped by category. Each card plays one variation live.",
        "按分类排列的全部动效系列。每张卡片轮流实时播放其中一个变体。"
    )
    static let showAllFamilies = L("Shows every family, grouped by category", "按分类查看全部系列")
    static let browseAllFamilies = L("Browse all families", "浏览全部系列")
    static let browseByFamily = L("Browse by Family", "按系列浏览")
    static let searchFamilies = L("Search families", "搜索系列")
    static let noFamilyResults = L("No matching families", "没有匹配的系列")
    static let noFamilyResultsHint = L("Try another name, such as slider, spinner or toggle.", "换个名称试试，比如滑块、加载或开关。")
    static let jumpToCategory = L("Jumps to this category's families", "跳到该分类的系列")
    static let replayAll = L("Replay All", "全部重播")
    static let replayAllHint = L("Restarts every variation at the same moment", "让所有变体在同一时刻重新开始")
    static let anyInteraction = L("Any interaction", "全部交互")
    /// Joins the parts of a VoiceOver label: ", " / "，".
    static let listSeparator = L(", ", "，")
    /// Between a VoiceOver label's name and value: ": " / "：".
    static let labelSeparator = L(": ", "：")

    /// "1 family" / "6 families" / "6 个系列".
    static func familyCount(_ count: Int, _ language: AppLanguage) -> String {
        switch language {
        case .en: return count == 1 ? "1 family" : "\(count) families"
        case .zh: return "\(count) 个系列"
        }
    }

    /// "1 variation" / "5 variations" / "5 个变体".
    static func variationCount(_ count: Int, _ language: AppLanguage) -> String {
        switch language {
        case .en: return count == 1 ? "1 variation" : "\(count) variations"
        case .zh: return "\(count) 个变体"
        }
    }

    /// "6 families · 17 effects" / "6 个系列 · 17 个动效".
    static func familiesAndEffects(families: Int, effects: Int, _ language: AppLanguage) -> String {
        familyCount(families, language) + " · " + effectCount(effects, language)
    }

    /// "Variation 2 of 5" / "第 2 个变体，共 5 个" (VoiceOver).
    static func variationPosition(_ position: Int, of total: Int, _ language: AppLanguage) -> String {
        switch language {
        case .en: return "Variation \(position) of \(total)"
        case .zh: return "第 \(position) 个变体，共 \(total) 个"
        }
    }

    /// "15 categories" / "15 个分类".
    static func categoryCount(_ count: Int, _ language: AppLanguage) -> String {
        switch language {
        case .en: return count == 1 ? "1 category" : "\(count) categories"
        case .zh: return "\(count) 个分类"
        }
    }

    /// "1 effect" / "12 effects" / "12 个动效".
    static func effectCount(_ count: Int, _ language: AppLanguage) -> String {
        switch language {
        case .en: return count == 1 ? "1 effect" : "\(count) effects"
        case .zh: return "\(count) 个动效"
        }
    }
}
