# Android 本机发布与 OTA

默认使用本机构建、后台上传。GitHub 可保留源码和构建备份，用户下载与更新不依赖 GitHub。仅 Android 支持 APK 覆盖安装，iOS 暂不接入。

## 一次配置

继续使用已有 `android/release.jks` 和 `android/key.properties`，不要重新生成签名密钥。两者均被 Git 忽略；发布脚本会核对 APK 签名与首个正式版相同，并检查包名、版本号。

在被忽略的 `.env.production.json` 中配置：

```json
{
  "PARTY_HUB_WS": "wss://example.invalid/party-hub/ws",
  "PARTY_HUB_DOWNLOAD_BASE": "https://example.invalid/work/party-hub/downloads"
}
```

下载地址必须是 HTTPS，不带结尾斜杠。该路径应为后台已发布作品的地址加 `/downloads`；作品 slug 发布后保持不变，否则已安装 App 的更新地址会失效。

## 发布新版

1. 提高 `pubspec.yaml` 的版本号，例如 `1.0.1+2`。构建号必须大于服务器已发布版本。
2. 在项目根目录执行：

   ```sh
   python3 tool/build_release.py
   ```

3. 脚本检查线上版本，构建正式签名 APK，验证签名与版本，构建网站，再检查线上版本是否变化，生成 `build/releases/v版本+构建号/party-hub-v版本+构建号-website-android.zip`。
4. 在后台编辑**原来的作品**，上传该 ZIP 并保存。不要新建作品或更改 slug。后台校验并解压完成后才切换整个站点，因此网站、APK、校验文件和更新清单一起生效。构建脚本不会自动上传。
5. 上传后检查网站下载、`downloads/update.json` 与 `downloads/SHA256SUMS.txt`，并在 Android 真机验证更新。

ZIP 包含：

- 网站完整资源，小熊图标与本站下载按钮。
- `downloads/v版本+构建号/party-hub.apk`：正式安装包。
- `downloads/update.json`：版本、构建号、版本对应的 APK 地址与 SHA-256。
- `downloads/SHA256SUMS.txt`：便于人工核验。
- `downloads/release.txt`：当前版本信息。

不要再上传仅含网页的旧 ZIP，否则会把 OTA 文件一起替换掉。每次整站包只携带当前 APK，不是历史版本仓库；如果恰逢发布切换导致正在进行的旧版本下载失败，重新检查更新后再下载即可。脚本会检查后台的 100 MB 压缩包、200 MB 解压大小和 5000 文件限制。

## 旧版迁移与更新行为

`1.0.0+1` 仍检查 GitHub。用户须从官网手动下载安装一次新版本，之后由 App 访问配置的服务器更新。正式签名一致可覆盖安装并保留本机昵称；调试签名不能覆盖正式签名，不要为绕过签名冲突贸然卸载而丢失数据。

正式版冷启动时自动检查；用户中心也可手动检查。仅更高构建号提示更新。用户确认后下载 APK，校验 SHA-256，再交给系统确认安装。这不是静默更新或 Dart 热补丁。对局中不自动更新。

App 只接受构建时指定的 HTTPS 下载目录和清单版本对应的 APK 路径，不能被清单引导到任意源。网络错误或损坏清单会报告检查失败，不会伪装成最新版。

## 可选 GitHub Actions

原 Android Release 工作流保留为可选构建/备份渠道，不负责更新你的服务器。使用前除原签名 Secrets、`PARTY_HUB_WS` 外，还须配置 `PARTY_HUB_DOWNLOAD_BASE`。推送与版本一致的标签可生成 GitHub Release；仅生成 GitHub Release 不会让服务器出现新版。本机发布不需要推送标签或配置 Actions。

## 验证边界

`1.0.2+3` 的扫码加入验收：先保留一台安装 `1.0.1+2` 正式版的 Android 手机，上传新版整站 ZIP 后，在该手机的用户中心检查并安装更新，确认版本升为 `1.0.2+3`、昵称保留。使用新版创建房间并打开“邀请二维码”，另一台新版手机从“加入房间 → 扫码加入”识别，确认昵称后加入；同时检查拒绝相机权限、无效二维码和手输房间码的情况。相机插件需要更新 APK，不能只靠内容 OTA 下发。

打包、签名核对和组件测试不等于真机覆盖安装验收。完整验证需要：旧正式版 → 官网安装迁移版 → 发布更高构建号 → App 检查、下载、校验 → 系统确认覆盖安装 → 检查版本与昵称保留。
