import SwiftUI

/// Every piece of authored text in the trailer, grouped by scene, plus the voice-over script.
///
/// Defaults live here; `trailer/copy.json` at the repo root mirrors them key for key, and
/// `tools/trailer-editor.html` edits that file. `scripts/record-trailer.sh --copy <file>` copies the JSON into
/// the app container as `Documents/trailer-copy.json` before each launch, and `TrailerCopy.current` reads it
/// the first time the trailer touches its copy (during the white slate). The JSON may be partial: every
/// missing key, and every value of the wrong type, falls back to its default here.
///
/// Placeholders, expanded from the live catalog in every string (voice-over included): `{effects}` (effects),
/// `{categories}` (categories), `{families}` (effect families). `chat.bubbleTitle` also takes `{name}`, the
/// prompt effect's Chinese name.
///
/// `voiceover` is never drawn: the app writes the resolved copy (placeholders expanded) to
/// `Documents/trailer-resolved.json`, and the record script turns its voice-over lines into
/// `voiceover.srt` / `voiceover.txt` next to the video.
///
/// Effect names, prompts, parameter values and every string inside the embedded app screens come from the
/// real catalog and the app's own localisation. `prompt.effectID` / `prompt.textZh` / `prompt.textEn`
/// optionally override the prompt card (empty = catalog).
struct TrailerCopy: Codable, Equatable {
    var hook = Hook()
    var pain = Pain()
    var unknown = Unknown()
    var intro = Intro()
    var search = Search()
    var phone = Phone()
    var favorites = Favorites()
    var prompt = Prompt()
    var chat = Chat()
    var web = Web()
    var openSource = OpenSource()
    var end = End()
    var voiceover: [VoiceLine] = TrailerCopy.defaultVoiceover

    /// 0–6 s: the number tumbling in on prism digits, the line under it and the two stat chips.
    struct Hook: Codable, Equatable {
        /// Under the big effect count.
        var subtitle = "个 iOS 高级动效"
        /// Chip label after the category count.
        var categoriesLabel = "大分类"
        /// Chip label after the family count.
        var familiesLabel = "个动效家族"
    }

    /// 6–16 s: problem 1, the effect you can't describe, with vague words drifting around it.
    struct Pain: Codable, Equatable {
        var titleLine1 = "想要的动效，"
        var titleLine2 = "说不出来"
        /// The huge faint glyph behind the scene.
        var backdropMark = "？"
        /// Up to 12 words (the first 7 have hand-placed spots).
        var words = ["弹一下？", "顺滑一点？", "像果冻？", "来点高级感？", "duang 一下？", "要回弹吗？", "丝滑？"]
    }

    /// 16–24 s: problem 2, a grid of blurred unknown effects.
    struct Unknown: Codable, Equatable {
        var titleLine1 = "iOS 能做到什么？"
        var titleLine2 = "不知道"
        /// The mark on every blurred tile.
        var tileMark = "?"
    }

    /// 24–30 s: the brand reveal and the four pillars.
    struct Intro: Codable, Equatable {
        var title = "Motionary"
        var subtitle = "动效词典"
        /// Up to four chips under the name (2 × 2).
        var pillars = ["找灵感", "上手体验", "一键复制提示词", "完全开源"]
    }

    /// 30–44 s: the real Browse and Search screens on the phone.
    struct Search: Codable, Equatable {
        var title = "找灵感 · 一搜即达"
        var subtitle = "{effects} 个动效 · {categories} 大分类 · {families} 个家族"
        /// Typed into the app's real search field and really searched in the catalog.
        var query = "卡片"
    }

    /// 44–60 s: the app's detail page on the phone, several demos played by the finger.
    struct Phone: Codable, Equatable {
        var title = "真实上手体验"
        var subtitle = "每一下都有触感反馈"
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

    /// The author's two favourite demos on the phone (the day/night switch, then the gear checklist); the
    /// second line of the headline is the demo's name from the catalog.
    struct Favorites: Codable, Equatable {
        var title = "我最喜欢的"
    }

    /// 70–77 s: the prompt card.
    struct Prompt: Codable, Equatable {
        var title = "一键复制提示词"
        var subtitle = "中英双语 · 直接发给 AI"
        var cardTitle = "专业提示词"
        var languageZh = "中"
        var languageEn = "EN"
        var copyButton = "一键复制"
        var copiedButton = "已复制"
        /// Optional: effect whose name and prompt are shown (empty = the first demo played on the phone).
        var effectID = ""
        /// Optional: replaces the catalog's Chinese / English prompt text (empty = catalog).
        var textZh = ""
        var textEn = ""
    }

    /// 76–80 s: the AI chat the prompt is pasted into.
    struct Chat: Codable, Equatable {
        var assistantName = "AI 助手"
        var status = "在线"
        /// `{name}` = the prompt effect's name.
        var bubbleTitle = "{name} · 提示词"
        var reply = "收到！这就用 SwiftUI 实现："
    }

