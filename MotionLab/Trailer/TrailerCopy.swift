import SwiftUI

/// Every piece of authored on-screen text in the trailer, grouped by scene.
///
/// Defaults live here; `trailer/copy.json` at the repo root mirrors them key for key, and
/// `tools/trailer-editor.html` edits that file. `scripts/record-trailer.sh --copy <file>` copies the JSON into
/// the app container as `Documents/trailer-copy.json` before each launch, and `TrailerCopy.current` reads it
/// the first time the trailer touches its copy (during the white slate). The JSON may be partial: every
/// missing key, and every value of the wrong type, falls back to its default here.
///
/// Placeholders, expanded from the live catalog in every string: `{effects}` (effects), `{categories}`
/// (categories), `{families}` (effect families). `chat.bubbleTitle` also takes `{name}`, the prompt
/// effect's Chinese name.
///
/// Effect names, prompts and parameter values shown in tiles and on the phone come from the real catalog.
/// `prompt.effectID` / `prompt.textZh` / `prompt.textEn` optionally override the prompt card (empty = catalog).
struct TrailerCopy: Codable, Equatable {
    var hook = Hook()
    var pain = Pain()
    var search = Search()
    var phone = Phone()
    var tune = Tune()
    var prompt = Prompt()
    var chat = Chat()
    var web = Web()
    var end = End()
    var touch = Touch()

    /// 0–5 s: the counting number, the line under it and the two stat chips.
    struct Hook: Codable, Equatable {
        /// Under the big effect count.
        var subtitle = "个 iOS 高级动效"
        /// Chip label after the category count.
        var categoriesLabel = "大分类"
        /// Chip label after the family count.
        var familiesLabel = "个动效家族"
    }

    /// 5–11 s: the question and the vague words drifting around it.
    struct Pain: Codable, Equatable {
        var titleLine1 = "想要的动效，"
        var titleLine2 = "说不出名字？"
        /// The huge faint glyph behind the scene.
        var backdropMark = "？"
        /// Up to 12 words (the first 7 have hand-placed spots).
        var words = ["弹一下？", "顺滑一点？", "像果冻？", "有点高级感？", "duang 一下？", "要回弹吗？", "丝滑？"]
    }

    /// 10–21 s: search field, filter chips and results.
    struct Search: Codable, Equatable {
        var title = "一搜即达"
        var subtitle = "{effects} 个动效秒速定位"
        var placeholder = "搜索动效、控件、手势…"
        /// Typed into the field and really searched in the catalog.
        var query = "卡片"
        var resultSuffix = "个结果"
        /// Filter chips; the finger taps the second one (it filters to the Cards category).
        var chips = ["全部", "卡片", "质感交互", "按钮"]
    }

    /// 21–36 s: the app's detail page on an iPhone.
    struct Phone: Codable, Equatable {
        var title = "真实上手体验"
        var subtitle = "每一下都有触感"
        var statusTime = "9:41"
        /// Hint pill under the stage, per interaction type of the demo shown.
        var hintTap = "点一下试试"
        var hintGesture = "按住拖动试试"
        var hintScroll = "上下滑动试试"
        var hintLoop = "自动循环播放"
        var hintState = "点一下切换状态"
        /// Parameter card header, its reset link, and the text for demos without parameters.
        var paramsHeader = "参数"
        var reset = "重置"
        var noParams = "无可调参数"
    }

    /// 36–44 s: the spring lab on the phone and its sliders.
    struct Tune: Codable, Equatable {
        var title = "参数实时可调"
        var subtitle = "弹簧 · 阻尼 · 响应，随手试"
        /// Nav title, tag and hint of the lab page.
        var pageTitle = "弹簧参数"
        var pageTag = "实时预览"
        var hint = "拖动滑块，实时预览"
        var dampingLabel = "阻尼"
        var responseLabel = "响应"
        /// Label on the dashed target line of the curve.
        var targetLabel = "目标"
    }

    /// 44–50 s: the prompt card.
    struct Prompt: Codable, Equatable {
        var title = "专业中英提示词"
        var subtitle = "一键复制给 AI"
        var cardTitle = "专业提示词"
        var languageZh = "中"
        var languageEn = "EN"
        var copyButton = "一键复制"
        var copiedButton = "已复制"
        /// Optional: effect whose name and prompt are shown (empty = the searched hero, cards.flip).
        var effectID = ""
        /// Optional: replaces the catalog's Chinese / English prompt text (empty = catalog).
        var textZh = ""
        var textEn = ""
    }

