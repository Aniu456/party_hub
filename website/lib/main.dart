import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

const apkUrl =
    'https://github.com/Aniu456/party_hub/releases/latest/download/party-hub.apk';
const releasesUrl = 'https://github.com/Aniu456/party_hub/releases';
const checksumUrl =
    'https://github.com/Aniu456/party_hub/releases/latest/download/SHA256SUMS';
const blue = Color(0xFF3155E7);
const ink = Color(0xFF182343);
const muted = Color(0xFF59647B);
const paper = Color(0xFFF8F9FC);
const line = Color(0xFFE3E7F0);

void main() => runApp(const DownloadApp());

class DownloadApp extends StatelessWidget {
  const DownloadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '康师傅 · 聚会游戏',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PartySans',
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          primary: blue,
          onPrimary: Colors.white,
          surface: paper,
          onSurface: ink,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 15, height: 1.7, color: ink),
          bodyLarge: TextStyle(fontSize: 17, height: 1.8, color: muted),
        ),
        dividerColor: line,
      ),
      home: const DownloadPage(),
    );
  }
}

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _gamesKey = GlobalKey();
  final _installKey = GlobalKey();

  void _goTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _WidthLimit(
                child: LayoutBuilder(
                  builder: (context, constraints) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Row(
                      children: [
                        const _Brand(),
                        const Spacer(),
                        if (constraints.maxWidth >= 650) ...[
                          TextButton(
                            onPressed: () => _goTo(_gamesKey),
                            child: const Text('发现玩法'),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () => _goTo(_installKey),
                            child: const Text('安装指南'),
                          ),
                          const SizedBox(width: 24),
                        ],
                        const _WebLink(
                          url: apkUrl,
                          label: '下载 App',
                          icon: Icons.south_rounded,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _WidthLimit(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 850;
                    final text = _heroText(wide);
                    return Padding(
                      padding: EdgeInsets.only(top: wide ? 62 : 24, bottom: 48),
                      child: wide
                          ? Row(
                              children: [
                                Expanded(flex: 6, child: text),
                                const SizedBox(width: 24),
                                const Expanded(flex: 5, child: _HeroArt()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                text,
                                const SizedBox(height: 36),
                                const Center(
                                  child: SizedBox(
                                    width: 460,
                                    child: _HeroArt(),
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
              const _WidthLimit(child: _Highlights()),
              _WidthLimit(
                child: Padding(
                  key: _gamesKey,
                  padding: const EdgeInsets.only(top: 88, bottom: 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Eyebrow('THE MORE, THE MERRIER'),
                      const SizedBox(height: 14),
                      const Text(
                        '什么局，都有得玩。',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '两个人的较量，一群人的热闹。把选游戏的时间，留给朋友。',
                        style: TextStyle(color: muted, height: 1.8),
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth >= 750
                              ? (constraints.maxWidth - 36) / 3
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 18,
                            runSpacing: 18,
                            children: [
                              _GameCard(
                                width: width,
                                number: '01',
                                tag: '脑洞与演技',
                                title: '谁是卧底',
                                description: '一句话露出破绽？\n和朋友来一场观察力较量。',
                                footnote: '4–12 人 · 含 1 名独立主持人',
                                image: 'assets/peep_00.png',
                                color: const Color(0xFFE8EDFF),
                              ),
                              _GameCard(
                                width: width,
                                number: '02',
                                tag: '灵魂画手集合',
                                title: '你画我猜',
                                description: '画得像不像不重要，\n懂你的朋友自然会懂。',
                                footnote: '2–12 人 · 轮流画图猜词',
                                image: 'assets/peep_05.png',
                                color: const Color(0xFFFFEDCE),
                              ),
                              _GameCard(
                                width: width,
                                number: '03',
                                tag: '两个人也尽兴',
                                title: '双人 PK',
                                description: '五子棋、反应力对决，\n看看今天谁更胜一筹。',
                                footnote: '恰好 2 人 · 面对面挑战',
                                image: 'assets/peep_09.png',
                                color: const Color(0xFFE4EFDD),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '还有海龟汤、你比我猜、默契问答等玩法，在 App 里慢慢发现。',
                        style: TextStyle(color: muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                key: _installKey,
                width: double.infinity,
                color: const Color(0xFFEDF1FF),
                child: _WidthLimit(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Eyebrow('READY WHEN YOU ARE'),
                        const SizedBox(height: 14),
                        const Text(
                          '三步，把快乐装进口袋。',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 32),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth >= 750
                                ? (constraints.maxWidth - 48) / 3
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 24,
                              runSpacing: 28,
                              children: [
                                _Step(
                                  width: width,
                                  number: '1',
                                  title: '下载 Android 安装包',
                                  body: '点击下载按钮，从 GitHub Release 获取最新正式版 APK。',
                                ),
                                _Step(
                                  width: width,
                                  number: '2',
                                  title: '按系统提示完成安装',
                                  body: '打开 APK。如系统询问，请为下载所用的浏览器或文件管理器允许“安装未知应用”。',
                                ),
                                _Step(
                                  width: width,
                                  number: '3',
                                  title: '叫上朋友，开一局',
                                  body: '设置昵称、选择游戏。同机轮流玩，或创建房间，分享房间码一起加入。',
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        TextButton.icon(
                          onPressed: () => _showInstallHelp(context),
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('下载或安装遇到问题？'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _WidthLimit(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '开局前，你可能想知道',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _Question(
                        title: 'iPhone 可以下载吗？',
                        answer: '目前仅提供 Android APK 下载，iOS 暂未开放下载。APK 无法在 iPhone 或 iPad 上安装。',
                      ),
                      const _Question(
                        title: '需要注册账号吗？需要联网吗？',
                        answer: '无需注册账号，填写昵称即可开始。同机模式可离线游玩；创建或加入联机房间需要网络。口述、动作、哼歌类玩法需要在场互动，或使用自己的语音通话工具。',
                      ),
                      const _Question(
                        title: '以后怎么更新？',
                        answer: 'Android 正式版会在启动后检查更新，也可以在用户中心手动检查。你也可以随时回来下载最新 APK。更新安装由 Android 系统确认，不会静默安装。',
                      ),
                      const _Question(
                        title: '下载按钮打开的是哪里？',
                        answer: '安装包保存在项目的 GitHub Release 中，下载按钮始终指向最新正式版。若下载较慢，可稍后重试，或打开“版本记录”选择对应版本的 party-hub.apk。',
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 38,
                        ),
                        decoration: BoxDecoration(
                          color: blue,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '人齐了，就差你了。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '下一次聚会，从这一局开始。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const _WebLink(
                              url: apkUrl,
                              label: '下载 Android 版',
                              icon: Icons.download_rounded,
                              light: true,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'iOS 暂未开放下载',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              const _WidthLimit(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Wrap(
                    spacing: 28,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '康师傅 · 为朋友间的快乐而做',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      _WebLink(url: releasesUrl, label: '版本记录', plain: true),
                      _WebLink(url: checksumUrl, label: '安装包校验文件', plain: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroText(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('朋友局 · 随时开场', dot: true),
        const SizedBox(height: 24),
        Text(
          '好朋友，就要',
          style: TextStyle(
            fontSize: wide ? 58 : 40,
            fontWeight: FontWeight.w900,
            height: 1.35,
            letterSpacing: -1.5,
          ),
        ),
        Text(
          '玩在一起。',
          style: TextStyle(
            fontSize: wide ? 64 : 46,
            fontWeight: FontWeight.w900,
            height: 1.35,
            color: blue,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '把聚会的冷场，变成全场的笑声。\n26 款聚会游戏，同机玩、联机玩，\n有朋友在，就有好玩的。',
          style: TextStyle(fontSize: 17, height: 1.9, color: muted),
        ),
        const SizedBox(height: 30),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _WebLink(
              url: apkUrl,
              label: '下载 Android 版',
              icon: Icons.download_rounded,
            ),
            _WebLink(
              url: releasesUrl,
              label: '版本记录',
              icon: Icons.north_east_rounded,
              outlined: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '最新正式版 APK · iOS 暂未开放下载',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  void _showInstallHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载与安装帮助'),
        content: const SingleChildScrollView(
          child: Text(
            '下载没有开始？\n在手机的系统浏览器中打开本页，或进入版本记录，点击 Assets 中的 party-hub.apk。\n\n系统不允许安装？\n打开“设置 → 应用 → 特殊应用权限 → 安装未知应用”，为你正在使用的浏览器或文件管理器授权。不同手机的菜单名称可能不同；安装后可以关闭此权限。\n\n仍然安装失败？\n确认设备是 Android，存储空间充足，APK 已完整下载。若提示签名冲突，请先确认旧包来源，不要贸然卸载以免丢失本地数据。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _WidthLimit extends StatelessWidget {
  const _WidthLimit({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 600 ? 22 : 40,
        ),
        child: child,
      ),
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          'assets/app_icon.png',
          width: 44,
          height: 44,
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(width: 12),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '康师傅',
            style: TextStyle(
              fontSize: 21,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '聚会游戏',
            style: TextStyle(fontSize: 10, color: muted, letterSpacing: 2),
          ),
        ],
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label, {this.dot = false});
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (dot) ...[
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
      ],
      Flexible(
        child: Text(
          label,
          style: const TextStyle(
            color: blue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.7,
          ),
        ),
      ),
    ],
  );
}

class _WebLink extends StatelessWidget {
  const _WebLink({
    required this.url,
    required this.label,
    this.icon,
    this.compact = false,
    this.outlined = false,
    this.plain = false,
    this.light = false,
  });
  final String url;
  final String label;
  final IconData? icon;
  final bool compact;
  final bool outlined;
  final bool plain;
  final bool light;

  @override
  Widget build(BuildContext context) => Link(
    uri: Uri.parse(url),
    target: url == apkUrl ? LinkTarget.self : LinkTarget.blank,
    builder: (context, followLink) {
      final contents = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 17 : 20),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label)),
        ],
      );
      if (plain) return TextButton(onPressed: followLink, child: Text(label));
      final style = FilledButton.styleFrom(
        backgroundColor: light
            ? Colors.white
            : (outlined ? Colors.transparent : blue),
        foregroundColor: light || outlined ? blue : Colors.white,
        minimumSize: Size(0, compact ? 44 : 56),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: outlined ? const BorderSide(color: line) : BorderSide.none,
        textStyle: TextStyle(
          fontFamily: 'PartySans',
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w700,
        ),
      );
      return FilledButton(onPressed: followLink, style: style, child: contents);
    },
  );
}

class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 1.08,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(size * .07),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEFF),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: size * .15,
                top: size * .07,
                width: size * .71,
                height: size * .71,
                child: Transform.rotate(
                  angle: -.07,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * .12),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: .19),
                          blurRadius: 44,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(size * .12),
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: size * .015,
                child: Transform.rotate(
                  angle: .1,
                  child: _Sticker(
                    label: '下一局，你来选！',
                    color: const Color(0xFFFFD77D),
                    fontSize: size * .033,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: size * .16,
                child: Transform.rotate(
                  angle: -.1,
                  child: _Sticker(label: '好友已就位', fontSize: size * .036),
                ),
              ),
              Positioned(
                right: size * .02,
                bottom: size * .035,
                child: Transform.rotate(
                  angle: .06,
                  child: _Sticker(label: '快乐，不止一局  ↗', fontSize: size * .034),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Sticker extends StatelessWidget {
  const _Sticker({
    required this.label,
    required this.fontSize,
    this.color = Colors.white,
  });
  final String label;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ink.withValues(alpha: .08)),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: .06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Text(
      label,
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
    ),
  );
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 26),
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: line),
        bottom: BorderSide(color: line),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 20,
        runSpacing: 24,
        children: [
          for (final (value, detail) in [
            ('26 款', '总有一款对胃口'),
            ('同机 / 联机', '在一起，就能玩'),
            ('无需账号', '填个昵称，轻松开局'),
          ])
            SizedBox(
              width: constraints.maxWidth < 600
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 40) / 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.width,
    required this.number,
    required this.tag,
    required this.title,
    required this.description,
    required this.footnote,
    required this.image,
    required this.color,
  });
  final double width;
  final String number;
  final String tag;
  final String title;
  final String description;
  final String footnote;
  final String image;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(number, style: const TextStyle(color: muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              image,
              height: math.min(160, width * .5),
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: muted, fontSize: 14, height: 1.8),
          ),
          const SizedBox(height: 24),
          Text(
            footnote,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.width,
    required this.number,
    required this.title,
    required this.body,
  });
  final double width;
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(color: muted, fontSize: 14, height: 1.9),
        ),
      ],
    ),
  );
}

class _Question extends StatelessWidget {
  const _Question({required this.title, required this.answer});
  final String title;
  final String answer;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(vertical: 8),
      childrenPadding: const EdgeInsets.only(bottom: 24, right: 24),
      expandedAlignment: Alignment.centerLeft,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      children: [
        Text(answer, style: const TextStyle(color: muted, height: 1.9)),
      ],
    ),
  );
}
