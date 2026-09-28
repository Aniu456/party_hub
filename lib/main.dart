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
                                ? colors.surface
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.casino_outlined,
                  color: colors.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '康师傅',
                  style: Theme.of(context).textTheme.titleLarge,
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
                icon: const PlayerAvatar(index: 0, size: 34),
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
                labelText: '搜索游戏',
                hintText: '试试「你画我猜」',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => query = value.trim()),
            ),
            const SizedBox(height: 16),
          ],
          if (!searching) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: partyMist,
                borderRadius: BorderRadius.circular(24),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LET’S PLAY TOGETHER',
                            style: TextStyle(
                              color: partyInk,
                              fontSize: 10,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '好朋友，\n来一局。',
                            style: TextStyle(
                              color: partyInk,
                              fontSize: 30,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${plannedGames.length} 款游戏 · 快乐不重样',
                            style: const TextStyle(
                              color: partyInk,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (constraints.maxWidth >= 280 &&
                        MediaQuery.textScalerOf(context).scale(16) < 24)
                      const SizedBox(
                        width: 130,
                        height: 150,
                        child: Center(child: PartyIllustration()),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const RoomEntryPage(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          color: colors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '朋友已经开好房间？',
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '输入房间码加入',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          SectionHeading(
            searching ? '找一局好玩的' : '今天玩什么',
            trailing: '${games.length} 款游戏',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: choosePlayerCount,
              icon: const Icon(Icons.people_outline_rounded, size: 20),
              label: Text(partySize == null ? '按人数挑游戏' : '$partySize 人可玩'),
            ),
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
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      labelStyle: TextStyle(
                        color: category == item
                            ? colors.surface
                            : colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => category = item),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (games.isEmpty)
            SurfaceCard(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 40),
                  SizedBox(height: 12),
                  Text('暂时没找到这个游戏'),
                  SizedBox(height: 8),
                  const Text('换个名字、人数或分类，再找找看。'),
                  TextButton(
                    onPressed: resetFilters,
                    child: const Text('重置筛选'),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText =
                  MediaQuery.textScalerOf(context).scale(16) >= 24;
              final columns = largeText
                  ? 1
                  : constraints.maxWidth > 650
                  ? 3
                  : 2;
              final width =
                  (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  for (final game in games)
                    SizedBox(
                      width: width,
                      child: _GameCard(game: game),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            '两个人也好，一群人也好。\n总有一局，适合现在的你们。',
            textAlign: TextAlign.center,
          ),
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
    return Semantics(
      button: true,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => GameDetailPage(game: game)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameArtwork(game: game),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        playerCountLabel(game),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
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
          GameArtwork(game: game, height: 168),
          const SizedBox(height: 24),
          Text(game.name, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            look.teaser,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailTag(Icons.people_outline_rounded, playerCountLabel(game)),
              const _DetailTag(Icons.wifi_rounded, '支持联机'),
              const _DetailTag(Icons.smartphone_rounded, '可同机玩'),
            ],
          ),
          const SectionHeading('怎么玩'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.rules, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                const Divider(height: 1),
                InfoNote(
                  game.id == 'undercover'
                      ? '至少 1 名主持人 + 3 名玩家才能开局。'
                      : game.minPlayers == game.maxPlayers
                      ? '需要 ${game.minPlayers} 名玩家对战。'
                      : '至少 ${game.minPlayers} 名玩家才能开局。',
                  icon: Icons.people_outline_rounded,
                ),
                if (game.id == 'undercover')
                  const Text('主持人拥有上帝视角，能查看全部身份和词语，不参与拿词、发言和投票。'),
              ],
            ),
          ),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}
