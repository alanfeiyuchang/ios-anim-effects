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
- `-ML_route families` opens the All Families page; `-ML_freshState YES` starts with empty recents (used by screenshots).
- The tables below are generated: run `python3 scripts/gen_families_doc.py` after changing a Families file.

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
| `showcase.live-stats` | Stat Cards · 数据卡片 | 5 | `showcase.lift-status`, `showcase.run-summary`, `showcase.weather-widget`, `showcase.flip-clock`, `showcase.ev-charge` |
| `showcase.media-cards` | Photo & Media Cards · 照片与媒体卡片 | 7 | `showcase.board-card`, `showcase.photo-play`, `showcase.spots-grid`, `showcase.fog-wipe`, `showcase.destination-carousel`, `showcase.polaroid-fan`, `showcase.now-playing` |
| `showcase.controls` | Pickers & Sliders · 选择与滑动控件 | 5 | `showcase.slide-to-start`, `showcase.altitude-ruler`, `showcase.gear-checklist`, `showcase.trip-chips`, `showcase.date-range` |
| `showcase.routes` | Routes & Timelines · 路线与时间轴 | 5 | `showcase.best-line`, `showcase.flight-path`, `showcase.pin-route`, `showcase.itinerary`, `showcase.transit-line` |
| `showcase.moments` | Moments & CTAs · 行动与高光时刻 | 5 | `showcase.go-countdown`, `showcase.get-started`, `showcase.boarding-pass`, `showcase.save-burst`, `showcase.summit-badge` |

### Buttons · 按钮

File: `MotionLab/Families/ButtonsFamilies.swift` · list: `ButtonEffects` · 7 families · 41 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `buttons.press` | Press Feedback · 按压反馈 | 8 | `buttons.press-scale`, `buttons.depth-press`, `buttons.ink-ripple`, `buttons.jelly-press`, `buttons.soft-press`, `buttons.echo-press`, `buttons.stack-press`, `buttons.label-roll` |
| `buttons.pointer` | Finger-Aware Buttons · 指尖感应按钮 | 5 | `buttons.magnetic`, `buttons.spotlight`, `buttons.repel-letters`, `buttons.parallax-tilt`, `buttons.elastic-blob` |
| `buttons.glow` | Glow & Shimmer · 辉光与流光 | 5 | `buttons.shimmer`, `buttons.glow-border`, `buttons.neon-breath`, `buttons.ember-glow`, `buttons.plasma-glass` |
| `buttons.like` | Like Button · 点赞按钮 | 7 | `buttons.like-burst`, `buttons.like-thumb`, `buttons.like-liquid`, `buttons.like-float`, `buttons.like-draw`, `buttons.like-flip`, `buttons.like-double-tap` |
| `buttons.state-morph` | State-Change Buttons · 状态切换按钮 | 6 | `buttons.add-to-cart`, `buttons.follow-morph`, `buttons.liquid-glass`, `buttons.bookmark-ribbon`, `buttons.copy-flip`, `buttons.approve-stamp` |
| `buttons.hold` | Hold to Confirm · 长按确认 | 5 | `buttons.hold-to-confirm`, `buttons.hold-ring`, `buttons.hold-charge`, `buttons.hold-trace`, `buttons.hold-segments` |
| `buttons.expand` | Expanding Actions · 展开式操作 | 5 | `buttons.expand-actions`, `buttons.gooey-split`, `buttons.pill-toolbar`, `buttons.unfold-menu`, `buttons.orbit-actions` |

### Inputs & Controls · 输入与控件

File: `MotionLab/Families/InputsFamilies.swift` · list: `InputEffects` · 8 families · 45 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `inputs.toggle` | Toggle · 开关 | 7 | `inputs.squash-toggle`, `inputs.day-night-toggle`, `inputs.inchworm-toggle`, `inputs.rolling-toggle`, `inputs.rocker-switch`, `inputs.pull-cord-toggle`, `inputs.flood-toggle` |
| `inputs.slider` | Slider · 滑块 | 8 | `inputs.velocity-slider`, `inputs.elastic-slider`, `inputs.range-slider`, `inputs.liquid-slider`, `inputs.magnetic-tick-slider`, `inputs.drum-slider`, `inputs.segmented-slider`, `inputs.grow-scrubber` |
| `inputs.dial` | Dials & Wheels · 旋钮与滚轮 | 5 | `inputs.dial-knob`, `inputs.wheel-picker`, `inputs.jog-wheel`, `inputs.thermostat-dial`, `inputs.wind-up-timer` |
| `inputs.text-field` | Text Field · 输入框 | 5 | `inputs.floating-label`, `inputs.password-strength`, `inputs.expanding-search`, `inputs.char-drop-field`, `inputs.token-field` |
| `inputs.code-entry` | Code & Passcode · 验证码与密码 | 5 | `inputs.otp-code`, `inputs.passcode-pad`, `inputs.merge-pin`, `inputs.slot-reel-code`, `inputs.secure-flip-code` |
| `inputs.stepper` | Stepper · 步进器 | 5 | `inputs.rolling-stepper`, `inputs.expanding-stepper`, `inputs.accelerating-stepper`, `inputs.drag-stepper`, `inputs.delta-stepper` |
| `inputs.rating` | Rating · 评分 | 5 | `inputs.star-rating`, `inputs.emoji-face-rating`, `inputs.fill-rating`, `inputs.thumbs-rating`, `inputs.nps-scale` |
| `inputs.selection` | Checkboxes & Chips · 勾选与标签 | 5 | `inputs.checkbox-draw`, `inputs.chip-select`, `inputs.swatch-picker`, `inputs.radio-travel`, `inputs.todo-check` |

