import SwiftUI

// MARK: - Category

enum EffectCategory: String, CaseIterable, Identifiable {
    case showcase
    case buttons
    case inputs
    case loading
    case feedback
    case morph
    case navigation
    case cards
    case scroll
    case text
    case icons
    case gestures
    case charts
    case backgrounds
    case shaders

    var id: String { rawValue }

    var title: LocalizedText {
        switch self {
        case .showcase: return L("Signature Interactions", "质感交互精选")
        case .buttons: return L("Buttons", "按钮")
        case .inputs: return L("Inputs & Controls", "输入与控件")
        case .loading: return L("Loading & Progress", "加载与进度")
        case .feedback: return L("Feedback & Alerts", "反馈与提示")
        case .morph: return L("Transitions & Morphing", "转场与形变")
        case .navigation: return L("Navigation & Menus", "导航与菜单")
        case .cards: return L("Cards", "卡片")
        case .scroll: return L("Scroll & Lists", "滚动与列表")
        case .text: return L("Text & Numbers", "文字与数字")
        case .icons: return L("Icons & Symbols", "图标与符号")
        case .gestures: return L("Gestures & Physics", "手势与物理")
        case .charts: return L("Data & Charts", "数据与图表")
        case .backgrounds: return L("Backgrounds & Ambience", "背景与氛围")
        case .shaders: return L("Shaders & Materials", "着色器与材质")
        }
    }

    var subtitle: LocalizedText {
        switch self {
        case .showcase: return L("Dark, tactile widget cards with rich micro-interactions", "暗黑高级质感卡片与细腻微交互")
        case .buttons: return L("Press, glow, magnetic, ripple and state buttons", "按压、辉光、磁吸、涟漪与状态按钮")
        case .inputs: return L("Toggles, sliders, fields, pickers and steppers", "开关、滑块、输入框、选择器与步进器")
        case .loading: return L("Spinners, skeletons, progress and load buttons", "旋转器、骨架屏、进度条与加载按钮")
        case .feedback: return L("Toasts, success, error, confetti and badges", "吐司、成功、错误、彩纸与角标")
        case .morph: return L("Hero expands, matched geometry and shape morphs", "英雄展开、几何匹配与形状形变")
        case .navigation: return L("Tab bars, menus, drawers and segmented controls", "标签栏、菜单、抽屉与分段控件")
        case .cards: return L("Tilt, flip, stack, swipe and wallet cards", "倾斜、翻转、堆叠、滑动与钱包卡片")
        case .scroll: return L("Scroll-driven, parallax, sticky and list motion", "滚动驱动、视差、吸顶与列表动效")
        case .text: return L("Typewriter, counters, reveals and kinetic type", "打字机、数字滚动、揭示与动态排版")
        case .icons: return L("SF Symbol effects and animated glyph morphs", "SF Symbol 特效与图标形变")
        case .gestures: return L("Drag, fling, rubber-band, snap and pinch", "拖拽、惯性、橡皮筋、吸附与捏合")
        case .charts: return L("Animated bars, rings, lines and gauges", "动态柱状图、圆环、折线与仪表")
        case .backgrounds: return L("Mesh gradients, aurora, particles and blobs", "网格渐变、极光、粒子与流体")
        case .shaders: return L("Metal shaders, glass and material effects", "Metal 着色器、玻璃与材质")
        }
    }

    var symbol: String {
        switch self {
        case .showcase: return "wand.and.stars"
        case .buttons: return "hand.tap.fill"
        case .inputs: return "slider.horizontal.3"
        case .loading: return "hourglass"
        case .feedback: return "bell.badge.fill"
        case .morph: return "square.on.circle"
        case .navigation: return "sidebar.left"
        case .cards: return "rectangle.stack.fill"
        case .scroll: return "scroll.fill"
        case .text: return "textformat"
        case .icons: return "star.square.on.square.fill"
        case .gestures: return "hand.draw.fill"
        case .charts: return "chart.bar.xaxis"
        case .backgrounds: return "sparkles"
        case .shaders: return "cube.transparent.fill"
        }
    }

