import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'game_catalog.dart';
import 'game_looks.dart';
import 'open_peeps.dart';

export 'game_looks.dart';

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
  final textTheme = base.textTheme.copyWith(
    headlineLarge: TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: scheme.onSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      letterSpacing: -.8,
      color: scheme.onSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    bodyLarge: TextStyle(fontSize: 14, height: 1.55, color: scheme.onSurface),
    bodyMedium: TextStyle(
      fontSize: 13,
      height: 1.5,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  );
  final buttonTextStyle = textTheme.labelLarge?.copyWith(fontSize: 12);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF131A2A) : Colors.white,
    textTheme: textTheme,
    typography: base.typography.copyWith(
      englishLike: base.typography.englishLike.apply(fontSizeDelta: -1),
      dense: base.typography.dense.apply(fontSizeDelta: -1),
      tall: base.typography.tall.apply(fontSizeDelta: -1),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF131A2A) : Colors.white,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: buttonTextStyle,
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: buttonTextStyle,
        minimumSize: const Size(48, 52),
        foregroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: buttonTextStyle,
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF20283B) : const Color(0xFFF7F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      labelStyle: buttonTextStyle,
      shape: const StadiumBorder(),
      showCheckmark: false,
      selectedColor: scheme.primary,
      backgroundColor: scheme.surface,
      side: BorderSide(color: scheme.primary.withValues(alpha: .35)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
      padding: const EdgeInsets.only(top: 22, bottom: 12),
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
      child: SizedBox(
        width: size,
        height: size,
        child: OverflowBox(
          alignment: const Alignment(0, -.35),
          maxWidth: size * 1.5,
          maxHeight: size * 1.5 * 4 / 3,
          child: SizedBox(
            width: size * 1.5,
            height: size * 1.5 * 4 / 3,
            child: PeepPortrait(index: index),
          ),
        ),
      ),
    ),
  );
}

/// Open Peeps 蓝色衣物版本；保留人物的黑色线稿和白色肤色。
class PeepPortrait extends StatelessWidget {
  const PeepPortrait({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      peepAssets[index % peepAssets.length],
      fit: BoxFit.contain,
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
                fontSize: 12,
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
            fontSize: 29,
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
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (social)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: PeepPortrait(index: index),
              )
            else
              Icon(look.icon, size: height * .48, color: partyInk),
            if (social)
              Positioned(
                right: height < 100 ? 5 : 10,
                bottom: height < 100 ? 5 : 10,
                child: Container(
                  padding: EdgeInsets.all(height < 100 ? 5 : 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    look.icon,
                    size: height < 100 ? 16 : 22,
                    color: partyInk,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
