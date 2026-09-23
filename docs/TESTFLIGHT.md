# 发布到 TestFlight · Shipping to TestFlight

`.github/workflows/testflight.yml` 会在 GitHub 的 macOS 机器上用 Xcode 26 归档（archive）App，
并通过 App Store Connect API 自动签名、上传到 TestFlight。你的 Apple 账号凭据只存放在 GitHub Secrets 里。

## 一次性准备

1. **Apple Developer Program**（付费开发者账号）。
2. **App Store Connect → 我的 App → ＋ 新建 App**
   - 平台 iOS，名称例如「动效词典」，主要语言简体中文
   - 套装 ID（Bundle ID）：新建一个，例如 `com.<你的名字>.motionlexicon`
   - SKU 随意，例如 `motionlexicon`
3. **App Store Connect → 用户和访问 → 集成 → App Store Connect API → 团队密钥 → ＋**
   - 访问权限选 **管理（Admin）**（Xcode 需要它来自动创建证书与描述文件）
   - 下载 `AuthKey_XXXXXXXXXX.p8`（只能下载一次），记下 **Key ID** 和页面顶部的 **Issuer ID**
4. **Team ID**：developer.apple.com → Account → Membership details。
5. **GitHub 仓库 → Settings → Secrets and variables → Actions → New repository secret**，添加：

| Secret | 值 |
|---|---|
| `APPLE_TEAM_ID` | 10 位 Team ID |
| `APP_BUNDLE_ID` | 第 2 步的 Bundle ID |
| `ASC_KEY_ID` | API Key ID |
| `ASC_ISSUER_ID` | Issuer ID |
| `ASC_KEY_P8` | `.p8` 文件的完整文本内容（含 BEGIN/END 行） |

## 上传

- 推送一个提交信息包含 `[testflight]` 的 commit，或（合并到默认分支后）在 Actions 页手动运行 **TestFlight**。
- 构建号自动递增（run number + 100），版本号为 `MARKETING_VERSION`（当前 1.0）。
- 上传后约 5–20 分钟，构建会出现在 App Store Connect → TestFlight；内部测试员可立即安装，
  外部测试需先提交一次 Beta 审核。
- App 已声明 `ITSAppUsesNonExemptEncryption = NO`，无需每次回答出口合规问题。
