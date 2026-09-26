# 宣传片：修改文案与旁白，并在自己的 Mac 上录制

Motionary 的 75 秒宣传片（`MotionLab/Trailer/`）是 App 里实时渲染的「一镜到底」动画：启动参数 `-ML_trailer YES` 让 App 播放它，
`scripts/record-trailer.sh` 在 iOS 模拟器里录屏，再用 ffmpeg 裁切成小红书用的竖版视频，并生成旁白字幕 `voiceover.srt`。

画面上的**所有文字**（各场景的标题/副标题、漂浮词、搜索词、卖点胶囊、手机里的提示、提示词卡片、AI 对话、网址、片尾等）
和**旁白稿**都来自一个 JSON 文件：`trailer/copy.json`。改文案、改旁白都不需要改代码。

## 分镜（75.4 秒）

| 时间 | 场景 | 画面 | 旁白（默认） |
| --- | --- | --- | --- |
| 0–4.3 s | 开场 | 动效总数「461」用 App 里「翻滚棱柱数字」效果的真实 3D 棱柱一面面翻滚，从左到右带回弹落定；下方「个 iOS 高级动效」和两个统计胶囊 | 400 多个 iOS 动效，帮你找到适合的丝滑效果 |
| 4.3–13.8 s | 痛点 1 | 「想要的动效，说不出来」，周围漂浮「弹一下？」「来点高级感？」「像果冻？」…… | 做 App 的时候你一定遇到过这种情况…… |
| 13.8–18.6 s | 痛点 2 | 一格格模糊的未知动效，每格一个问号：「iOS 能做到什么？不知道」 | 更难的是，你根本不知道 iOS 原生能做出哪些效果 |
| 18.6–23.8 s | 登场 | App 图标 + Motionary + 动效词典，四个卖点：找灵感 · 上手体验 · 一键复制提示词 · 完全开源 | 所以我做了 Motionary…… |
| 23.8–33.2 s | 找灵感 | 手机里是 **App 真实的首页和搜索页**（像录屏）：首页滑过精选、系列、分类；点搜索，输入「卡片」，点「质感交互精选」分类，再点开一个结果 | 461 个动效，按 15 个分类、85 个家族整理…… |
| 33.2–43.1 s | 上手感受 | 动效详情页依次演示照片卡片播放、收藏迸发、雪板翻转，手指点击带涟漪，手机随之轻轻一震 | 每个动效都是真实运行的 SwiftUI…… |
| 43.1–52.4 s | 我最喜欢的 | 同一台手机上：昼夜切换开关（手指来回切三次），然后装备清单（五件装备依次打包，「装备齐全」） | 其中我最喜欢的有昼夜切换开关……还有这个装备清单…… |
| 52.4–61.9 s | 一键复制提示词 | 提示词卡片、中/EN 切换、一键复制，飞进 AI 对话 | 每个动效都配有中英双语的专业提示词…… |
| 61.9–68 s | 网页 + App | 左边浏览器（地址栏打出 `alanfeiyuchang.github.io/motionary-ios-animations`），右边手机被手指点着玩：「网页随时看 · App 感受手感」 | 想快速浏览，打开网页就能看全部录像…… |
| 68–71 s | 开源 | 手机退场，浏览器移到中央放大，地址栏改打 `github.com/alanfeiyuchang/motionary-ios-animations`，页面是仓库的真实截图（`trailer/github.jpg`），下滑到 README 标题和「在线预览」链接 | 整个项目已经开源，欢迎查看 |
| 71–75.4 s | 片尾 | GitHub 窗口收拢成 App 图标：Motionary · 动效词典 · iOS Motion Dictionary + 「让动效说得清 · 看得见 · 摸得着」+「更多动效后续加入」小胶囊 | Motionary 让动效说得清，看得见、摸得着 |

画面底部约 18% 始终空着，留给旁白字幕。

## 需要什么

| 需要 | 说明 |
| --- | --- |
| 一台 Mac | Apple 芯片或 Intel 都可以 |
| Xcode 26（或 Xcode 16） | 从 App Store 安装，**至少打开一次**，并在 Xcode › Settings › Components 里装好 iOS 模拟器 |
| Homebrew 的 ffmpeg | `brew install ffmpeg`（没有 Homebrew：先按 <https://brew.sh> 安装） |
| 磁盘空间 | 约 5 GB（构建缓存 + 录像） |