### Loading & Progress · 加载与进度

File: `MotionLab/Families/LoadingFamilies.swift` · list: `LoadingEffects` · 6 families · 36 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `loading.spinner` | Spinner · 旋转加载 | 7 | `loading.arc-spinner`, `loading.orbit-dots`, `loading.activity-petals`, `loading.gooey-orbit`, `loading.gyroscope`, `loading.flip-tile`, `loading.infinity-comet` |
| `loading.pulse` | Dots & Pulses · 跳动与脉冲 | 5 | `loading.dot-bounce`, `loading.audio-wave`, `loading.pulse-rings`, `loading.square-grid`, `loading.heartbeat` |
| `loading.progress-bar` | Progress Bar · 进度条 | 7 | `loading.glow-bar`, `loading.story-bars`, `loading.indeterminate-bar`, `loading.segment-bar`, `loading.liquid-bar`, `loading.tooltip-bar`, `loading.candy-stripes` |
| `loading.progress-ring` | Progress Ring · 进度环 | 7 | `loading.progress-ring`, `loading.liquid-fill`, `loading.tick-ring`, `loading.install-pie`, `loading.elastic-ring`, `loading.ring-to-check`, `loading.dash-flow-ring` |
| `loading.button` | Loading Button · 加载按钮 | 5 | `loading.load-button`, `loading.download-button`, `loading.fill-button`, `loading.dots-button`, `loading.trace-button` |
| `loading.placeholder` | Placeholders · 占位加载 | 5 | `loading.skeleton-shimmer`, `loading.blur-up`, `loading.ai-generating`, `loading.breathing-skeleton`, `loading.mosaic-resolve` |

### Feedback & Alerts · 反馈与提示

File: `MotionLab/Families/FeedbackFamilies.swift` · list: `FeedbackEffects` · 6 families · 32 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `feedback.toast` | Toasts & Banners · 吐司与横幅 | 7 | `feedback.toast`, `feedback.island-pill`, `feedback.connection-banner`, `feedback.undo-snackbar`, `feedback.stacked-banners`, `feedback.hinge-toast`, `feedback.morph-toast` |
| `feedback.success` | Success · 成功反馈 | 5 | `feedback.success-check`, `feedback.confetti`, `feedback.copy-confirm`, `feedback.spark-burst`, `feedback.level-up` |
| `feedback.error` | Errors & Validation · 错误与校验 | 5 | `feedback.error-shake`, `feedback.inline-validation`, `feedback.glitch-error`, `feedback.limit-bounce`, `feedback.faceid-fail` |
| `feedback.badge` | Badges & Reactions · 角标与回应 | 5 | `feedback.badge-bounce`, `feedback.reaction-picker`, `feedback.streak-flame`, `feedback.presence-ping`, `feedback.floating-hearts` |
| `feedback.overlay` | Alerts & Overlays · 弹窗与引导 | 5 | `feedback.alert-pop`, `feedback.coach-spotlight`, `feedback.receding-sheet`, `feedback.tip-popover`, `feedback.drop-alert` |
| `feedback.refresh` | Pull to Refresh · 下拉刷新 | 5 | `feedback.pull-refresh`, `feedback.goo-refresh`, `feedback.sun-refresh`, `feedback.letter-refresh`, `feedback.dots-refresh` |

### Transitions & Morphing · 转场与形变