    /// 49–52 s: the AI chat the prompt is pasted into.
    struct Chat: Codable, Equatable {
        var assistantName = "AI 助手"
        var status = "在线"
        /// `{name}` = the prompt effect's name.
        var bubbleTitle = "{name} · 提示词"
        var reply = "收到！这就用 SwiftUI 实现："
    }

    /// 52–57 s: the browser window with the documentation site.
    struct Web: Codable, Equatable {
        var title = "网页版全部动效"
        var subtitle = "录像一览，随时查看"
        /// Typed into the address bar.
        var url = "alanfeiyuchang.github.io/ios-anim-effects"
        var siteName = "Motionary"
        var siteTagline = "全部动效录像一览"
        var countBadge = "{effects} 个"
    }

    /// 57–60 s: the end card under the app icon.
    struct End: Codable, Equatable {
        var title = "Motionary"
        var subtitle = "动效词典 · iOS Motion Dictionary"
        var tagline = "{effects} 个可上手玩的 iOS 高级动效"
    }

    /// Shown on every simulated tap, whole trailer.
    struct Touch: Codable, Equatable {
        var hapticBadge = "触感"
    }
}

// MARK: - Lenient decoding (partial JSON: missing or mistyped keys keep their defaults)

private extension KeyedDecodingContainer {
    func trailerCopyValue<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        let value: T? = try? decodeIfPresent(T.self, forKey: key)
        return value ?? fallback
    }
}

extension TrailerCopy {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = TrailerCopy()
        hook = c.trailerCopyValue(.hook, d.hook)
        pain = c.trailerCopyValue(.pain, d.pain)
        search = c.trailerCopyValue(.search, d.search)
        phone = c.trailerCopyValue(.phone, d.phone)
        tune = c.trailerCopyValue(.tune, d.tune)
        prompt = c.trailerCopyValue(.prompt, d.prompt)
        chat = c.trailerCopyValue(.chat, d.chat)
        web = c.trailerCopyValue(.web, d.web)
        end = c.trailerCopyValue(.end, d.end)
        touch = c.trailerCopyValue(.touch, d.touch)
    }
}

extension TrailerCopy.Hook {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        categoriesLabel = c.trailerCopyValue(.categoriesLabel, d.categoriesLabel)
        familiesLabel = c.trailerCopyValue(.familiesLabel, d.familiesLabel)
    }
}

extension TrailerCopy.Pain {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        titleLine1 = c.trailerCopyValue(.titleLine1, d.titleLine1)
        titleLine2 = c.trailerCopyValue(.titleLine2, d.titleLine2)
        backdropMark = c.trailerCopyValue(.backdropMark, d.backdropMark)
        words = c.trailerCopyValue(.words, d.words)
    }
}

extension TrailerCopy.Search {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        placeholder = c.trailerCopyValue(.placeholder, d.placeholder)
        query = c.trailerCopyValue(.query, d.query)
        resultSuffix = c.trailerCopyValue(.resultSuffix, d.resultSuffix)
        chips = c.trailerCopyValue(.chips, d.chips)
    }
}

extension TrailerCopy.Phone {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        statusTime = c.trailerCopyValue(.statusTime, d.statusTime)
        hintTap = c.trailerCopyValue(.hintTap, d.hintTap)
        hintGesture = c.trailerCopyValue(.hintGesture, d.hintGesture)
        hintScroll = c.trailerCopyValue(.hintScroll, d.hintScroll)
        hintLoop = c.trailerCopyValue(.hintLoop, d.hintLoop)
        hintState = c.trailerCopyValue(.hintState, d.hintState)
        paramsHeader = c.trailerCopyValue(.paramsHeader, d.paramsHeader)
        reset = c.trailerCopyValue(.reset, d.reset)
        noParams = c.trailerCopyValue(.noParams, d.noParams)
    }
}

extension TrailerCopy.Tune {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        pageTitle = c.trailerCopyValue(.pageTitle, d.pageTitle)
        pageTag = c.trailerCopyValue(.pageTag, d.pageTag)
        hint = c.trailerCopyValue(.hint, d.hint)
        dampingLabel = c.trailerCopyValue(.dampingLabel, d.dampingLabel)
        responseLabel = c.trailerCopyValue(.responseLabel, d.responseLabel)
        targetLabel = c.trailerCopyValue(.targetLabel, d.targetLabel)
    }
}

extension TrailerCopy.Prompt {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        cardTitle = c.trailerCopyValue(.cardTitle, d.cardTitle)
        languageZh = c.trailerCopyValue(.languageZh, d.languageZh)
        languageEn = c.trailerCopyValue(.languageEn, d.languageEn)
        copyButton = c.trailerCopyValue(.copyButton, d.copyButton)
        copiedButton = c.trailerCopyValue(.copiedButton, d.copiedButton)
        effectID = c.trailerCopyValue(.effectID, d.effectID)
        textZh = c.trailerCopyValue(.textZh, d.textZh)
        textEn = c.trailerCopyValue(.textEn, d.textEn)
    }
}

