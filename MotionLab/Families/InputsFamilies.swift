import Foundation

/// Families (variation groups) of `EffectCategory.inputs`.
///
/// To add a variation: append the effect to `InputEffects.all`, then add one
/// `"<effect id>": "<family id>",` line to `membership` below. Each effect id may appear only once
/// (a duplicate dictionary key traps at launch). See docs/FAMILIES.md.
enum InputsFamilies {
    static let all: [EffectFamily] = [
        EffectFamily(
            id: "inputs.toggle",
            category: .inputs,
            name: L("Toggle", "开关"),
            summary: L("On/off switches with different ways of travelling between states.", "开与关之间以不同方式过渡的开关。"),
            symbol: "switch.2"
        ),
        EffectFamily(
            id: "inputs.slider",
            category: .inputs,
            name: L("Slider", "滑块"),
            summary: L("Dragging a value: elastic, velocity-aware, stretchy and range sliders.", "拖动取值：弹性、感知速度、橡皮筋与区间滑块。"),
            symbol: "slider.horizontal.3"
        ),
        EffectFamily(
            id: "inputs.dial",
            category: .inputs,
            name: L("Dials & Wheels", "旋钮与滚轮"),
            summary: L("Rotary knobs and wheel pickers that click into detents.", "带刻度吸附的旋钮与滚轮选择器。"),
            symbol: "dial.max"
        ),
        EffectFamily(
            id: "inputs.text-field",
            category: .inputs,
            name: L("Text Field", "输入框"),
            summary: L("Fields whose labels, underlines and meters animate as you type.", "标签、下划线与强度条随输入而动的输入框。"),
            symbol: "character.cursor.ibeam"
        ),
        EffectFamily(
            id: "inputs.code-entry",
            category: .inputs,
            name: L("Code & Passcode", "验证码与密码"),
            summary: L("Digit boxes and keypads that pop, shake on errors and celebrate success.", "数字格与键盘：输入弹出、错误抖动、成功庆祝。"),
            symbol: "circle.grid.3x3.fill"
        ),
        EffectFamily(
            id: "inputs.stepper",
            category: .inputs,
            name: L("Stepper", "步进器"),
            summary: L("Plus/minus steppers whose number rolls in the direction of the change.", "数字朝变化方向滚动的加减步进器。"),
            symbol: "plus.forwardslash.minus"
        ),
        EffectFamily(
            id: "inputs.rating",
            category: .inputs,
            name: L("Rating", "评分"),
            summary: L("Stars and scales that fill in a wave and pop as you rate.", "评分时以波浪填充并弹起的星级与刻度。"),
            symbol: "star.fill"
        ),
        EffectFamily(
            id: "inputs.selection",
            category: .inputs,
            name: L("Checkboxes & Chips", "勾选与标签"),
            summary: L("Checkboxes, tag chips and swatches that mark a choice with motion.", "以动效标记选择的勾选框、标签与色板。"),
            symbol: "checkmark.circle.fill"
        ),
    ]

    static let membership: [String: String] = [
        // Toggle
        "inputs.squash-toggle": "inputs.toggle",
        "inputs.day-night-toggle": "inputs.toggle",
        // Slider
        "inputs.velocity-slider": "inputs.slider",
        "inputs.elastic-slider": "inputs.slider",
        "inputs.range-slider": "inputs.slider",
        // Dials & wheels
        "inputs.dial-knob": "inputs.dial",
        "inputs.wheel-picker": "inputs.dial",
        // Text field
        "inputs.floating-label": "inputs.text-field",
        "inputs.password-strength": "inputs.text-field",
        "inputs.expanding-search": "inputs.text-field",
        // Code & passcode
        "inputs.otp-code": "inputs.code-entry",
        "inputs.passcode-pad": "inputs.code-entry",
        // Stepper
        "inputs.rolling-stepper": "inputs.stepper",
        // Rating
        "inputs.star-rating": "inputs.rating",
        // Checkboxes & chips
        "inputs.checkbox-draw": "inputs.selection",
        "inputs.chip-select": "inputs.selection",
        "inputs.swatch-picker": "inputs.selection",
    ]
}