File: `MotionLab/Families/MorphFamilies.swift` · list: `MorphEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `morph.container` | Button to Surface · 按钮变容器 | 5 | `morph.button-to-card`, `morph.fab-menu`, `morph.zoom-sheet`, `morph.search-expand`, `morph.island-expand` |
| `morph.hero` | Hero & Zoom Transitions · 英雄与缩放转场 | 5 | `morph.hero-card`, `morph.native-zoom`, `morph.mini-player`, `morph.folder-open`, `morph.gallery-zoom` |
| `morph.shape` | Shape Morph · 形状形变 | 5 | `morph.shape-morph`, `morph.liquid-glass`, `morph.polygon-sides`, `morph.corner-cascade`, `morph.line-to-ring` |
| `morph.reveal` | Reveal & Replace · 揭示与替换 | 5 | `morph.circular-reveal`, `morph.blur-replace`, `morph.blinds-reveal`, `morph.feather-wipe`, `morph.tile-mosaic` |
| `morph.layout` | Layout Transitions · 布局转场 | 5 | `morph.staggered-transition`, `morph.list-grid`, `morph.cube-transition`, `morph.grid-to-ring`, `morph.sort-hop` |

### Navigation & Menus · 导航与菜单

File: `MotionLab/Families/NavigationFamilies.swift` · list: `NavigationEffects` · 6 families · 32 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `navigation.tab-indicator` | Tab Indicator · 标签指示器 | 7 | `navigation.tab-indicator`, `navigation.segmented-thumb`, `navigation.elastic-underline`, `navigation.gooey-tab`, `navigation.spotlight-tab`, `navigation.hop-dot-tab`, `navigation.trace-tab` |
| `navigation.tab-bar` | Tab Bars & Docks · 标签栏与程序坞 | 5 | `navigation.collapsing-tab-bar`, `navigation.dock-magnify`, `navigation.notch-tab-bar`, `navigation.search-tab-morph`, `navigation.ripple-tab-bar` |
| `navigation.page-indicator` | Page & Step Indicators · 页码与步骤指示 | 5 | `navigation.page-dots`, `navigation.step-progress`, `navigation.number-pager`, `navigation.timer-dots`, `navigation.scrolling-dots` |
| `navigation.drawer` | Drawers & Sidebars · 抽屉与侧栏 | 5 | `navigation.side-drawer-3d`, `navigation.sidebar-rail`, `navigation.parallax-drawer`, `navigation.elastic-drawer`, `navigation.popout-drawer` |
| `navigation.sheet` | Pages & Sheets · 页面与面板 | 5 | `navigation.push-parallax`, `navigation.bottom-sheet`, `navigation.stacked-sheets`, `navigation.fade-through`, `navigation.floating-sheet` |
| `navigation.menu` | Menus · 菜单 | 5 | `navigation.radial-menu`, `navigation.context-popover`, `navigation.context-menu-lift`, `navigation.fold-menu`, `navigation.overlay-menu` |

### Cards · 卡片

File: `MotionLab/Families/CardsFamilies.swift` · list: `CardEffects` · 5 families · 27 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `cards.tilt` | Tilt & Foil · 倾斜与光泽 | 5 | `cards.tilt-3d`, `cards.holographic`, `cards.parallax-layers`, `cards.press-tilt`, `cards.rim-light` |
| `cards.flip` | Flip & Reveal · 翻转与揭示 | 5 | `cards.flip`, `cards.scratch-reveal`, `cards.hinge-reveal`, `cards.tile-flip`, `cards.scrub-flip` |
| `cards.swipe` | Card Swipe · 卡片滑动 | 7 | `cards.swipe-stack`, `cards.shuffle`, `cards.jelly-swipe`, `cards.turn-swipe`, `cards.toss-swipe`, `cards.tear-off`, `cards.rewind-swipe` |
| `cards.stack` | Stacks & Decks · 堆叠与牌组 | 5 | `cards.wallet-stack`, `cards.fan-deck`, `cards.notification-stack`, `cards.stacking-scroll`, `cards.cascade-spread` |
| `cards.expand` | Expand & Peek · 展开与预览 | 5 | `cards.peek`, `cards.accordion`, `cards.bento-expand`, `cards.detent-expand`, `cards.origami-unfold` |

### Scroll & Lists · 滚动与列表

File: `MotionLab/Families/ScrollFamilies.swift` · list: `ScrollEffects` · 5 families · 27 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `scroll.carousel` | Carousel · 轮播 | 7 | `scroll.cover-flow`, `scroll.paging-carousel`, `scroll.infinite-carousel`, `scroll.stack-carousel`, `scroll.cube-carousel`, `scroll.parallax-pager`, `scroll.fan-carousel` |
| `scroll.header` | Scroll Headers · 滚动头部 | 5 | `scroll.stretchy-header`, `scroll.collapsing-header`, `scroll.sticky-sections`, `scroll.hiding-header`, `scroll.pill-header` |
| `scroll.list-motion` | List Motion · 列表动效 | 5 | `scroll.transition-list`, `scroll.parallax-cards`, `scroll.staggered-entrance`, `scroll.insert-remove`, `scroll.elastic-list` |
| `scroll.wheel` | Wheels & Dials · 滚轮与转盘 | 5 | `scroll.wheel-list`, `scroll.arc-dial`, `scroll.ruler-picker`, `scroll.rotary-wheel`, `scroll.slot-reels` |
| `scroll.indicator` | Progress & Index · 进度与索引 | 5 | `scroll.progress-indicator`, `scroll.index-scrubber`, `scroll.minimap`, `scroll.chapter-rail`, `scroll.liquid-scrollbar` |

### Text & Numbers · 文字与数字

File: `MotionLab/Families/TextFamilies.swift` · list: `TextEffects` · 5 families · 30 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `text.number` | Number Counter · 数字滚动 | 7 | `text.numeric-counter`, `text.odometer`, `text.split-flap`, `text.slot-reel`, `text.gravity-digits`, `text.count-up`, `text.seven-segment` |
| `text.reveal` | Text Reveal · 文字揭示 | 8 | `text.blur-reveal`, `text.typewriter`, `text.scramble`, `text.flip-in-3d`, `text.masked-lines`, `text.elastic-letters`, `text.light-sweep`, `text.tracking-in` |
| `text.kinetic` | Kinetic Type · 动态字形 | 5 | `text.wave`, `text.circular-badge`, `text.variable-weight`, `text.spring-chain`, `text.squash-hop` |
| `text.emphasis` | Light & Emphasis · 光效与强调 | 5 | `text.shimmer`, `text.highlighter`, `text.synced-lyrics`, `text.scribble-circle`, `text.neon-sign` |
| `text.ticker` | Rotating & Ticker · 轮播与跑马灯 | 5 | `text.rotating-words`, `text.marquee`, `text.news-ticker`, `text.word-drum`, `text.type-cycle` |

### Icons & Symbols · 图标与符号

File: `MotionLab/Families/IconsFamilies.swift` · list: `IconEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `icons.symbol-effects` | SF Symbol Effects · SF 符号特效 | 5 | `icons.bounce`, `icons.replace`, `icons.ripple-grid`, `icons.draw-on`, `icons.appear-disappear` |
| `icons.ambient` | Ambient Icons · 常驻动态图标 | 5 | `icons.variable-color`, `icons.wiggle-rotate-breathe`, `icons.weather`, `icons.radar-ping`, `icons.ai-sparkle` |
| `icons.glyph-morph` | Glyph Morph · 图标形变 | 5 | `icons.play-pause`, `icons.hamburger-morph`, `icons.plus-close`, `icons.chevron-flip`, `icons.search-close` |
| `icons.status` | Status Icons · 状态图标 | 5 | `icons.checkmark-draw`, `icons.download`, `icons.padlock`, `icons.wifi-connect`, `icons.battery-charge` |
| `icons.action` | Action Icons · 动作图标 | 5 | `icons.heart-like`, `icons.bell-ring`, `icons.trash-delete`, `icons.paper-plane`, `icons.bookmark-save` |