如果装了多个 Xcode，确认命令行用的是正确的那个：

```bash
xcode-select -p                                   # 应该指向 …/Xcode.app/Contents/Developer
sudo xcode-select -s /Applications/Xcode.app      # 不对的话切换一下
```

## 一步一步

### 1. 获取代码

```bash
git clone https://github.com/alanfeiyuchang/motionary-ios-animations.git
cd motionary-ios-animations
```

### 2. 编辑文案

用浏览器（Safari / Chrome 都行）直接打开 `tools/trailer-editor.html`（在 Finder 里双击，或 `open tools/trailer-editor.html`）。

- 页面按场景分组，每组标着它在片中的时间段（例如「找灵感 · 一搜即达 23.8–33.2 s」）。
- 每一项下面有简短说明和字数统计（中文算 1、英文/数字算 0.5）。超过建议长度不会出错，但录制时文字会自动缩小。
- 「漂浮的模糊词」「卖点胶囊」这类列表可以增删行。
- 最后一节「旁白 · 字幕」：每行一个开始/结束秒数和一段旁白，可增删行、按时间排序；每行下面实时预览切好的字幕条（和录制脚本的切法完全一致），
  并提示语速（中文配音约 4–5 字/秒为宜）、时间重叠等问题。
- 修改会自动保存在本机浏览器里；**导入 JSON** 可以载入已有的 `copy.json` 继续改；**恢复默认** 回到原始文案。
- 改完点 **导出 copy.json**，把下载的文件移动到仓库里，覆盖 `trailer/copy.json`：

```bash
mv ~/Downloads/copy.json trailer/copy.json
```

这个页面完全离线，不会联网。

### 3. 录制

```bash
scripts/record-trailer.sh --aspects 9x16
```

脚本会：检查 Xcode / 模拟器 / ffmpeg → 选一台模拟器（默认是最新的 iPhone Pro）→ 用 Release 配置构建并安装 App →
把 `trailer/copy.json` 复制进 App 的 `Documents/trailer-copy.json` → 启动并录屏 → 找到白色开场板结束的位置，精确裁出 75.4 秒 →
从 App 取回解析后的文案（`trailer-resolved.json`）写出旁白字幕。
单个画幅整个过程约 6–12 分钟（第一次构建更久）。录制时不要操作模拟器窗口。

常用参数：

| 参数 | 作用 | 默认 |
| --- | --- | --- |
| `--aspects "9x16 3x4"` | 录哪些画幅：`9x16`（1080×1920，全屏视频，推荐）、`3x4`（1080×1440，信息流） | 两个都录 |
| `--copy <文件>` | 用哪个文案文件 | `trailer/copy.json`（不存在则用代码里的默认文案） |
| `--out <目录>` | 输出目录 | `out` |
| `--device "<模拟器名>"` | 指定模拟器，例如 `"iPhone 17 Pro"` | 最新的 iPhone Pro |
| `--voiceover-only` | 只重新生成 `voiceover.srt` / `voiceover.txt`（改了旁白文字或时间，不用重录；不需要 Xcode） | 关 |

例子：

```bash
scripts/record-trailer.sh --copy ~/Desktop/双十一版.json --aspects "9x16 3x4" --out ~/Movies/motionary
```

### 4. 拿到视频

结束时脚本会列出文件，并自动在 Finder 里打开输出目录：

```
out/9x16/trailer.mp4             成片：1080×1920，60 fps，75.4 秒（直接上传）
out/9x16/trailer-preview.mp4     小预览：540×960，30 fps
out/9x16/frames/frame-01…18.png  每 5 秒一张关键帧（可挑封面）
out/9x16/voiceover.srt           旁白字幕（UTF-8，每条 ≤ 18 字）
out/9x16/voiceover.txt           旁白稿（每行一段，用于录音或 AI 配音）
out/9x16/trailer-resolved.json   App 实际使用的文案（占位符已换成数字）和目录数量
out/3x4/…                        3:4 画幅的同样一套（如果录了）
```

画面底部约 18% 是留给字幕的空白带。

## 旁白与字幕（剪映）

旁白写在 `trailer/copy.json` 的 `voiceover` 里（编辑器最后一节），每行是 `{ "start": 秒, "end": 秒, "text": "旁白" }`，
时间以成片开头为 0。旁白**不会**画在画面上，只用来生成字幕和配音稿：