    /// 80–87 s: the documentation site in a browser beside the phone.
    struct Web: Codable, Equatable {
        var title = "网页随时看 · App 感受手感"
        var subtitle = ""
        /// Typed into the address bar.
        var url = "alanfeiyuchang.github.io/ios-anim-effects"
        var siteName = "Motionary"
        var siteTagline = "全部动效录像"
        var countBadge = "{effects} 个"
        /// Captions under the browser and under the phone.
        var webLabel = "网页 · 快速浏览全部录像"
        var appLabel = "App · 亲手感受手感"
    }

    /// The browser leaves the site for the repository on GitHub.
    struct OpenSource: Codable, Equatable {
        var title = "完全开源"
        var subtitle = "欢迎 Star · 一起补充动效"
        /// Typed into the address bar.
        var url = "github.com/alanfeiyuchang/ios-anim-effects"
    }

    /// 87–90 s: the end card under the app icon.
    struct End: Codable, Equatable {
        var title = "Motionary"
        var subtitle = "动效词典 · iOS Motion Dictionary"
        var tagline = "让动效说得清 · 看得见 · 摸得着"
        /// A small ember pill under the tagline; "" hides it.
        var upcoming = "更多动效后续加入"
    }

    /// One voice-over line, `start` … `end` in seconds of the cut. Not drawn on screen.
    struct VoiceLine: Codable, Equatable {
        var start: Double = 0
        var end: Double = 0
        var text: String = ""
    }

    static let defaultVoiceover: [VoiceLine] = [
        VoiceLine(start: 0.0, end: 2.033, text: "400多个iOS动效"),
        VoiceLine(start: 2.033, end: 4.3, text: "帮你找到适合的丝滑效果"),
        VoiceLine(start: 4.3, end: 6.833, text: "做 app的时候你一定遇到过这种情况"),
        VoiceLine(start: 6.833, end: 9.0, text: "脑子里有感觉 却说不清"),
        VoiceLine(start: 9.0, end: 10.933, text: "只会说来点高级感"),
        VoiceLine(start: 10.933, end: 13.766, text: "跟设计师、跟 AI 都讲不明白"),
        VoiceLine(start: 13.766, end: 15.166, text: "更难的是"),
        VoiceLine(start: 15.166, end: 18.6, text: "你根本不知道 iOS 原生能做出哪些效果"),
        VoiceLine(start: 18.6, end: 20.6, text: "所以我做了 Motionary"),
        VoiceLine(start: 20.6, end: 23.8, text: "一本可以上手体验的 iOS 动效词典"),
        VoiceLine(start: 23.8, end: 26.466, text: "{effects} 个动效 按 {categories} 个分类"),
        VoiceLine(start: 26.466, end: 28.266, text: "{families} 个家族整理"),
        VoiceLine(start: 28.266, end: 30.5, text: "输入关键词就能搜到"),
        VoiceLine(start: 30.5, end: 33.166, text: "点「质感交互」 看最精致的那一批"),
        VoiceLine(start: 33.166, end: 36.166, text: "每个动效都是真实运行的 SwiftUI"),
        VoiceLine(start: 36.166, end: 38.4, text: "用手指去按、去拖"),
        VoiceLine(start: 38.4, end: 40.9, text: "配合 Taptic Engine 的触感反馈"),
        VoiceLine(start: 40.9, end: 43.066, text: "手感好不好 一试就知道"),
        VoiceLine(start: 43.066, end: 46.066, text: "其中我最喜欢的有昼夜切换开关"),
        VoiceLine(start: 46.066, end: 48.233, text: "能看到丝滑的转换效果"),
        VoiceLine(start: 48.233, end: 50.033, text: "还有这个装备清单"),
        VoiceLine(start: 50.033, end: 52.433, text: "装备齐全后的成就感满满"),
        VoiceLine(start: 52.433, end: 55.7, text: "每个动效都配有中英双语的专业提示词"),
        VoiceLine(start: 55.7, end: 58.833, text: "写清时长、曲线和弹簧参数"),
        VoiceLine(start: 58.833, end: 61.933, text: "一键复制给 AI 或设计师 直接复现"),
        VoiceLine(start: 61.933, end: 65.2, text: "想快速浏览 打开网页就能看全部录像"),
        VoiceLine(start: 65.2, end: 68.033, text: "想感受手感 就在 App 里亲手试试"),
        VoiceLine(start: 68.033, end: 71.033, text: "整个项目已经开源，欢迎查看"),
        VoiceLine(start: 71.033, end: 73.266, text: "Motionary 让动效说得清"),
        VoiceLine(start: 73.266, end: 75.4, text: "看得见、摸得着"),
    ]
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
        unknown = c.trailerCopyValue(.unknown, d.unknown)
        intro = c.trailerCopyValue(.intro, d.intro)
        search = c.trailerCopyValue(.search, d.search)
        phone = c.trailerCopyValue(.phone, d.phone)
        favorites = c.trailerCopyValue(.favorites, d.favorites)
        prompt = c.trailerCopyValue(.prompt, d.prompt)
        chat = c.trailerCopyValue(.chat, d.chat)
        web = c.trailerCopyValue(.web, d.web)
        openSource = c.trailerCopyValue(.openSource, d.openSource)
        end = c.trailerCopyValue(.end, d.end)
        voiceover = c.trailerCopyValue(.voiceover, d.voiceover)
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

extension TrailerCopy.Unknown {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        titleLine1 = c.trailerCopyValue(.titleLine1, d.titleLine1)
        titleLine2 = c.trailerCopyValue(.titleLine2, d.titleLine2)
        tileMark = c.trailerCopyValue(.tileMark, d.tileMark)
    }
}

extension TrailerCopy.Intro {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        pillars = c.trailerCopyValue(.pillars, d.pillars)
    }
}

