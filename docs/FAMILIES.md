# Effect families · 动效系列

A **family** groups variations of the same UI element or pattern — every slider, every spinner, every tab indicator —
so the app can show *many motion styles for one control* side by side. Navigation is
**Browse → Category (families) → Family (variations: Grid / Compare) → Detail (Variations strip)**.

Current catalog: **461 effects** in **85 families** across **15 categories**.
Counts below are the number of variations per family today; singletons (1) are families that are
explicitly waiting for more variations.

## How it is wired

- Model: `EffectFamily` (`MotionLab/Core/EffectFamily.swift`) — `id`, `category`, `name`, `summary`, `symbol`.
- Declarations: `MotionLab/Families/<Category>Families.swift`, one `enum XxxFamilies` per category with
  `static let all: [EffectFamily]` (display order) and `static let membership: [String: String]` (effect id → family id).
- Registry: `EffectFamilies` concatenates all files and exposes `family(id:)`, `family(for:)`, `effects(in:)`,
  `families(in:)`, `variations(of:)` and `search(_:category:interaction:)`.
- A family's variations are ordered by the category list (`XxxEffects.all`), not by the membership table.
- Effects with a missing/invalid membership line fall into an automatic "More · 更多" family of their category.
- Search: family names/summaries are part of every member's search haystack, and matching families are shown as
  chips above the results.
- Launch argument: `-ML_route family:<family id>` (e.g. `-ML_route family:inputs.slider`). Category pages remember
  Families vs. All Effects in `app.categoryMode`; family pages remember Grid vs. Compare in `app.familyMode`.

## How to add a variation · 如何添加变体

1. Write the effect as usual (see [`EFFECT_GUIDE.md`](EFFECT_GUIDE.md)) with a unique id such as `inputs.notch-slider`.
2. Append it to the category list (`XxxEffects.all`). Put it right after its siblings so the family reads well.
3. In `MotionLab/Families/<Category>Families.swift`, add **one line** to `membership`:
   ```swift
   "inputs.notch-slider": "inputs.slider",
   ```
   Each effect id must appear only once (a duplicate key in a Swift dictionary literal traps at launch).
4. Only if no family fits, add an `EffectFamily(...)` to that file's `all` (id `"<category rawValue>.<slug>"` —
   `shaders.` for the Shaders category — bilingual name + one-line summary + an SF Symbol) and update this document.
5. Make the variation differ in *motion style* (curve, physics, choreography, material, feedback), not only in color:
   the family page's Compare mode plays all variations side by side.

## Families per category · 各分类的系列

### Signature Interactions · 质感交互精选

File: `MotionLab/Families/ShowcaseFamilies.swift` · list: `ShowcaseSportEffects / ShowcaseTravelEffects / ShowcaseLifeEffects` · 6 families · 32 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `showcase.chart-widgets` | Chart Widgets · 图表小组件 | 5 | `showcase.speed-line`, `showcase.fresh-snow`, `showcase.heart-zone`, `showcase.finance-card`, `showcase.sleep-timeline` |
| `showcase.live-stats` | Live Stat Cards · 实时数据卡片 | 4 | `showcase.lift-status`, `showcase.run-summary`, `showcase.weather-widget`, `showcase.flip-clock` |
| `showcase.media-cards` | Photo & Media Cards · 照片与媒体卡片 | 7 | `showcase.board-card`, `showcase.photo-play`, `showcase.spots-grid`, `showcase.fog-wipe`, `showcase.destination-carousel`, `showcase.polaroid-fan`, `showcase.now-playing` |
| `showcase.controls` | Pickers & Sliders · 选择与滑动控件 | 5 | `showcase.slide-to-start`, `showcase.altitude-ruler`, `showcase.gear-checklist`, `showcase.trip-chips`, `showcase.date-range` |
| `showcase.routes` | Routes & Timelines · 路线与时间轴 | 4 | `showcase.best-line`, `showcase.flight-path`, `showcase.pin-route`, `showcase.itinerary` |
| `showcase.moments` | Moments & CTAs · 行动与高光时刻 | 4 | `showcase.go-countdown`, `showcase.get-started`, `showcase.boarding-pass`, `showcase.save-burst` |

### Buttons · 按钮

