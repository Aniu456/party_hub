import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'game_catalog.dart';
import 'local_game_page.dart';
import 'online/room_page.dart';
import 'profile/user_center_page.dart';
import 'profile/user_profile.dart';
import 'update/app_update.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final profile = UserProfile(SharedPreferencesAsync());
  await profile.load();
  runApp(PartyHubApp(profile: profile));
}

class PartyHubApp extends StatelessWidget {
  const PartyHubApp({super.key, this.profile});
  final UserProfile? profile;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '康师傅',
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: partyTheme(Brightness.light),
    darkTheme: partyTheme(Brightness.dark),
    builder: (context, child) =>
        UserProfileScope(profile: profile, child: child!),
    home: const GameLobbyPage(),
  );
}

class GameLobbyPage extends StatefulWidget {
  const GameLobbyPage({super.key});
  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  String category = '全部';
  int? partySize;
  String query = '';
  bool searching = false;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kReleaseMode && supportsAppUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          checkAppUpdate(context, silently: true);
        }
      });
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> choosePlayerCount() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '今天有几个人？',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('只显示当前人数能开局的游戏。'),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final count in [0, for (var i = 2; i <= 12; i++) i])
                        ChoiceChip(
                          label: Text(count == 0 ? '人数不限' : '$count 人'),
                          selected: (partySize ?? 0) == count,
                          labelStyle: TextStyle(
                            color: (partySize ?? 0) == count
                                ? colors.onPrimary
                                : colors.onSurface,
                          ),
                          onSelected: (_) => Navigator.pop(context, count),
                        ),
                    ],
                  ),
                  const InfoNote('谁是卧底的人数包含 1 名主持人，最少共 4 人。'),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => partySize = selected == 0 ? null : selected);
    }
  }

  void resetFilters() {
    search.clear();
    setState(() {
      query = '';
      category = '全部';
      partySize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profile = UserProfileScope.watch(context);
    final games = plannedGames
        .where(
          (game) =>
              (category == '全部' || gameLooks[game.id]!.category == category) &&
              (partySize == null || game.supportsPlayerCount(partySize!)) &&
              (query.isEmpty ||
                  game.name.contains(query) ||
                  gameLooks[game.id]!.teaser.contains(query)),
        )
        .toList();
    return Scaffold(
      body: PageContent(
        maxWidth: 900,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.nickname.isNotEmpty == true
                          ? '嗨，${profile!.nickname}'
                          : '朋友，欢迎来玩',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '今天玩什么？',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: searching ? '收起搜索' : '搜索游戏',
                onPressed: () => setState(() {
                  searching = !searching;
                  if (!searching) {
                    search.clear();
                    query = '';
                  }
                }),
                icon: Icon(
                  searching ? Icons.close_rounded : Icons.search_rounded,
                ),
              ),
              IconButton(
                tooltip: '用户中心',
                onPressed: profile == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => UserCenterPage(profile: profile),
                        ),
                      ),
                icon: const PlayerAvatar(index: 0, size: 38),
              ),
            ],
          ),
          if (profile?.storageError != null)
            InfoNote(profile!.storageError!, error: true),
          const SizedBox(height: 20),
          if (searching) ...[
            TextField(
              controller: search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: '搜索游戏',
                hintText: '试试「你画我猜」',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除搜索',
                        onPressed: () {
                          search.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (value) => setState(() => query = value.trim()),
            ),
          ] else
            Material(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RoomEntryPage(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        color: colors.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '朋友已经开好房间？',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '输入房间码加入',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                searching ? '搜索结果 · ${games.length}' : '${games.length} 款游戏',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: choosePlayerCount,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(partySize == null ? '按人数挑游戏' : '$partySize 人可玩'),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in [
                  '全部',
                  '推理社交',
                  '团队合作',
                  '创意表演',
                  '轻松破冰',
                  '双人 PK',
                ])
                  Semantics(
                    selected: category == item,
                    button: true,
                    child: InkWell(
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      onTap: () => setState(() => category = item),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: category == item
                                  ? colors.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: category == item
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                fontWeight: category == item
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (games.isEmpty)
            SurfaceCard(
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 36),
                  const SizedBox(height: 12),
                  const Text('暂时没找到这个游戏'),
                  const SizedBox(height: 8),
                  const Text('换个名字、人数或分类，再找找看。'),
                  TextButton(
                    onPressed: resetFilters,
                    child: const Text('重置筛选'),
                  ),
                ],
              ),
            ),
          for (final game in games) ...[
            _GameCard(game: game),
            if (game != games.last)
              Divider(height: 1, color: colors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final PartyGame game;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final look = gameLooks[game.id]!;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => GameDetailPage(game: game)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (MediaQuery.textScalerOf(context).scale(16) < 24) ...[
                  SizedBox(
                    width: 52,
                    child: GameArtwork(game: game, height: 60),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            game.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${playerCountLabel(game)}  ·  ${look.category}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.primary, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        look.teaser,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameDetailPage extends StatelessWidget {
  const GameDetailPage({super.key, required this.game});
  final PartyGame game;
  @override
  Widget build(BuildContext context) {
    final look = gameLooks[game.id]!;
    return Scaffold(
      appBar: AppBar(title: Text(look.category)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LocalSetupPage(game: game),
                        ),
                      ),
                      child: const Text('同机开局', textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RoomEntryPage(game: game),
                        ),
                      ),
                      child: const Text('创建联机房间', textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageContent(
        children: [
          Row(
            children: [
              if (MediaQuery.textScalerOf(context).scale(16) < 24) ...[
                SizedBox(width: 76, child: GameArtwork(game: game, height: 80)),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      look.teaser,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playerCountLabel(game),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _DetailTag(Icons.wifi_rounded, '支持联机'),
              _DetailTag(Icons.smartphone_rounded, '可同机玩'),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SectionHeading('怎么玩'),
          Text(game.rules, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SectionHeading('开局须知'),
          Text(
            game.id == 'undercover'
                ? '至少 1 名主持人 + 3 名玩家才能开局。'
                : game.minPlayers == game.maxPlayers
                ? '需要 ${game.minPlayers} 名玩家对战。'
                : '至少 ${game.minPlayers} 名玩家才能开局。',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (game.id == 'undercover') ...[
            const SizedBox(height: 8),
            const Text('主持人拥有上帝视角，能查看全部身份和词语，不参与拿词、发言和投票。'),
          ],
          const InfoNote('联机时每人使用自己的设备；同机时围坐一起，轮流传递手机。讨论和表演需要面对面或自行语音通话。'),
        ],
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  const _DetailTag(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}
