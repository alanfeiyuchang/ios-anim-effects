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
    static let appTitle = L("Motion Lexicon", "动效词典")
    static let appSubtitle = L("A living dictionary of premium iOS motion", "高级 iOS 动效活字典")
    static let browse = L("Browse", "浏览")
    static let search = L("Search", "搜索")
    static let favorites = L("Favorites", "收藏")
    static let settings = L("Settings", "设置")
    static let categories = L("Categories", "分类")
    static let allEffects = L("All Effects", "全部动效")
    static let effects = L("effects", "个动效")
    static let searchPrompt = L("Search effects, APIs, keywords…", "搜索动效、API、关键词…")
    static let parameters = L("Parameters", "参数调节")
    static let prompt = L("Prompt", "提示词")
    static let promptHint = L("A professional description you can hand to a designer, engineer or AI.", "可直接交给设计师、工程师或 AI 的专业描述。")
    static let copy = L("Copy", "复制")
    static let copied = L("Copied", "已复制")
    static let implementation = L("Implementation", "实现方式")
    static let apis = L("Key APIs", "关键 API")
    static let tags = L("Tags", "标签")
    static let reset = L("Reset", "重置")
    static let resetParams = L("Restore defaults", "恢复默认")
    static let interaction = L("Interaction", "交互方式")
    static let language = L("Language", "语言")
    static let appearance = L("Appearance", "外观")
    static let system = L("System", "跟随系统")
    static let light = L("Light", "浅色")
    static let dark = L("Dark", "深色")
    static let reduceGridMotion = L("Animate previews", "列表预览动画")
    static let about = L("About", "关于")
    static let aboutBody = L(
        "Every entry is a live, native SwiftUI implementation. Tweak parameters, study the implementation notes, and copy the prompt to describe the motion precisely.",
        "每个条目都是原生 SwiftUI 实时实现。调节参数、查看实现方式，并复制提示词以精确描述该动效。"
    )
    static let noFavorites = L("No favorites yet", "还没有收藏")
    static let noFavoritesHint = L("Tap the heart on any effect to keep it here.", "在任意动效页点击爱心即可收藏到这里。")
    static let noResults = L("No matching effects", "没有匹配的动效")
    static let all = L("All", "全部")
    static let tapToInteract = L("Interact with the stage above", "在上方舞台中与动效互动")
    static let requires = L("Requires", "需要")
    static let random = L("Surprise me", "随便看看")
    static let featured = L("Featured", "精选")
    static let sort = L("Sort", "排序")
}