### Gestures & Physics · 手势与物理

File: `MotionLab/Families/GesturesFamilies.swift` · list: `GestureEffects` · 6 families · 32 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `gestures.drag-spring` | Drag & Spring · 拖拽与弹簧 | 7 | `gestures.rubber-band`, `gestures.jelly-stretch`, `gestures.spring-chain`, `gestures.gooey-blobs`, `gestures.magnetic-snap`, `gestures.elastic-tether`, `gestures.pendulum-swing` |
| `gestures.throw` | Throw & Snap · 抛掷与吸附 | 5 | `gestures.fling-inertia`, `gestures.pip-snap`, `gestures.drag-dismiss`, `gestures.gravity-toss`, `gestures.detent-sheet` |
| `gestures.physics` | Physics Toys · 物理模拟 | 5 | `gestures.charge-burst`, `gestures.verlet-rope`, `gestures.newtons-cradle`, `gestures.coil-spring`, `gestures.orbit-slingshot` |
| `gestures.list` | List Gestures · 列表手势 | 5 | `gestures.swipe-actions`, `gestures.drag-reorder`, `gestures.swipe-complete`, `gestures.staged-swipe`, `gestures.drag-select` |
| `gestures.pinch` | Pinch, Zoom & Loupe · 捏合缩放与放大镜 | 5 | `gestures.pinch-rotate`, `gestures.magnifier-loupe`, `gestures.photo-viewer`, `gestures.pinch-grid`, `gestures.pinch-open` |
| `gestures.slide-confirm` | Slide to Confirm · 滑动确认 | 5 | `gestures.slide-to-confirm`, `gestures.stretch-slide`, `gestures.notch-slide`, `gestures.arc-slide`, `gestures.pull-cord` |