    var gradient: [Color] {
        switch self {
        case .showcase: return [Color(hex: 0xFFB02E), Color(hex: 0xFF5A1F)]
        case .buttons: return [Color(hex: 0x6E7BFF), Color(hex: 0xA46BFF)]
        case .inputs: return [Color(hex: 0x3AC4FF), Color(hex: 0x4F7CFF)]
        case .loading: return [Color(hex: 0x21D4A8), Color(hex: 0x2A9DF4)]
        case .feedback: return [Color(hex: 0xFF8A5B), Color(hex: 0xFF4D7A)]
        case .morph: return [Color(hex: 0xB86BFF), Color(hex: 0xFF6BC1)]
        case .navigation: return [Color(hex: 0x5B8CFF), Color(hex: 0x39D0D8)]
        case .cards: return [Color(hex: 0xFF6B8B), Color(hex: 0xFFB36B)]
        case .scroll: return [Color(hex: 0x4ED6A0), Color(hex: 0x5AA8FF)]
        case .text: return [Color(hex: 0xFFC247), Color(hex: 0xFF7A45)]
        case .icons: return [Color(hex: 0x7C5CFF), Color(hex: 0x4FA3FF)]
        case .gestures: return [Color(hex: 0x00C2A8), Color(hex: 0x7BE36B)]
        case .charts: return [Color(hex: 0x4F7CFF), Color(hex: 0x8A5CFF)]
        case .backgrounds: return [Color(hex: 0xFF5FA2), Color(hex: 0x7B61FF)]
        case .shaders: return [Color(hex: 0x2BD9FE), Color(hex: 0xAA5CFF)]
        }
    }
}

// MARK: - Interaction

/// How the user drives the effect. Used as a secondary filter facet.
enum EffectInteraction: String, CaseIterable, Identifiable {
    case tap
    case gesture
    case scroll
    case loop
    case state

    var id: String { rawValue }

    var title: LocalizedText {
        switch self {
        case .tap: return L("Tap", "点击")
        case .gesture: return L("Gesture", "手势")
        case .scroll: return L("Scroll", "滚动")
        case .loop: return L("Ambient loop", "循环")
        case .state: return L("State change", "状态切换")
        }
    }

    /// Short instruction shown under the detail stage.
    var hint: LocalizedText {
        switch self {
        case .tap: return L("Tap the stage to play", "点击舞台试玩")
        case .gesture: return L("Drag or press on the stage", "在舞台上拖拽或按压")
        case .scroll: return L("Scroll inside the stage", "在舞台内滚动")
        case .loop: return L("Plays on its own — tune it below", "自动循环播放，可在下方调参")
        case .state: return L("Tap to switch states", "点击切换状态")
        }
    }

    var symbol: String {
        switch self {
        case .tap: return "hand.point.up.left.fill"
        case .gesture: return "hand.draw"
        case .scroll: return "arrow.up.and.down"
        case .loop: return "repeat"
        case .state: return "switch.2"
        }
    }
}

// MARK: - Parameters

struct ParamSpec: Identifiable {
    enum Kind {
        case slider(ClosedRange<Double>, step: Double?)
        case toggle
        case choice([LocalizedText])
    }

    let id: String
    let name: LocalizedText
    let kind: Kind
    let defaultValue: Double
    /// Decimal places shown for slider values.
    let decimals: Int
    /// Optional unit appended to the value (e.g. "s", "°", "pt").
    let unit: String

    /// A continuous (or stepped) numeric parameter.
    static func slider(
        _ id: String,
        _ name: LocalizedText,
        _ range: ClosedRange<Double>,
        default value: Double,
        step: Double? = nil,
        decimals: Int = 2,
        unit: String = ""
    ) -> ParamSpec {
        ParamSpec(id: id, name: name, kind: .slider(range, step: step), defaultValue: value, decimals: decimals, unit: unit)
    }

    /// An on/off parameter. Read it with `ctx.params.bool(id)`.
    static func toggle(_ id: String, _ name: LocalizedText, default value: Bool) -> ParamSpec {
        ParamSpec(id: id, name: name, kind: .toggle, defaultValue: value ? 1 : 0, decimals: 0, unit: "")
    }

    /// A segmented choice. Read it with `ctx.params.int(id)` (index into `options`).
    static func choice(_ id: String, _ name: LocalizedText, _ options: [LocalizedText], default index: Int = 0) -> ParamSpec {
        ParamSpec(id: id, name: name, kind: .choice(options), defaultValue: Double(index), decimals: 0, unit: "")
    }

