# Android 自动更新

发布仓库：[Aniu456/party_hub](https://github.com/Aniu456/party_hub)。仅接入 Android；iOS 暂不接更新渠道。

## 用户怎么更新

正式版冷启动进入大厅后检查一次 GitHub 最新 Release；用户中心也可点击「检查应用更新」。只有更高的 Android 构建号才提示更新。用户确认后下载完整 APK，显示进度，校验 SHA-256，再打开系统安装界面由用户确认。首次安装此来源时可能需要系统授权。下载安装不会静默执行，也不是 Dart 热补丁。

自动检查失败时不影响游戏；用户主动检查失败会明确提示。网络请求返回时若已离开大厅或 App 在后台，不弹出更新窗口。正在对局时不会检查、下载或替换代码。未发布首版时显示「暂未发布可用更新」。GitHub 无法连接时可继续使用原版本。

## 首次配置

Actions 需要以下仓库 Secrets（Settings → Secrets and variables → Actions）：

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | 正式签名 JKS 文件的 Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | JKS 密码 |
| `ANDROID_KEY_ALIAS` | 签名别名 |
| `ANDROID_KEY_PASSWORD` | 私钥密码 |
| `PARTY_HUB_WS` | 正式联机 WSS 地址（构建时注入） |

签名密钥必须备份并长期复用，不能在每次 CI 中重新生成。`android/release.jks` 和 `android/key.properties` 已被 Git 忽略。后者使用下列格式（真实密码不要提交）：

```properties
storeFile=release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=partyhub
keyPassword=YOUR_KEY_PASSWORD
```

公开仓库仅包含 App、公开测试与发布工具。服务端、部署目录、内部规划、运维工具、iOS 团队标识和本地配置均被忽略。提交前运行 `python3 tool/check_public_files.py`，该检查读取 Git 暂存区而非只看 `.gitignore`。本地正式地址保存在被忽略的 `.env.production.json`，可用 `flutter run --dart-define-from-file=.env.production.json` 运行；iOS 本机签名团队保存在 `ios/Flutter/Signing.local.xcconfig`。不要使用 `git add -f` 强行加入这些文件。

构建注入只避免生产地址出现在公开源码；联网 APK 中的连接地址仍可被提取，不能把它当作访问凭证。

安装包沿用项目当前应用 ID `com.example.party_hub`。之后更改应用 ID 将被系统视为另一个应用。原先使用调试签名安装的版本无法被正式签名覆盖；测试设备需卸载调试版后安装首个正式版（卸载会删除本机昵称）。后续正式版之间用同一签名覆盖安装，保留本机数据。

## 发布新版

1. 修改 `pubspec.yaml` 的 `version`，例如 `1.0.1+2`。`+` 后的构建号必须严格大于已发布版本；同一版本名也可提高构建号。
2. 提交并推送代码，然后创建和推送完全匹配的 tag：

   ```sh
   git tag v1.0.1+2
   git push origin main
   git push origin v1.0.1+2
   ```

3. [Android Release 工作流](https://github.com/Aniu456/party_hub/actions/workflows/android-release.yml) 自动校验版本、检查源码、运行测试、签名打包并发布 Release。也可在 Actions 手动执行，输入已经推送的 tag。
4. Release 包含 `party-hub.apk`、`update.json` 和 `SHA256SUMS`。先以草稿上传完整文件，再公开并标记 latest，避免客户端拿到半成品。重跑可以续传同一草稿；已公开版本禁止覆盖，应提高构建号重新发布。

首次发行使用 `v1.0.0+1`。首次安装从 [Releases](https://github.com/Aniu456/party_hub/releases) 下载 `party-hub.apk`；以后由 App 提示升级。仅推送普通代码不会发布安装包。

## 验证边界

静态检查和模拟原生事件的测试不能证明系统安装成功。完整验收需要：在 Android 真机安装首版 → 发布更高构建号 → 打开旧版收到提示 → 下载校验 → 系统确认覆盖安装 → 检查版本与昵称保留。还应检查取消下载、拒绝安装权限、安装界面取消以及网络不可用后的重试。

参考：[Flutter Android 发布与签名](https://docs.flutter.dev/deployment/android)、[ota_update 插件](https://pub.dev/packages/ota_update)、[GitHub Release 下载链接](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases)。
