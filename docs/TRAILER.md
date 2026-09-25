# 宣传片：修改文案并在自己的 Mac 上录制

Motionary 的 60 秒宣传片（`MotionLab/Trailer/`）是 App 里实时渲染的动画：启动参数 `-ML_trailer YES` 让 App 播放它，
`scripts/record-trailer.sh` 在 iOS 模拟器里录屏，再用 ffmpeg 裁切成小红书用的竖版视频。

画面上的**所有文字**（各场景的标题/副标题、漂浮词、搜索词、筛选胶囊、手机里的提示、提示词卡片、AI 对话、网址、片尾等）
都来自一个 JSON 文件：`trailer/copy.json`。改文案不需要改代码。

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
git clone https://github.com/alanfeiyuchang/ios-anim-effects.git
cd ios-anim-effects
```

### 2. 编辑文案

用浏览器（Safari / Chrome 都行）直接打开 `tools/trailer-editor.html`（在 Finder 里双击，或 `open tools/trailer-editor.html`）。

- 页面按场景分组，每组标着它在片中的时间段（例如「搜索 · 一搜即达 10–21 s」）。
- 每一项下面有简短说明和字数统计（中文算 1、英文/数字算 0.5）。超过建议长度不会出错，但录制时文字会自动缩小。
- 「漂浮的模糊词」「筛选胶囊」这类列表可以增删行。
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
把 `trailer/copy.json` 复制进 App 的 `Documents/trailer-copy.json` → 启动并录屏 → 找到白色开场板结束的位置，精确裁出 60 秒。
单个画幅整个过程约 5–10 分钟（第一次构建更久）。录制时不要操作模拟器窗口。

常用参数：

| 参数 | 作用 | 默认 |
| --- | --- | --- |
| `--aspects "9x16 3x4"` | 录哪些画幅：`9x16`（1080×1920，全屏视频，推荐）、`3x4`（1080×1440，信息流） | 两个都录 |
| `--copy <文件>` | 用哪个文案文件 | `trailer/copy.json`（不存在则用代码里的默认文案） |
| `--out <目录>` | 输出目录 | `out` |
| `--device "<模拟器名>"` | 指定模拟器，例如 `"iPhone 17 Pro"` | 最新的 iPhone Pro |

例子：

```bash
scripts/record-trailer.sh --copy ~/Desktop/双十一版.json --aspects "9x16 3x4" --out ~/Movies/motionary
```

### 4. 拿到视频

结束时脚本会列出文件，并自动在 Finder 里打开输出目录：

```
out/9x16/trailer.mp4           成片：1080×1920，60 fps，约 60 秒（直接上传）
out/9x16/trailer-preview.mp4   小预览：540×960，30 fps
out/9x16/frames/frame-01…12.png  每 5 秒一张关键帧（可挑封面）
out/3x4/…                      3:4 画幅的同样三件套（如果录了）
```

画面底部约 18% 是留给字幕的空白带，后期可以在剪映等工具里加字幕/配乐。

## 占位符

文案里可以写这些占位符，录制时会换成 App 目录里的实时数字，动效数量变了也不用改文案：

| 占位符 | 替换为 |
| --- | --- |
| `{effects}` | 动效总数（例如 461） |
| `{categories}` | 大分类数 |
| `{families}` | 动效家族数 |
| `{name}` | 只用于 `chat.bubbleTitle`：提示词对应的动效名 |

例如 `"{effects} 个可上手玩的 iOS 高级动效"`。

开场的大数字、统计胶囊里的数字、搜索结果数、结果卡片上的动效名、手机页面上的动效名和参数值都来自真实目录，本身不在文案里。
提示词卡片默认显示 `cards.flip` 的真实提示词；想换可以填 `prompt.effectID`（另一个动效的 id），或直接填 `prompt.textZh` / `prompt.textEn`。

## 文案文件的规则

- 格式就是 `trailer/copy.json` 的样子：按场景分组（`hook`、`pain`、`search`、`phone`、`tune`、`prompt`、`chat`、`web`、`end`、`touch`）。
- **可以只写一部分**：缺少的键、类型写错的值都会自动用默认文案。例如只想改一个标题：

  ```json
  { "phone": { "title": "真实上手体验" } }
  ```

- 一些保护：搜索词不能为空；筛选胶囊至少 2 个（手指会点第 2 个）、最多 6 个；漂浮词最多 12 个；网址为空时用默认网址。
- 副标题写成空字符串 `""` 就不显示那一行。
- 文字过长时会自动缩小字号，不会溢出画面；但太长会显得很小，编辑器里的「建议长度」是比较好看的上限。
- 搜索词越长，打字越快（总是在结果出现前打完）；网址越长，地址栏打字时间越长（0.4–1.4 秒）。

## GitHub Actions

`.github/workflows/trailer.yml` 在提交信息包含 `[trailer]` 时（或在 Actions 页手动运行）会用同一个脚本录制两个画幅，
自动使用仓库里的 `trailer/copy.json`，并把结果提交到 `docs/trailer/`。所以改完文案后提交：

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