File: `MotionLab/Families/ButtonsFamilies.swift` · list: `ButtonEffects` · 7 families · 41 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `buttons.press` | Press Feedback · 按压反馈 | 3 | `buttons.press-scale`, `buttons.ink-ripple`, `buttons.depth-press` |
| `buttons.pointer` | Finger-Aware Buttons · 指尖感应按钮 | 2 | `buttons.magnetic`, `buttons.spotlight` |
| `buttons.glow` | Glow & Shimmer · 辉光与流光 | 3 | `buttons.shimmer`, `buttons.glow-border`, `buttons.neon-breath` |
| `buttons.like` | Like Button · 点赞按钮 | 1 | `buttons.like-burst` |
| `buttons.state-morph` | State-Change Buttons · 状态切换按钮 | 4 | `buttons.add-to-cart`, `buttons.follow-morph`, `buttons.label-roll`, `buttons.liquid-glass` |
| `buttons.hold` | Hold to Confirm · 长按确认 | 1 | `buttons.hold-to-confirm` |
| `buttons.expand` | Expanding Actions · 展开式操作 | 2 | `buttons.expand-actions`, `buttons.gooey-split` |

### Inputs & Controls · 输入与控件

File: `MotionLab/Families/InputsFamilies.swift` · list: `InputEffects` · 8 families · 45 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `inputs.toggle` | Toggle · 开关 | 2 | `inputs.squash-toggle`, `inputs.day-night-toggle` |
| `inputs.slider` | Slider · 滑块 | 3 | `inputs.velocity-slider`, `inputs.elastic-slider`, `inputs.range-slider` |
| `inputs.dial` | Dials & Wheels · 旋钮与滚轮 | 2 | `inputs.dial-knob`, `inputs.wheel-picker` |
| `inputs.text-field` | Text Field · 输入框 | 3 | `inputs.floating-label`, `inputs.password-strength`, `inputs.expanding-search` |
| `inputs.code-entry` | Code & Passcode · 验证码与密码 | 2 | `inputs.otp-code`, `inputs.passcode-pad` |
| `inputs.stepper` | Stepper · 步进器 | 1 | `inputs.rolling-stepper` |
| `inputs.rating` | Rating · 评分 | 1 | `inputs.star-rating` |
| `inputs.selection` | Checkboxes & Chips · 勾选与标签 | 3 | `inputs.checkbox-draw`, `inputs.chip-select`, `inputs.swatch-picker` |

### Loading & Progress · 加载与进度

File: `MotionLab/Families/LoadingFamilies.swift` · list: `LoadingEffects` · 6 families · 36 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `loading.spinner` | Spinner · 旋转加载 | 3 | `loading.arc-spinner`, `loading.orbit-dots`, `loading.activity-petals` |
| `loading.pulse` | Dots & Pulses · 跳动与脉冲 | 4 | `loading.dot-bounce`, `loading.audio-wave`, `loading.pulse-rings`, `loading.square-grid` |
| `loading.progress-bar` | Progress Bar · 进度条 | 3 | `loading.glow-bar`, `loading.story-bars`, `loading.indeterminate-bar` |
| `loading.progress-ring` | Progress Ring · 进度环 | 2 | `loading.progress-ring`, `loading.liquid-fill` |
| `loading.button` | Loading Button · 加载按钮 | 2 | `loading.load-button`, `loading.download-button` |
| `loading.placeholder` | Placeholders · 占位加载 | 3 | `loading.skeleton-shimmer`, `loading.blur-up`, `loading.ai-generating` |

### Feedback & Alerts · 反馈与提示

File: `MotionLab/Families/FeedbackFamilies.swift` · list: `FeedbackEffects` · 6 families · 32 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `feedback.toast` | Toasts & Banners · 吐司与横幅 | 5 | `feedback.toast`, `feedback.island-pill`, `feedback.connection-banner`, `feedback.undo-snackbar`, `feedback.stacked-banners` |
| `feedback.success` | Success · 成功反馈 | 3 | `feedback.success-check`, `feedback.confetti`, `feedback.copy-confirm` |
| `feedback.error` | Errors & Validation · 错误与校验 | 2 | `feedback.error-shake`, `feedback.inline-validation` |
| `feedback.badge` | Badges & Reactions · 角标与回应 | 2 | `feedback.badge-bounce`, `feedback.reaction-picker` |
| `feedback.overlay` | Alerts & Overlays · 弹窗与引导 | 2 | `feedback.alert-pop`, `feedback.coach-spotlight` |
| `feedback.refresh` | Pull to Refresh · 下拉刷新 | 1 | `feedback.pull-refresh` |

### Transitions & Morphing · 转场与形变