extension TrailerCopy.Chat {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        assistantName = c.trailerCopyValue(.assistantName, d.assistantName)
        status = c.trailerCopyValue(.status, d.status)
        bubbleTitle = c.trailerCopyValue(.bubbleTitle, d.bubbleTitle)
        reply = c.trailerCopyValue(.reply, d.reply)
    }
}

extension TrailerCopy.Web {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        url = c.trailerCopyValue(.url, d.url)
        siteName = c.trailerCopyValue(.siteName, d.siteName)
        siteTagline = c.trailerCopyValue(.siteTagline, d.siteTagline)
        countBadge = c.trailerCopyValue(.countBadge, d.countBadge)
    }
}

extension TrailerCopy.End {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        tagline = c.trailerCopyValue(.tagline, d.tagline)
    }
}

extension TrailerCopy.Touch {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        hapticBadge = c.trailerCopyValue(.hapticBadge, d.hapticBadge)
    }
}

// MARK: - Loading

extension TrailerCopy {
    /// File name inside the app's Documents folder (written there by `scripts/record-trailer.sh`).
    static let fileName = "trailer-copy.json"

    /// The copy the trailer shows: `Documents/trailer-copy.json` if present (partial allowed), else the
    /// defaults; placeholders expanded. Loaded once, on first use (`TrailerData.warmUp`, during the slate).
    static let current: TrailerCopy = load()

    static func load() -> TrailerCopy {
        var copy = TrailerCopy()
        if let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = folder.appendingPathComponent(fileName)
            if let data = try? Data(contentsOf: url) {
                do {
                    copy = try JSONDecoder().decode(TrailerCopy.self, from: data)
                    print("trailer: copy loaded from \(url.path)")
                } catch {
                    print("trailer: ignoring unreadable \(url.path): \(error)")
                }
            }
        }
        let effects: Int = EffectLibrary.all.count
        let categories: Int = EffectCategory.allCases.count
        let families: Int = EffectFamilies.all.count
        return copy.sanitized().expanding(effects: effects, categories: categories, families: families)
    }

    /// Guards the few values the choreography depends on.
    func sanitized() -> TrailerCopy {
        let defaults = TrailerCopy()
        var copy = self
        if copy.search.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            copy.search.query = defaults.search.query
        }
        // The finger taps the second chip, so there must be at least two.
        if copy.search.chips.count < 2 {
            copy.search.chips = defaults.search.chips
        }
        copy.search.chips = Array(copy.search.chips.prefix(6))
        copy.pain.words = Array(copy.pain.words.filter { !$0.isEmpty }.prefix(TrailerCopy.maxWords))
        if copy.web.url.isEmpty {
            copy.web.url = defaults.web.url
        }
        return copy
    }

    static let maxWords: Int = 12

    /// Replaces `{effects}`, `{categories}` and `{families}` in every string (a JSON round trip, so no field
    /// can be missed).
    func expanding(effects: Int, categories: Int, families: Int) -> TrailerCopy {
        let replacements: [(String, String)] = [
            ("{effects}", "\(effects)"),
            ("{categories}", "\(categories)"),
            ("{families}", "\(families)"),
        ]
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data),
              let expanded = try? JSONSerialization.data(withJSONObject: Self.expand(object, replacements)),
              let copy = try? JSONDecoder().decode(TrailerCopy.self, from: expanded)
        else { return self }
        return copy
    }

    private static func expand(_ value: Any, _ replacements: [(String, String)]) -> Any {
        if let text = value as? String {
            var result = text
            for (key, replacement) in replacements {
                result = result.replacingOccurrences(of: key, with: replacement)
            }
            return result
        }
        if let list = value as? [Any] {
            return list.map { expand($0, replacements) }
        }
        if let object = value as? [String: Any] {
            return object.mapValues { expand($0, replacements) }
        }
        return value
    }

    /// nil for an empty string (an empty subtitle hides the line).
    static func optional(_ text: String) -> String? {
        text.isEmpty ? nil : text
    }

    /// Rough rendered width of `text` in the system font at `size` (CJK ≈ 1 em, Latin ≈ 0.6 em), used to size
    /// chips, pills and buttons around authored text.
    static func estimatedWidth(_ text: String, size: CGFloat) -> CGFloat {
        var ems: CGFloat = 0
        for character in text {
            if character == " " {
                ems += 0.3
            } else if character.isASCII {
                ems += 0.6
            } else {
                ems += 1
            }
        }
        return ems * size
    }
}