- 录制时 App 把解析后的文案写到 `Documents/trailer-resolved.json`（`{effects}` 等占位符已换成实时数字），脚本取回后生成
  `voiceover.srt`：每行旁白先按句号/问号/分号分句，再在逗号、顿号处切成尽量少、长度尽量均匀的字幕条（每条 ≤ 18 字，中文算 1、英文算 0.5，
  不会切断英文单词和 `0.55` 这样的数字），每条的时长按字数在这一行的时间段里分配；句中的「，。；：」换成空格，句尾的去掉。
- 只改了旁白文字或时间：`scripts/record-trailer.sh --voiceover-only` 会用新的 `trailer/copy.json` 重写 `out/<画幅>/voiceover.srt`
  （数字取自上次录制留下的 `trailer-resolved.json`），不用重录视频。

在剪映里使用：

1. 导入 `trailer.mp4`，拖到时间线。
2. **文本 › 本地字幕 › 导入字幕**（或把 `voiceover.srt` 直接拖进时间线），字幕会按时间自动对齐；统一设置字体、大小，放在画面底部的空白带里。
3. 配音：选中字幕轨 › **文本朗读**，挑一个音色即可一键生成配音；也可以照着 `voiceover.txt` 自己录，导入音频后对齐字幕。
4. 配音偏长时，在编辑器里把那一行的结束时间调晚一点或删减文字，再运行 `--voiceover-only` 重新导入字幕。
5. 加背景音乐，注意把音乐音量压低（约 −18 dB）让旁白清楚。

## 占位符

文案里可以写这些占位符，录制时会换成 App 目录里的实时数字，动效数量变了也不用改文案：

| 占位符 | 替换为 |
| --- | --- |
| `{effects}` | 动效总数（例如 461） |
| `{categories}` | 大分类数 |
| `{families}` | 动效家族数 |
| `{name}` | 只用于 `chat.bubbleTitle`：提示词对应的动效名 |

例如 `"{effects} 个可上手玩的 iOS 高级动效"`。

开场的大数字、统计胶囊里的数字、手机里 App 首页和搜索页上的一切（它们就是 App 本身的页面）、详情页上的动效名和参数值都来自真实目录，本身不在文案里。
提示词卡片默认显示手机上演示的第一个动效（`showcase.photo-play`）的真实提示词；想换可以填 `prompt.effectID`（另一个动效的 id），或直接填 `prompt.textZh` / `prompt.textEn`。

## 文案文件的规则

- 格式就是 `trailer/copy.json` 的样子：按场景分组（`hook`、`pain`、`unknown`、`intro`、`search`、`phone`、`tune`、`prompt`、`chat`、`web`、`end`），
  外加旁白数组 `voiceover`。
- **可以只写一部分**：缺少的键、类型写错的值都会自动用默认文案。例如只想改一个标题：

  ```json
  { "phone": { "title": "真实上手体验" } }
  ```

- 一些保护：搜索词不能为空；漂浮词最多 12 个；卖点胶囊最多 4 个；网址为空时用默认网址；旁白里空的行会被忽略，结束早于开始的行不输出。
- 副标题写成空字符串 `""` 就不显示那一行。
- 文字过长时会自动缩小字号，不会溢出画面；但太长会显得很小，编辑器里的「建议长度」是比较好看的上限。
- 搜索词越长，打字越快（约 1 秒内打完）；网址越长，地址栏打字时间越长（0.4–1.4 秒）。
- 搜索词会在 App 的真实搜索里执行：换了词，手机里的结果也会变。手指打开的是「质感交互精选」结果里的 `showcase.photo-play`
  （它在前两行时点它，否则点第一张卡片），之后的详情页演示固定是上面分镜里的 4 个动效。

## 开发时预览某一段

在 Xcode 的 Scheme › Run › Arguments 里加 `-ML_trailer YES -ML_trailerFrom 30`，App 会跳过白色开场板、直接从第 30 秒播放（录制脚本从不传这个参数）。
`-ML_trailerAspect 3x4` 看 3:4 画幅。

手机里的 App 页面是按 iPhone 16/17 Pro（402 × 874 pt）排版后等比缩小的真实页面。搜索页上手指点的位置（「质感交互精选」胶囊、第一张结果卡片）
是按系统导航栏高度估算的：如果录出来手指没点准，调整 `MotionLab/Trailer/TrailerFind.swift` 里的 `searchContentTop`。