File: `MotionLab/Families/MorphFamilies.swift` · list: `MorphEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `morph.container` | Button to Surface · 按钮变容器 | 4 | `morph.button-to-card`, `morph.fab-menu`, `morph.zoom-sheet`, `morph.search-expand` |
| `morph.hero` | Hero & Zoom Transitions · 英雄与缩放转场 | 5 | `morph.hero-card`, `morph.native-zoom`, `morph.mini-player`, `morph.folder-open`, `morph.gallery-zoom` |
| `morph.shape` | Shape Morph · 形状形变 | 2 | `morph.shape-morph`, `morph.liquid-glass` |
| `morph.reveal` | Reveal & Replace · 揭示与替换 | 2 | `morph.circular-reveal`, `morph.blur-replace` |
| `morph.layout` | Layout Transitions · 布局转场 | 3 | `morph.staggered-transition`, `morph.list-grid`, `morph.cube-transition` |

### Navigation & Menus · 导航与菜单

File: `MotionLab/Families/NavigationFamilies.swift` · list: `NavigationEffects` · 6 families · 32 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `navigation.tab-indicator` | Tab Indicator · 标签指示器 | 3 | `navigation.tab-indicator`, `navigation.segmented-thumb`, `navigation.elastic-underline` |
| `navigation.tab-bar` | Tab Bars & Docks · 标签栏与程序坞 | 2 | `navigation.collapsing-tab-bar`, `navigation.dock-magnify` |
| `navigation.page-indicator` | Page & Step Indicators · 页码与步骤指示 | 2 | `navigation.page-dots`, `navigation.step-progress` |
| `navigation.drawer` | Drawers & Sidebars · 抽屉与侧栏 | 2 | `navigation.side-drawer-3d`, `navigation.sidebar-rail` |
| `navigation.sheet` | Pages & Sheets · 页面与面板 | 2 | `navigation.push-parallax`, `navigation.bottom-sheet` |
| `navigation.menu` | Menus · 菜单 | 3 | `navigation.radial-menu`, `navigation.context-popover`, `navigation.context-menu-lift` |

### Cards · 卡片

File: `MotionLab/Families/CardsFamilies.swift` · list: `CardEffects` · 5 families · 27 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `cards.tilt` | Tilt & Foil · 倾斜与光泽 | 3 | `cards.tilt-3d`, `cards.holographic`, `cards.parallax-layers` |
| `cards.flip` | Flip & Reveal · 翻转与揭示 | 2 | `cards.flip`, `cards.scratch-reveal` |
| `cards.swipe` | Card Swipe · 卡片滑动 | 2 | `cards.swipe-stack`, `cards.shuffle` |
| `cards.stack` | Stacks & Decks · 堆叠与牌组 | 4 | `cards.wallet-stack`, `cards.fan-deck`, `cards.notification-stack`, `cards.stacking-scroll` |
| `cards.expand` | Expand & Peek · 展开与预览 | 2 | `cards.peek`, `cards.accordion` |

### Scroll & Lists · 滚动与列表

File: `MotionLab/Families/ScrollFamilies.swift` · list: `ScrollEffects` · 5 families · 27 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `scroll.carousel` | Carousel · 轮播 | 3 | `scroll.cover-flow`, `scroll.paging-carousel`, `scroll.infinite-carousel` |
| `scroll.header` | Scroll Headers · 滚动头部 | 3 | `scroll.stretchy-header`, `scroll.collapsing-header`, `scroll.sticky-sections` |
| `scroll.list-motion` | List Motion · 列表动效 | 4 | `scroll.transition-list`, `scroll.parallax-cards`, `scroll.staggered-entrance`, `scroll.insert-remove` |
| `scroll.wheel` | Wheels & Dials · 滚轮与转盘 | 2 | `scroll.wheel-list`, `scroll.arc-dial` |
| `scroll.indicator` | Progress & Index · 进度与索引 | 2 | `scroll.progress-indicator`, `scroll.index-scrubber` |

### Text & Numbers · 文字与数字

File: `MotionLab/Families/TextFamilies.swift` · list: `TextEffects` · 5 families · 30 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `text.number` | Number Counter · 数字滚动 | 3 | `text.numeric-counter`, `text.odometer`, `text.split-flap` |
| `text.reveal` | Text Reveal · 文字揭示 | 5 | `text.blur-reveal`, `text.typewriter`, `text.scramble`, `text.flip-in-3d`, `text.masked-lines` |
| `text.kinetic` | Kinetic Type · 动态字形 | 3 | `text.wave`, `text.circular-badge`, `text.variable-weight` |
| `text.emphasis` | Light & Emphasis · 光效与强调 | 3 | `text.shimmer`, `text.highlighter`, `text.synced-lyrics` |
| `text.ticker` | Rotating & Ticker · 轮播与跑马灯 | 2 | `text.rotating-words`, `text.marquee` |

### Icons & Symbols · 图标与符号

File: `MotionLab/Families/IconsFamilies.swift` · list: `IconEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `icons.symbol-effects` | SF Symbol Effects · SF 符号特效 | 4 | `icons.bounce`, `icons.replace`, `icons.ripple-grid`, `icons.draw-on` |
| `icons.ambient` | Ambient Icons · 常驻动态图标 | 3 | `icons.variable-color`, `icons.wiggle-rotate-breathe`, `icons.weather` |
| `icons.glyph-morph` | Glyph Morph · 图标形变 | 2 | `icons.play-pause`, `icons.hamburger-morph` |
| `icons.status` | Status Icons · 状态图标 | 3 | `icons.checkmark-draw`, `icons.download`, `icons.padlock` |
| `icons.action` | Action Icons · 动作图标 | 4 | `icons.heart-like`, `icons.bell-ring`, `icons.trash-delete`, `icons.paper-plane` |