extension TrailerCopy.Search {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        query = c.trailerCopyValue(.query, d.query)
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

extension TrailerCopy.Favorites {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
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
        webLabel = c.trailerCopyValue(.webLabel, d.webLabel)
        appLabel = c.trailerCopyValue(.appLabel, d.appLabel)
    }
}

extension TrailerCopy.OpenSource {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        let address: String = c.trailerCopyValue(.url, d.url)
        url = address.isEmpty ? d.url : address
    }
}

extension TrailerCopy.End {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self()
        title = c.trailerCopyValue(.title, d.title)
        subtitle = c.trailerCopyValue(.subtitle, d.subtitle)
        tagline = c.trailerCopyValue(.tagline, d.tagline)
        upcoming = c.trailerCopyValue(.upcoming, d.upcoming)
    }
}

extension TrailerCopy.VoiceLine {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let start: Double = c.trailerCopyValue(.start, 0)
        let end: Double = c.trailerCopyValue(.end, start)
        self.start = start
        self.end = end
        text = c.trailerCopyValue(.text, "")
    }
}

// MARK: - Loading

extension TrailerCopy {
    /// File name inside the app's Documents folder (written there by `scripts/record-trailer.sh`).
    static let fileName = "trailer-copy.json"
    /// The copy as shown (placeholders expanded) plus the catalog counts, written at start for the record
    /// script (it builds the voice-over subtitles from it).
    static let resolvedFileName = "trailer-resolved.json"

    /// The copy the trailer shows: `Documents/trailer-copy.json` if present (partial allowed), else the
    /// defaults; placeholders expanded. Loaded once, on first use (`TrailerData.warmUp`, during the slate).
    static let current: TrailerCopy = load()

    static func load() -> TrailerCopy {
        var copy = TrailerCopy()
        let folder: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let folder {
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
        let resolved: TrailerCopy = copy.sanitized().expanding(effects: effects, categories: categories, families: families)
        if let folder {
            resolved.writeResolved(to: folder.appendingPathComponent(resolvedFileName), effects: effects, categories: categories, families: families)
        }
        return resolved
    }

    /// `{ "counts": { effects, categories, families }, "duration": …, "copy": { …resolved copy… } }`.
    private func writeResolved(to url: URL, effects: Int, categories: Int, families: Int) {
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data)
        else { return }
        let counts: [String: Int] = ["effects": effects, "categories": categories, "families": families]
        let root: [String: Any] = [
            "counts": counts,
            "duration": TrailerCanvas.duration,
            "copy": object,
        ]
        guard let output = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]) else { return }
        do {
            try output.write(to: url, options: .atomic)
            print("trailer: resolved copy written to \(url.path)")
        } catch {
            print("trailer: could not write \(url.path): \(error)")
        }
    }

    /// Guards the few values the choreography depends on.
    func sanitized() -> TrailerCopy {
        let defaults = TrailerCopy()
        var copy = self
        if copy.search.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            copy.search.query = defaults.search.query
        }
        copy.pain.words = Array(copy.pain.words.filter { !$0.isEmpty }.prefix(TrailerCopy.maxWords))
        copy.intro.pillars = Array(copy.intro.pillars.filter { !$0.isEmpty }.prefix(TrailerCopy.maxPillars))
        if copy.web.url.isEmpty {
            copy.web.url = defaults.web.url
        }
        let lines: [VoiceLine] = copy.voiceover.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        copy.voiceover = lines
            .map { line -> VoiceLine in
                var fixed = line
                fixed.start = max(line.start, 0)
                fixed.end = max(line.end, fixed.start)
                return fixed
            }
            .sorted { $0.start < $1.start }
        return copy
    }

    static let maxWords: Int = 12
    static let maxPillars: Int = 4

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
