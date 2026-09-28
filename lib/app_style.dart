import 'package:flutter/material.dart';

import 'game_catalog.dart';

const partyInk = Color(0xFF1C2540);
const partyMist = Color(0xFFEBEFFF);
const partyBlue = Color(0xFF3659E3);

ThemeData partyTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: partyBlue,
    brightness: brightness,
    primary: dark ? const Color(0xFFB5C4FF) : partyBlue,
    onPrimary: dark ? partyInk : Colors.white,
    surface: dark ? const Color(0xFF20283B) : Colors.white,
    onSurface: dark ? const Color(0xFFF3F5FC) : partyInk,
    onSurfaceVariant: dark ? const Color(0xFFBAC3D8) : const Color(0xFF667088),
    secondaryContainer: dark ? const Color(0xFF283557) : partyMist,
    onSecondaryContainer: dark ? partyMist : partyInk,
    outline: dark ? const Color(0xFF8895B2) : const Color(0xFF909BB2),
    outlineVariant: dark ? const Color(0xFF36415A) : const Color(0xFFE6EAF2),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    scaffoldBackgroundColor: dark
        ? const Color(0xFF131A2A)
        : const Color(0xFFF6F8FC),
    textTheme: base.textTheme.copyWith(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -.8,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: scheme.onSurface),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF131A2A) : const Color(0xFFF6F8FC),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: scheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorMaxLines: 3,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      showCheckmark: false,
      selectedColor: scheme.onSurface,
      backgroundColor: scheme.surface,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