    func formatted(_ value: Double, _ language: AppLanguage) -> String {
        switch kind {
        case .slider:
            return String(format: "%.\(decimals)f", value) + unit
        case .toggle:
            return value > 0.5 ? L("on", "开")(language) : L("off", "关")(language)
        case .choice(let options):
            let index = min(max(Int(value.rounded()), 0), max(options.count - 1, 0))
            return options.isEmpty ? "" : options[index](language)
        }
    }
}

/// Current parameter values for a demo. Missing keys fall back to 0.
struct ParamValues: Equatable {
    var values: [String: Double]

    init(_ specs: [ParamSpec]) {
        var dict: [String: Double] = [:]
        for spec in specs { dict[spec.id] = spec.defaultValue }
        values = dict
    }

    subscript(key: String) -> Double {
        get { values[key] ?? 0 }
        set { values[key] = newValue }
    }

    func cg(_ key: String) -> CGFloat { CGFloat(self[key]) }
    func bool(_ key: String) -> Bool { self[key] > 0.5 }
    func int(_ key: String) -> Int { Int(self[key].rounded()) }
}

// MARK: - Demo context

/// Everything a demo needs to render.
struct DemoContext {
    var params: ParamValues
    /// `true` when rendered as a small, non-interactive thumbnail in a grid.
    /// Demos that normally wait for a tap/gesture must auto-play in this mode (see `.autoplay`).
    var isPreview: Bool
    var language: AppLanguage

    /// Convenience accessor: `ctx["response"]`.
    subscript(key: String) -> Double { params[key] }
    func cg(_ key: String) -> CGFloat { params.cg(key) }
    func bool(_ key: String) -> Bool { params.bool(key) }
    func int(_ key: String) -> Int { params.int(key) }
}

// MARK: - Effect

struct Effect: Identifiable {
    let id: String
    let category: EffectCategory
    let interaction: EffectInteraction
    let name: LocalizedText
    /// One-line description shown on cards.
    let summary: LocalizedText
    /// Professional, precise motion-design prompt. Written natively in each language.
    let prompt: LocalizedText
    /// How it's built, in plain words.
    let implementation: LocalizedText
    /// Key SwiftUI / Metal APIs used.
    let apis: [String]
    /// Extra search keywords (both languages).
    let tags: [String]
    let params: [ParamSpec]
    /// Minimum OS if above the app's deployment target (e.g. "iOS 26").
    let requirement: String?
    private let builder: (DemoContext) -> AnyView

    init<Demo: View>(
        id: String,
        category: EffectCategory,
        interaction: EffectInteraction,
        name: LocalizedText,
        summary: LocalizedText,
        prompt: LocalizedText,
        implementation: LocalizedText,
        apis: [String],
        tags: [String] = [],
        params: [ParamSpec] = [],
        requirement: String? = nil,
        @ViewBuilder demo: @escaping (DemoContext) -> Demo
    ) {
        self.id = id
        self.category = category
        self.interaction = interaction
        self.name = name
        self.summary = summary
        self.prompt = prompt
        self.implementation = implementation
        self.apis = apis
        self.tags = tags
        self.params = params
        self.requirement = requirement
        self.builder = { AnyView(demo($0)) }
    }

    func makeDemo(_ context: DemoContext) -> AnyView { builder(context) }

    var defaultParams: ParamValues { ParamValues(params) }

    /// The prompt plus a machine-precise line describing the current parameter values.
    func fullPrompt(_ language: AppLanguage, params values: ParamValues) -> String {
        let base = prompt(language)
        guard !params.isEmpty else { return base }
        let joined = params
            .map { "\($0.name(language)) \($0.formatted(values[$0.id], language))" }
            .joined(separator: language == .zh ? "，" : ", ")
        let label = language == .zh ? "当前参数：" : "Current parameters: "
        return base + "\n\n" + label + joined + (language == .zh ? "。" : ".")
    }

    /// Lower-cased haystack for search.
    var searchText: String {
        ([name.all, summary.all, category.title.all, interaction.title.all, implementation.all] + apis + tags)
            .joined(separator: " ")
            .lowercased()
    }
}
