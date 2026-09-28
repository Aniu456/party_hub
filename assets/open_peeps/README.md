# Open Peeps 人物素材

作者：Pablo Stanley。来源：https://www.openpeeps.com/ 。许可：CC0 1.0（https://creativecommons.org/publicdomain/zero/1.0/）。

- 官网 Grab and go 共 93 个独立 SVG，49 半身、30 站姿、14 坐姿。官网 94 个下载链接中的 peep-58 重复一次。旧黑白 SVG 已删除，本地仅保留蓝色 SVG。
- `catalog.json`：官方 URL、SHA-256、尺寸、图层及去重记录。
- `blue/`：App 实际随包加载的蓝色衍生版。原有 12 张 PNG 留作原始记录，不再随 App 打包。
- `clothing_regions.json`：在身体局部坐标内人工选择并视觉检查的白色衣物区域；`protect` 是领口和手部的排除区域。站坐姿的孔洞已合并在路径中，使用 even-odd 填充规则。`regions` 仅记录选区编号，运行时不依赖临时分区文件。
- `generate_blue.py`：通过原图和选区重复生成蓝色 SVG。如需重新生成，先按 `catalog.json` 的 `sourceURL` 下载原图到清单记录的 `path`，并核对 SHA-256，再运行 `python3 assets/open_peeps/generate_blue.py`。脚本本身不下载文件。

蓝色为 `#3659E3`，对应 `lib/app_style.dart` 的 `partyBlue`。白色衣物使用选区补色；黑色衣物在原 Ink 内部补蓝并保留黑色边界，头部、表情和配饰不参与着色。原图和生成脚本不进入 Flutter 资源包。

`lib/open_peeps.dart` 提供全部分类清单，`PeepPortrait(index: ..., pose: PeepPose.standing)` 可显示站姿，坐姿同理；默认半身，前 12 个角色索引与旧版保持一致。`PlayerAvatar` 共用半身人物、浅蓝背景和圆形裁切。
