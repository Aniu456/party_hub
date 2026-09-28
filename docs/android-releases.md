# Android 本机发布与 OTA

推送 `main` 后由 GitHub Actions 自动构建并上传到自己的下载服务器。用户下载 APK、检查 OTA 都访问服务器，不访问 GitHub；服务器保存完整文件，不做逐次请求 GitHub 的透传代理。仅 Android 支持 APK 覆盖安装，iOS 暂不接入。

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

## 自动发布

- 推送 `main` 自动触发；其他分支不发布。Actions 页面也可手动运行当前 `main`。
- 每次构建读取服务器版本，构建号取 `max(pubspec 构建号, 线上构建号 + 1)`，只修改运行器中的版本，不回写 Git。版本名称仍由 `pubspec.yaml` 决定，禁止版本名称倒退。
- 检查、测试、原签名 APK 构建、网站构建全部成功后，再把整包上传服务器。服务器只允许更新预先指定的作品，校验 APK 的 SHA-256 和版本，复用后台 ZIP 校验和原子切换，保留旧站点文件。
- 发布后从公网重新读取清单并下载 APK 核验 SHA-256，成功才将工作流标为成功。若文件已发布、后续公网验证因网络失败，则线上可能已经更新，以实际清单为准。
- 工作流串行执行，不中断正在进行的上传；发布前再次检查提交仍是当前 `main`，防止旧任务覆盖较新的代码。若另一个发布已推进版本，停止本次发布。
- GitHub 无法访问只会延迟新版发布，服务器已有的下载与 OTA 不受影响。

仓库 Actions Secrets：已有的 `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`、`PARTY_HUB_WS`，另加 `PARTY_HUB_DOWNLOAD_BASE`、`PARTY_HUB_DEPLOY_HOST`、`PARTY_HUB_DEPLOY_KEY`、`PARTY_HUB_DEPLOY_KNOWN_HOSTS`。

发布 SSH 密钥必须由服务器强制限制为固定作品的 `publish` / `status` 命令，禁用 Shell、PTY 和转发；CI 不持有服务器现有管理员私钥或博客登录凭据。主机密钥需事先核验并固定，不能关闭主机校验。

## 本机备用发布

GitHub 不可用时可从本机直接构建、上传同一服务器。已有签名配置和专用发布密钥需在本机可用。

```sh
python3 tool/publish_release.py --prepare
python3 tool/build_release.py
python3 tool/publish_release.py \
  --archive build/releases/v版本+构建号/party-hub-v版本+构建号-website-android.zip \
  --host 服务器地址 --identity deploy/github_publish --known-hosts deploy/github_publish_known_hosts
```

`--prepare` 会更新本机 `pubspec.yaml` 构建号。也可以只运行构建脚本，再按下面流程手动上传。

## 手动上传新版

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

## 验证边界

`1.0.2+3` 的扫码加入验收：先保留一台安装 `1.0.1+2` 正式版的 Android 手机，上传新版整站 ZIP 后，在该手机的用户中心检查并安装更新，确认版本升为 `1.0.2+3`、昵称保留。使用新版创建房间并打开“邀请二维码”，另一台新版手机从“加入房间 → 扫码加入”识别，确认昵称后加入；同时检查拒绝相机权限、无效二维码和手输房间码的情况。相机插件需要更新 APK，不能只靠内容 OTA 下发。

打包、签名核对和组件测试不等于真机覆盖安装验收。完整验证需要：旧正式版 → 官网安装迁移版 → 发布更高构建号 → App 检查、下载、校验 → 系统确认覆盖安装 → 检查版本与昵称保留。