### Gestures & Physics · 手势与物理

File: `MotionLab/Families/GesturesFamilies.swift` · list: `GestureEffects` · 6 families · 32 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `gestures.drag-spring` | Drag & Spring · 拖拽与弹簧 | 4 | `gestures.rubber-band`, `gestures.jelly-stretch`, `gestures.spring-chain`, `gestures.gooey-blobs` |
| `gestures.throw` | Throw & Snap · 抛掷与吸附 | 3 | `gestures.fling-inertia`, `gestures.pip-snap`, `gestures.drag-dismiss` |
| `gestures.physics` | Physics Toys · 物理模拟 | 3 | `gestures.charge-burst`, `gestures.verlet-rope`, `gestures.newtons-cradle` |
| `gestures.list` | List Gestures · 列表手势 | 2 | `gestures.swipe-actions`, `gestures.drag-reorder` |
| `gestures.pinch` | Pinch, Zoom & Loupe · 捏合缩放与放大镜 | 3 | `gestures.pinch-rotate`, `gestures.magnifier-loupe`, `gestures.photo-viewer` |
| `gestures.slide-confirm` | Slide to Confirm · 滑动确认 | 1 | `gestures.slide-to-confirm` |

### Data & Charts · 数据与图表

File: `MotionLab/Families/ChartsFamilies.swift` · list: `ChartEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `charts.bar` | Bar Charts · 柱状图 | 3 | `charts.bar-grow`, `charts.bar-race`, `charts.stacked-bars` |
| `charts.line` | Line Charts · 折线图 | 5 | `charts.line-draw`, `charts.scrub-tooltip`, `charts.sparkline-stream`, `charts.range-morph`, `charts.candlestick-live` |
| `charts.ring` | Rings & Gauges · 圆环与仪表 | 3 | `charts.donut-explode`, `charts.gauge-needle`, `charts.activity-rings` |
| `charts.morph` | Chart Morph · 图表形变 | 2 | `charts.radar-morph`, `charts.donut-to-bars` |
| `charts.kpi` | KPIs & Heatmaps · 指标与热力图 | 2 | `charts.heatmap-cascade`, `charts.kpi-count-up` |

### Backgrounds & Ambience · 背景与氛围

File: `MotionLab/Families/BackgroundsFamilies.swift` · list: `BackgroundEffects` · 5 families · 27 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `backgrounds.gradient` | Mesh & Ambient Gradients · 网格与氛围渐变 | 4 | `backgrounds.mesh-gradient`, `backgrounds.intelligence-glow`, `backgrounds.aurora`, `backgrounds.grain-gradient` |
| `backgrounds.particles` | Particle Fields · 粒子场 | 5 | `backgrounds.particle-repulsion`, `backgrounds.fireflies`, `backgrounds.bokeh`, `backgrounds.constellation`, `backgrounds.flow-field` |
| `backgrounds.liquid` | Liquid & Blobs · 液态与融球 | 3 | `backgrounds.metaballs`, `backgrounds.glow-orb`, `backgrounds.lava-lamp` |
| `backgrounds.weather` | Weather · 天气氛围 | 2 | `backgrounds.rain`, `backgrounds.snowfall` |
| `backgrounds.waves-grids` | Waves, Grids & Warp · 波浪、网格与跃迁 | 4 | `backgrounds.starfield-warp`, `backgrounds.halftone-flow`, `backgrounds.sine-waves`, `backgrounds.synthwave-grid` |

### Shaders & Materials · 着色器与材质

File: `MotionLab/Families/ShadersFamilies.swift` · list: `ShaderEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `shaders.distortion` | Ripple & Distortion · 涟漪与扭曲 | 4 | `shader.ripple`, `shader.wave`, `shader.swirl`, `shader.chromatic-drag` |
| `shaders.transition` | Shader Transitions · 着色器转场 | 3 | `shader.pixelate`, `shader.dissolve`, `shader.edge-scan` |
| `shaders.glass` | Glass & Lens · 玻璃与透镜 | 4 | `shader.magnifier`, `shader.glassmorphism`, `shader.liquid-glass-lens`, `shader.progressive-blur` |
| `shaders.retro` | Retro & Print · 复古与印刷 | 3 | `shader.glitch`, `shader.crt`, `shader.halftone` |
| `shaders.generative` | Generative Light · 生成光效 | 3 | `shader.plasma`, `shader.kaleidoscope`, `shader.caustics` |
