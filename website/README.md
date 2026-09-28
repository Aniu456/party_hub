# 康师傅下载网站

独立 Flutter Web 项目，用户下载与 OTA 文件随网站一起托管在现有后台，不依赖 GitHub 下载。页面不连接游戏服务端，不读取签名文件。

## 正式发布

在项目根目录运行：

```sh
python3 tool/build_release.py
```

将输出的 `build/releases/v版本+构建号/party-hub-v版本+构建号-website-android.zip` 上传到后台的原作品。保留原 slug，后台校验后整体切换站点。不要用仅含网页的构建产物覆盖正式站点，否则会移除 APK 与 OTA 清单。

该 ZIP 已适配后台路径和扩展名规则：去除 `.last_build_id`，特殊资源使用 `.txt` 后缀并同步运行时引用。入口直接在 ZIP 根目录，APK 使用版本路径，避免包含两份大安装包。更新清单、校验文件与 APK 在同一包内，不需要新增服务器进程。

网站使用相对路径，网页按钮在构建时通过 `PARTY_HUB_APK_PATH` 指向当前 APK。`downloads/release.txt` 提供版本信息，`downloads/SHA256SUMS.txt` 提供校验信息。APK 的服务器绝对地址由根项目本地配置注入；详见 `../docs/android-releases.md`。

## 本地预览

```sh
flutter pub get
flutter run -d chrome
```

预览仅展示页面；发布 ZIP 才包含实际安装包。独立运行 `flutter build web --release --no-web-resources-cdn` 只构建网站，不能代替正式发布脚本。

## 字体与资源

图标与封面采用蓝色小熊风格，人物插画为 Open Peeps（Pablo Stanley，CC0）。中文字体为 Noto Sans SC 子集 PartySans，许可见 `assets/fonts/OFL.txt`。改动中文文案后更新字体子集：

```sh
python3 tool/subset_font.py /path/to/NotoSansSC.ttf
```

渲染资源和字体随站点提供。启动时显示小熊图标、名称和不表示百分比的加载动画，首帧完成后自动移除；超过 12 秒或脚本加载失败时提供重试和直接下载。未启用 JavaScript 时也保留原生下载链接。iOS 暂无下载入口。

```sh
flutter analyze
flutter test
```
