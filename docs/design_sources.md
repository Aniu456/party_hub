# UI 设计来源与接入范围

核对日期：2026-09-28。三套资源的使用方式不同；不能把本次工作表述为导入了三套完整开源设计系统。

## Nucleus UI Lite

- 官方介绍与预览：[Nucleus Lite](https://www.nucleus-ui.com/nucleus-lite)。
- 官方授权：[License Agreement](https://www.nucleus-ui.com/license)。
- 本项目参考官方公开预览中的移动端排版、留白、卡片、表单和按钮层级，以 Flutter 自行实现大厅、游戏详情和用户中心的布局与组件。
- 本次没有下载、导入或随应用分发完整 Figma 源文件，也没有集成 Nucleus 官方 Flutter 组件包。
- 官方授权允许将 Lite 用于个人、客户及商业成品 App，但限制设计文件和内容的再分发、作为 UI 套件或模板发布等用途。免费不等于无条件开源；此处只记录本次参考范围，不将其声明为 MIT 或 CC0。

## Game UX Kit — Alena Eresko / Dismantle Studio

- 作者发布页：[Game UX Kit — FREE](https://www.behance.net/gallery/223928871/Game-UX-Kit)。
- 本项目基于 Behance 公开展示的组件和游戏交互模式，参考主要行动、次要行动、阶段信息、进度与结果反馈的组织方式，以现有 Flutter 游戏界面实现。
- 本次没有下载、导入或随应用分发完整 Figma 源文件；游戏逻辑、权限、主持人身份隔离仍由项目自身实现。
- 发布页提供免费 Figma 资源入口。尚未核实下载文件附带的完整商业使用、再分发和署名条款，因此不将其标记为 MIT、CC0 或已完成源文件授权核验。本次也未将作者的原始组件、字体或预览图打包进应用。

## Open Peeps — Pablo Stanley

- 官方网站：[Open Peeps](https://www.openpeeps.com/)。
- 官方声明的许可：[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)。官网明确允许个人与商业用途，并允许复制、修改和分发。
- 本项目实际随包接入官网提供的 12 张 PNG 半身人物插画，位于 `assets/open_peeps/peep_00.png` 至 `peep_11.png`。用于玩家头像、大厅人物插画及部分游戏封面，离线加载，不要求用户联网获取头像。
- 每张图的官网 CDN 来源与文件大小见 [sources.json](../assets/open_peeps/sources.json)。原图保留透明背景；头像的缩放、裁切和背景色由 Flutter 布局决定。
- 本次没有引入全部 Open Peeps 组合库、Blush 服务或其他插画包。CC0 的使用说明仅对应这些来源明确的 Open Peeps 插画。

## 验证边界

- 已核对本地素材清单、PNG 文件头、文件大小及部分原图视觉内容。设计来源记录不能替代应用界面验收。
- 三套参考的组合效果、暗色模式、小屏及大字体布局以本项目后续静态检查、组件测试和实际设备查看结果为准。
- App 显示名称现已更新为「康师傅」；下方预览保留改名之前的 UI 验收记录。App Icon 已采用下述融合版，发布下载页面尚待制作。

## 本轮验收结果

- `flutter analyze` 通过；56 项相关测试通过，覆盖 26 款游戏首屏、人数门槛、昵称读写与失败、准备与离线、私密遮挡、画板确认、320/375 宽度、横屏及大字体。
- 已检查 390 × 844 的组件渲染预览；预览文件仅本地保留，不随公开仓库分发。
- 这些图片由 Flutter 组件渲染生成，预览加载本机中文字体；计时与选项图使用展示数据。它们不是模拟器/真机截图，也不代表线上对局验收。
- 本轮未构建安装包、未重新安装原生应用。昵称在实际进程重启后保留仍待设备验收。

## 正式 App Icon

用户选定 C + A 融合版：橙白双卡牌与两位击掌朋友。使用内置 imagegen 创作，提示词及候选记录仅本地保留。1024px 主图见 [app_icon.png](../assets/branding/app_icon.png)；已按现有 iOS AppIcon 目录和 Android 五档 mipmap 密度导出。仅做尺寸转换，保留选定画面，不预裁外圆角。全部平台文件经尺寸及不透明 RGB 检查。本轮未构建安装包，实际桌面显示待重新安装验收。
