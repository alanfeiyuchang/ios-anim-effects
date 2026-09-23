import Foundation

/// Families (variation groups) of `EffectCategory.icons`.
///
/// To add a variation: append the effect to `IconEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum IconsFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "icons.symbol-effects",
            category: .icons,
            name: L("SF Symbol Effects", "SF 符号特效"),
            summary: L("The system symbol effects: bounce, replace, ripple and draw-on.", "系统符号特效：弹跳、替换、涟漪与笔绘。"),
            symbol: "star.circle.fill"
        ),
        EffectFamily(
            id: "icons.ambient",
            category: .icons,
            name: L("Ambient Icons", "常驻动态图标"),
            summary: L("Icons that loop on their own: wiggle, breathe, signal sweeps and weather.", "自行循环的图标：摇摆、呼吸、信号扫动与天气。"),
            symbol: "cloud.sun.fill"
        ),
        EffectFamily(
            id: "icons.glyph-morph",
            category: .icons,
            name: L("Glyph Morph", "图标形变"),
            summary: L("One glyph reshaping into another: play ↔ pause, menu ↔ close.", "一个图标形变为另一个：播放 ↔ 暂停、菜单 ↔ 关闭。"),
            symbol: "play.circle.fill"
        ),
        EffectFamily(
            id: "icons.status",
            category: .icons,
            name: L("Status Icons", "状态图标"),
            summary: L("Icons that narrate a process: checks, downloads and unlocking.", "讲述过程的图标：对勾、下载与解锁。"),
            symbol: "checkmark.circle.fill"
        ),
        EffectFamily(
            id: "icons.action",
            category: .icons,
            name: L("Action Icons", "动作图标"),
            summary: L("Icons that act out their verb: like, ring, delete, send.", "演绎自身动作的图标：点赞、响铃、删除、发送。"),
            symbol: "heart.fill"
        ),
    ]

    static let membership: [String: String] = [
        // SF Symbol effects
        "icons.bounce": "icons.symbol-effects",
        "icons.replace": "icons.symbol-effects",
        "icons.ripple-grid": "icons.symbol-effects",
        "icons.draw-on": "icons.symbol-effects",
        // Ambient icons
        "icons.variable-color": "icons.ambient",
        "icons.wiggle-rotate-breathe": "icons.ambient",
        "icons.weather": "icons.ambient",
        // Glyph morph
        "icons.play-pause": "icons.glyph-morph",
        "icons.hamburger-morph": "icons.glyph-morph",
        // Status icons
        "icons.checkmark-draw": "icons.status",
        "icons.download": "icons.status",
        "icons.padlock": "icons.status",
        // Action icons
        "icons.heart-like": "icons.action",
        "icons.bell-ring": "icons.action",
        "icons.trash-delete": "icons.action",
        "icons.paper-plane": "icons.action",
    ]
}