/// 页面内容保持适合阅读的宽度，也为底部手势区和键盘留出空间。
class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children, this.maxWidth = 760});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: children,
        ),
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class InfoNote extends StatelessWidget {
  const InfoNote(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.error = false,
  });
  final String text;
  final IconData icon;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: error ? colors.error : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: error ? colors.error : colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) {
    final heading = Text(title, style: Theme.of(context).textTheme.titleLarge);
    final detail = trailing == null
        ? null
        : Text(trailing!, style: Theme.of(context).textTheme.bodyMedium);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: MediaQuery.textScalerOf(context).scale(16) > 24
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, ?detail],
            )
          : Row(
              children: [
                Expanded(child: heading),
                ?detail,
              ],
            ),
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.index, this.size = 44});
  final int index;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipOval(
      child: ColoredBox(
        color: const [
          Color(0xFFFFE4D7),
          Color(0xFFE5ECFF),
          Color(0xFFDDF3EB),
          Color(0xFFFFEFC6),
        ][index % 4],
        child: SizedBox(
          width: size,
          height: size,
          child: OverflowBox(
            alignment: const Alignment(0, -.6),
            maxWidth: size * 2.3,
            maxHeight: size * 2.3 * 4 / 3,
            child: SizedBox(
              width: size * 2.3,
              height: size * 2.3 * 4 / 3,
              child: PeepPortrait(index: index),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pablo Stanley 的 Open Peeps 原始插画，随包离线加载。
class PeepPortrait extends StatelessWidget {
  const PeepPortrait({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/open_peeps/peep_${(index % 12).toString().padLeft(2, '0')}.png',
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    ),
  );
}

class ScoreStrip extends StatelessWidget {
  const ScoreStrip({
    super.key,
    required this.names,
    required this.scores,
    this.teamScores,
    this.moderator,
  });
  final List<String> names;
  final List<int> scores;
  final List<int>? teamScores;
  final int? moderator;
  @override
  Widget build(BuildContext context) {
    final teams = teamScores;
    if (teams != null && teams.length == 2) {
      return Row(
        children: [
          Expanded(
            child: _TeamScore(label: '橙队', score: teams[0], orange: true),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: _TeamScore(label: '蓝队', score: teams[1], orange: false),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < names.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              '${names[i]}  ${moderator == i
                  ? '主持人'
                  : i < scores.length
                  ? '${scores[i]} 分'
                  : '—'}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.label,
    required this.score,
    required this.orange,
  });
  final String label;
  final int score;
  final bool orange;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    decoration: BoxDecoration(
      color: orange ? const Color(0xFFFFEADB) : partyMist,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: partyInk, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: const TextStyle(
            color: partyInk,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

String playerCountLabel(PartyGame game) => game.minPlayers == game.maxPlayers
    ? '${game.minPlayers} 人'
    : '${game.minPlayers}–${game.maxPlayers} 人';

/// 仅用于展示；玩法与服务端协议不依赖 UI 分类。
class GameLook {
  const GameLook(this.category, this.teaser, this.icon, this.color);
  final String category;
  final String teaser;
  final IconData icon;
  final Color color;
}

const _peach = Color(0xFFF3D6C3);
const _green = Color(0xFFDDE8C9);
const _blue = Color(0xFFDCE6F2);
const _lilac = Color(0xFFE6DDF0);
const _yellow = Color(0xFFF4E5AD);
const gameLooks = <String, GameLook>{
  'undercover': GameLook(
    '推理社交',
    '藏好你的词，找出那个人',
    Icons.theater_comedy_outlined,
    _peach,
  ),
  'draw_guess': GameLook('创意表演', '画技不重要，脑洞才重要', Icons.draw_outlined, _green),
  'drawing_telephone': GameLook(
    '创意表演',
    '传到最后，还认得出吗',
    Icons.auto_fix_high_outlined,
    _lilac,
  ),
  'werewolf': GameLook('推理社交', '天黑请闭眼，好戏刚开场', Icons.nightlight_outlined, _blue),
  'avalon': GameLook('推理社交', '信任，是最难的一次选择', Icons.shield_outlined, _lilac),
  'lateral_thinking': GameLook(
    '推理社交',
    '一个故事，无数种可能',
    Icons.psychology_alt_outlined,
    _green,
  ),
  'who_am_i': GameLook('推理社交', '所有人都知道，除了你', Icons.face_outlined, _yellow),
  'charades': GameLook(
    '团队合作',
    '你的动作，队友的脑洞',
    Icons.accessibility_new_rounded,
    _peach,
  ),
  'taboo': GameLook(
    '团队合作',
    '那个词，就差说出口了',
    Icons.voice_over_off_outlined,
    _lilac,
  ),
  'hum_guess': GameLook('团队合作', '一段旋律，谁先听懂', Icons.music_note_outlined, _green),
  'word_chain': GameLook('轻松破冰', '接住朋友的最后一个字', Icons.link_rounded, _yellow),
  'category_relay': GameLook(
    '团队合作',
    '轮到你了，别让灵感断线',
    Icons.sync_alt_rounded,
    _blue,
  ),
  'seven_pass': GameLook(
    '轻松破冰',
    '数到七，把紧张传下去',
    Icons.exposure_plus_1_rounded,
    _peach,
  ),
  'number_bomb': GameLook('轻松破冰', '范围越小，心跳越快', Icons.timer_outlined, _yellow),
  'quiz': GameLook('轻松破冰', '比脑力，也比手速', Icons.bolt_outlined, _green),
  'minority_choice': GameLook(
    '轻松破冰',
    '这次，少数人说了算',
    Icons.call_split_rounded,
    _lilac,
  ),
  'know_your_friends': GameLook(
    '轻松破冰',
    '你真的了解身边的朋友吗',
    Icons.favorite_border_rounded,
    _peach,
  ),
  'two_truths_one_lie': GameLook(
    '推理社交',
    '三句话，哪句骗过了你',
    Icons.chat_bubble_outline_rounded,
    _blue,
  ),
  'same_answer': GameLook(
    '团队合作',
    '不用说，也能想到一起',
    Icons.all_inclusive_rounded,
    _lilac,
  ),
  'memory_relay': GameLook('轻松破冰', '一起把记忆叠得更高', Icons.layers_outlined, _green),
  'spy_codes': GameLook('团队合作', '一个暗号，读懂队友', Icons.key_outlined, _yellow),
  'team_estimation': GameLook(
    '团队合作',
    '靠近答案，需要一点默契',
    Icons.straighten_rounded,
    _blue,
  ),
  'puzzle_race': GameLook(
    '团队合作',
    '拼起线索，一起破局',
    Icons.extension_outlined,
    _peach,
  ),
  'blind_maze': GameLook('团队合作', '你指方向，我来走', Icons.route_outlined, _green),
  'gomoku': GameLook('双人 PK', '黑白之间，走好每一步', Icons.grid_4x4_rounded, _yellow),
  'reaction_duel': GameLook(
    '双人 PK',
    '盯紧信号，一触即发',
    Icons.touch_app_outlined,
    _blue,
  ),
};

class GameArtwork extends StatelessWidget {
  const GameArtwork({super.key, required this.game, this.height = 132});
  final PartyGame game;
  final double height;
  @override
  Widget build(BuildContext context) {
    final look = gameLooks[game.id]!;
    final index = plannedGames.indexWhere((item) => item.id == game.id);
    final social = look.category == '推理社交' || look.category == '轻松破冰';
    return ExcludeSemantics(
      child: Container(
        height: height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: look.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -20,
              bottom: -40,
              child: Container(
                width: height * 1.1,
                height: height * 1.1,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .38),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (social)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: PeepPortrait(index: index),
              )
            else
              Icon(look.icon, size: height * .48, color: partyInk),
            if (social)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(look.icon, size: 22, color: partyInk),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PartyIllustration extends StatelessWidget {
  const PartyIllustration({super.key});
  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SizedBox(
      width: 156,
      height: 144,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 12,
            width: 88,
            height: 126,
            child: PeepPortrait(index: 2),
          ),
          Positioned(
            right: 0,
            top: 0,
            width: 96,
            height: 140,
            child: PeepPortrait(index: 1),
          ),
        ],
      ),
    ),
  );
}