## 英文版（或别的口播版本）

一个语言版本 = 一个文案文件。`trailer/copy-en.json` 就是英文版：

- `"language": "en"`：手机里的 App 页面、动效名、参数、网页、提示词卡片（先英文、切到中文再切回）都用英文，录制脚本也用英文启动 App；
- `"edit"`：这一版口播的剪辑时间轴，`duration` 是成片长度（最后一句字幕的结束时间），`knots` 是 [成片时间, 源时间] 对，
  把每句字幕对到它讲的画面上（手机里有实时动效的那一段保持 1 倍速，节奏只在静止的段落里快慢调整）；
- 其余各组是画面上的英文文字，`voiceover` 是英文口播的 30 句字幕。

录制：

```bash
scripts/record-trailer.sh --aspects 9x16 --copy trailer/copy-en.json --out out-en
```

时长和语言都从文案文件里读，不用另外传参数。

## 开源画面的 GitHub 截图

68–71 秒浏览器里显示的是 `trailer/github.jpg`：仓库首页在手机宽度（393 pt，3 倍图裁到 786 px 宽）、深色模式下的整页截图，
保留从顶部到 README 动图上沿的一段（约 1330 pt 高）。录制脚本会把它复制进 App 的 `Documents/trailer-github.jpg`；
文件不存在时画面里只画一个简单的替身。README 改版后重新截一张覆盖它即可，
滚动停在哪里由 `TrailerGitHubPage.stopFraction`（截图高度的比例）决定。

## GitHub Actions

`.github/workflows/trailer.yml` 在提交信息包含 `[trailer]` 时（或在 Actions 页手动运行）会用同一个脚本录制两个画幅，
自动使用仓库里的 `trailer/copy.json`，并把视频、关键帧和 `voiceover.srt` / `voiceover.txt` 提交到 `docs/trailer/`。所以改完文案后提交：

```bash
git add trailer/copy.json
git commit -m "更新宣传片文案 [trailer]"
git push
```

也可以让云端录制，省去本地环境。

## 常见问题

**找不到模拟器 / “没有可用的 iPhone 模拟器”**
打开 Xcode › Settings › Components，安装 iOS 平台（模拟器运行时）。用 `--device` 时名称必须和列表完全一致，
脚本会打印可用的名称；也可以用 `xcrun simctl list devices available` 查看，或在 Xcode › Window › Devices and Simulators 新建一台 iPhone Pro。

**“xcrun simctl 不可用” / 找不到 xcodebuild**
通常是 `xcode-select` 指向了 CommandLineTools：运行 `sudo xcode-select -s /Applications/Xcode.app`，并至少打开一次 Xcode 接受许可。

**第一次构建很慢**
正常。第一次要编译整个 App（几分钟到十几分钟），之后会复用 `build/` 里的缓存。构建日志在仓库根目录的 `build.log`；
构建失败时脚本会列出 `error:` 行。

**字幕里出现 `{effects}` 这样的占位符**
说明这次没有取回 App 写的 `trailer-resolved.json`（脚本会打印 warning）。重录一次，或在已有输出目录上运行 `--voiceover-only`
（它用该目录里上次的 `trailer-resolved.json` 的数字）。

**“white slate not found”（找不到白色开场板）**
脚本靠开场 2.5 秒的纯白画面对齐时间。出现这个错误说明这次启动没有从头播放（例如有残留的 App 实例、模拟器太卡、录屏开始太晚）。
看一下输出目录里的 `debug-first-frame.png`，然后：关掉其他占用 CPU 的程序，退出模拟器（`xcrun simctl shutdown all`）后重跑；
录制期间不要点击模拟器窗口。

**缺少 ffmpeg / ffprobe**
`brew install ffmpeg`。

**改了文案但视频里没变**
确认文件放在 `trailer/copy.json`（或用 `--copy` 指向它），并且是合法 JSON（脚本会检查；也可以用编辑器的「导入 JSON」验证）。
脚本每次启动前都会把文案复制进 App；不带文案文件运行时会删除旧的 `trailer-copy.json`，因此使用默认文案。

**画面卡顿**
录制时尽量不开其他大型程序；用 Release 构建（脚本默认如此）；插着电源录制。