### Data & Charts · 数据与图表

File: `MotionLab/Families/ChartsFamilies.swift` · list: `ChartEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `charts.bar` | Bar Charts · 柱状图 | 5 | `charts.bar-grow`, `charts.bar-race`, `charts.stacked-bars`, `charts.liquid-bars`, `charts.brick-bars` |
| `charts.line` | Line Charts · 折线图 | 5 | `charts.line-draw`, `charts.scrub-tooltip`, `charts.sparkline-stream`, `charts.range-morph`, `charts.candlestick-live` |
| `charts.ring` | Rings & Gauges · 圆环与仪表 | 5 | `charts.donut-explode`, `charts.gauge-needle`, `charts.activity-rings`, `charts.segmented-gauge`, `charts.rose-bloom` |
| `charts.morph` | Chart Morph · 图表形变 | 5 | `charts.radar-morph`, `charts.donut-to-bars`, `charts.bars-to-line`, `charts.scatter-histogram`, `charts.grouped-stacked` |
| `charts.kpi` | Stat Tiles & Unit Grids · 指标卡与格阵图 | 5 | `charts.heatmap-cascade`, `charts.kpi-count-up`, `charts.odometer-kpi`, `charts.bullet-kpi`, `charts.waffle-kpi` |

### Backgrounds & Ambience · 背景与氛围

File: `MotionLab/Families/BackgroundsFamilies.swift` · list: `BackgroundEffects` · 5 families · 27 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `backgrounds.gradient` | Mesh & Ambient Gradients · 网格与氛围渐变 | 7 | `backgrounds.mesh-gradient`, `backgrounds.intelligence-glow`, `backgrounds.aurora`, `backgrounds.grain-gradient`, `backgrounds.conic-halo`, `backgrounds.light-leak`, `backgrounds.wave-band` |
| `backgrounds.particles` | Particle Fields · 粒子场 | 5 | `backgrounds.particle-repulsion`, `backgrounds.fireflies`, `backgrounds.bokeh`, `backgrounds.constellation`, `backgrounds.flow-field` |
| `backgrounds.liquid` | Liquid & Blobs · 液态与融球 | 5 | `backgrounds.metaballs`, `backgrounds.glow-orb`, `backgrounds.lava-lamp`, `backgrounds.ink-bloom`, `backgrounds.slosh-tank` |
| `backgrounds.weather` | Weather · 天气氛围 | 5 | `backgrounds.rain`, `backgrounds.snowfall`, `backgrounds.window-droplets`, `backgrounds.rolling-fog`, `backgrounds.autumn-wind` |
| `backgrounds.waves-grids` | Waves, Grids & Warp · 波浪、网格与跃迁 | 5 | `backgrounds.starfield-warp`, `backgrounds.halftone-flow`, `backgrounds.sine-waves`, `backgrounds.synthwave-grid`, `backgrounds.shockwave-grid` |

### Shaders & Materials · 着色器与材质

File: `MotionLab/Families/ShadersFamilies.swift` · list: `ShaderEffects` · 5 families · 25 effects

| Family id | Name · 名称 | Count | Variations (effect ids) |
|---|---|---:|---|
| `shaders.distortion` | Ripple & Distortion · 涟漪与扭曲 | 5 | `shader.ripple`, `shader.wave`, `shader.swirl`, `shader.chromatic-drag`, `shader.jelly-press` |
| `shaders.transition` | Shader Transitions · 着色器转场 | 5 | `shader.pixelate`, `shader.dissolve`, `shader.edge-scan`, `shader.liquid-wipe`, `shader.tile-scatter` |
| `shaders.glass` | Glass & Lens · 玻璃与透镜 | 5 | `shader.magnifier`, `shader.glassmorphism`, `shader.liquid-glass-lens`, `shader.progressive-blur`, `shader.reeded-glass` |
| `shaders.retro` | Retro & Print · 复古与印刷 | 5 | `shader.glitch`, `shader.crt`, `shader.halftone`, `shader.dither`, `shader.vhs` |
| `shaders.generative` | Generative Light · 生成光效 | 5 | `shader.plasma`, `shader.kaleidoscope`, `shader.caustics`, `shader.voronoi-cells`, `shader.tunnel` |
