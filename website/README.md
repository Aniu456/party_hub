# 康师傅下载网站

独立 Flutter Web 项目，界面由 `lib/main.dart` 实现。仅展示公开的产品信息和 GitHub Release 下载链接，不连接游戏服务端，不读取根项目的生产配置或签名文件。

## 本地预览

在本目录执行（Flutter 3.47.0 / Dart 3.13）：

```sh
flutter pub get
flutter run -d chrome
```

## 构建与 1Panel 部署

```sh
flutter build web --release --no-web-resources-cdn
```

将 **`build/web/` 内的全部内容** 上传到 1Panel 对应静态网站的根目录。目录中直接可见 `index.html`、`main.dart.js`、`assets/`、`canvaskit/` 等文件；不要只上传 HTML，也不要多嵌套一层 `web/`。

- 1Panel 创建或使用现有「静态网站」，默认首页设为 `index.html`。无需 Node、Dart 或 Flutter 服务进程。
- 默认相对资源路径，也可放在子目录（例如 `/download/`）；访问子目录时 URL 应以 `/` 结尾。
- 不需要反向代理、游戏服务器地址或任何密钥。域名和 HTTPS 在 1Panel 中按实际环境设置。
- 更新时替换完整构建产物，避免旧 `index.html`、`flutter_bootstrap.js`、`main.dart.js` 长期缓存；这些入口文件建议使用 `Cache-Control: no-cache`。
- 若站点启用了严格 CSP，需允许同源脚本、资源及 WebAssembly 执行。使用常规静态网站配置即可，勿把 `.wasm` 请求重写成 HTML。
- 页面字体和 Flutter 渲染资源均随构建打包。APK 下载仍需要用户能访问 GitHub。
- 初始 HTML 保留直接下载链接，JavaScript 未启用或页面加载较慢时也可以下载。

## 下载地址

- 最新 APK：https://github.com/Aniu456/party_hub/releases/latest/download/party-hub.apk
- 版本记录：https://github.com/Aniu456/party_hub/releases
- SHA256 校验文件：https://github.com/Aniu456/party_hub/releases/latest/download/SHA256SUMS

按钮使用 GitHub 的 `latest` 地址，发布新版 APK 后无需重新构建网站。iOS 暂无下载入口。网页图标使用当前项目图标；旧版 APK 图标可能不同，取决于对应版本的构建内容。

## 资源与验证

App 图标来自本项目 `assets/branding/`，人物插画为项目已使用的 Open Peeps（Pablo Stanley，CC0）。这里保留发布所需的资源副本。

中文字体为 Google Fonts 的 [Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc)，按本站文字子集化并命名为 PartySans，许可见 `assets/fonts/OFL.txt`。增加页面文字后，使用原始可变 TTF 重新生成子集：

```sh
python3 tool/subset_font.py /path/to/NotoSansSC.ttf
```

该脚本需要 Python `fonttools`。常规构建不需要重新下载或生成字体。

```sh
flutter analyze
flutter test
```

构建输出 `build/` 已忽略，不应提交到公开仓库。
