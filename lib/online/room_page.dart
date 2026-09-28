import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_style.dart';
import '../game_catalog.dart';
import '../game_surface.dart';
import '../games/create_session.dart';
import '../profile/user_profile.dart';
import 'room_client.dart';
import 'undercover_game_view.dart';
import 'room_invite.dart';
import 'room_scan_page.dart';

class RoomEntryPage extends StatefulWidget {
  const RoomEntryPage({super.key, this.game});
  final PartyGame? game;
  @override
  State<RoomEntryPage> createState() => _RoomEntryPageState();
}

class _RoomEntryPageState extends State<RoomEntryPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final code = TextEditingController();
  bool entering = false;
  String? saveError;
  bool scanning = false;
  @override
  void initState() {
    super.initState();
    name.text = UserProfileScope.read(context)?.nickname ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> enter() async {
    if (entering || !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      entering = true;
      saveError = null;
    });
    final profile = UserProfileScope.read(context);
    try {
      if (profile != null && !await profile.saveNickname(name.text)) {
        if (mounted) {
          setState(() => saveError = profile.storageError);
        }
        return;
      }
      if (!mounted) {
        return;
      }
      final client = RoomClient(
        name: name.text.trim(),
        gameId: widget.game?.id,
        joinCode: code.text.trim(),
      );
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => RoomPage(client: client)),
      );
    } finally {
      if (mounted) {
        setState(() => entering = false);
      }
    }
  }

  Future<void> scan() async {
    if (entering || scanning) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => scanning = true);
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RoomScanPage()),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      scanning = false;
      if (result != null) {
        code.text = result;
      }
    });
    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已识别房间码，确认昵称后点击加入房间')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final game = widget.game;
    final joining = game == null;
    return Scaffold(
      appBar: AppBar(title: Text(joining ? '加入房间' : '创建房间')),
      body: Form(
        key: form,
        child: PageContent(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final artwork = SizedBox(
                    width: 68,
                    height: 68,
                    child: joining
                        ? const PlayerAvatar(index: 2, size: 68)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GameArtwork(game: game, height: 68),
                          ),
                  );
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        joining ? '朋友的邀请' : '即将开局',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        joining ? '快乐，就差你了' : game.name,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 19,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                  if (MediaQuery.textScalerOf(context).scale(16) > 24) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [artwork, const SizedBox(height: 14), details],
                    );
                  }
                  return Row(
                    children: [
                      artwork,
                      const SizedBox(width: 16),
                      Expanded(child: details),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(
              joining ? '扫码或输入房间码，马上与朋友会合。' : '创建后邀请朋友扫码或输入房间码，大家准备好就能开始。',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              enabled: !entering,
              maxLength: 20,
              textInputAction: joining
                  ? TextInputAction.next
                  : TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: UserProfile.validateNickname,
              decoration: const InputDecoration(
                labelText: '你的昵称',
                hintText: '朋友们怎么称呼你',
                counterText: '',
                errorMaxLines: 4,
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '昵称会保存在本机，下次自动填写。',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
            if (joining) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: entering || scanning ? null : scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('扫码加入'),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '六位房间码',
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: code,
                      enabled: !entering,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                          ? null
                          : '请输入完整的 6 位房间码',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: colors.primary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '000000',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20),
                        counterText: '',
                        errorMaxLines: 4,
                      ),
                      onFieldSubmitted: (_) => enter(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '向开房的朋友获取',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (saveError != null) InfoNote(saveError!, error: true),
            FilledButton(
              onPressed: entering ? null : enter,
              child: Text(
                entering
                    ? '正在进入…'
                    : joining
                    ? '加入房间'
                    : '创建房间',
              ),
            ),
            const SizedBox(height: 12),
            const InfoNote(
              '每人使用自己的设备。讨论、口述和动作类玩法，需要面对面或自行语音通话。',
              icon: Icons.chat_bubble_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class RoomPage extends StatefulWidget {
  const RoomPage({super.key, required this.client});
  final RoomClient client;
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  Timer? timer;
  int? displayedSeconds;
  bool exiting = false;
  RoomClient get client => widget.client;
  int? get remainingSeconds {
    final state = client.state;
    final seconds = state?.step?.seconds;
    if (state == null || seconds == null) {
      return null;
    }
    return max(
      0,
      seconds -
          (state.elapsedMs + client.snapshotAge.elapsedMilliseconds) ~/ 1000,
    );
  }

  @override
  void initState() {
    super.initState();
    client.addListener(changed);
    unawaited(client.connect());
    timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && remainingSeconds != displayedSeconds) {
        setState(() {});
      }
    });
  }

  void changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    client.removeListener(changed);
    client.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (client.state?.step == null ||
        client.state!.finished ||
        await confirmExit(context, message: '离开进行中的对局会结束整场游戏，其他朋友将返回准备房间。')) {
      if (mounted) {
        setState(() => exiting = true);
        Navigator.pop(context);
      }
    }
  }

  Future<void> reset() async {
    if (client.state!.finished ||
        await confirmExit(context, message: '结束当前对局，让所有玩家返回准备房间？')) {
      if (mounted) {
        client.send('reset');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = client.state;
    displayedSeconds = remainingSeconds;
    final game = state == null
        ? null
        : plannedGames.firstWhere((game) => game.id == state.gameId);
    final enabled = client.connected && !client.pending;
    final colors = Theme.of(context).colorScheme;
    final dockControls =
        MediaQuery.sizeOf(context).height >= 600 &&
        MediaQuery.textScalerOf(context).scale(16) <= 24;
    final controls = state != null && state.step == null
        ? _RoomControls(
            state: state,
            game: game!,
            connected: client.connected,
            pending: client.pending,
            onReady: () => client.send('ready'),
            onStart: () => client.send('start'),
          )
        : null;
    final undercoverPlaying = game?.id == 'undercover' && state?.step != null;
    final dockGameAction =
        undercoverPlaying &&
        dockControls &&
        state!.undercover?.phase != 'vote' &&
        state.step!.options.length == 1;
    final bottomControls = dockGameAction
        ? Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: enabled
                    ? () => client.send(
                        'action',
                        action: state.step!.options.single.id,
                      )
                    : null,
                child: Text(state.step!.options.single.label),
              ),
            ),
          )
        : dockControls
        ? controls
        : null;
    return PopScope(
      canPop: exiting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(leave());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state == null ? '连接房间' : game!.name),
          actions: [
            if (undercoverPlaying &&
                !state!.finished &&
                state.host == state.seat)
              PopupMenuButton<String>(
                tooltip: '房间操作',
                onSelected: (_) => reset(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'reset',
                    enabled: enabled,
                    child: const Text('结束本局，返回房间'),
                  ),
                ],
              ),
          ],
          leading: IconButton(
            onPressed: leave,
            tooltip: '离开房间',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
        ),
        bottomNavigationBar: bottomControls != null
            ? ColoredBox(
                color: colors.surface,
                child: SafeArea(
                  top: false,
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: bottomControls,
                    ),
                  ),
                ),
              )
            : null,
        body: PageContent(
          children: [
            if (client.connecting) ...[
              const LinearProgressIndicator(),
              const InfoNote('正在连接，稍等一下就好。', icon: Icons.wifi_rounded),
            ],
            if (client.error.isNotEmpty) InfoNote(client.error, error: true),
            if (!client.connected && !client.connecting)
              OutlinedButton.icon(
                onPressed: () => unawaited(client.connect()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新连接'),
              ),
            if (state != null) ...[
              if (undercoverPlaying)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '房间 ${state.code}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                    Icon(
                      client.connected
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      client.connected ? '已连接' : '离线',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Icon(
                      client.connected
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    Text(
                      '你是 ${state.members[state.seat].name} · ${client.connected ? '已连接' : '离线'}',
                    ),
                    if (state.step != null) Text('房间 ${state.code}'),
                  ],
                ),
              if (state.message.isNotEmpty) InfoNote(state.message),
              const SizedBox(height: 20),
              if (state.step == null) ...[
                SurfaceCard(
                  color: colors.secondaryContainer,
                  child: Column(
                    children: [
                      Text(
                        '邀请朋友入局',
                        style: TextStyle(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          state.code,
                          semanticsLabel:
                              '房间码 ${state.code.split('').join(' ')}',
                          style: TextStyle(
                            fontSize: 35,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w800,
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: state.code),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('房间码已复制，发给朋友吧')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('复制房间码'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: !enabled
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    RoomInviteDialog(code: state.code),
                              ),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('邀请二维码'),
                      ),
                    ],
                  ),
                ),
                if (game!.id == 'undercover')
                  UndercoverLobbyView(
                    state: state,
                    enabled: enabled,
                    onSelectModerator: (seat) => client.send(
                      'moderator',
                      input: '$seat',
                      action: state.members[seat].name,
                    ),
                  )
                else ...[
                  SectionHeading(
                    '等朋友，等开场',
                    trailing: '${state.members.length} / ${game.maxPlayers} 人',
                  ),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < state.members.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                PlayerAvatar(index: i),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.members[i].name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        [
                                          if (i == state.seat) '你',
                                          if (i == state.host) '房主',
                                          if (teamGameIds.contains(game.id))
                                            i.isEven ? '橙队' : '蓝队',
                                          if (!state.members[i].online) '离线',
                                        ].join(' · '),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    state.members[i].online
                                        ? state.members[i].ready
                                              ? '已准备'
                                              : '未准备'
                                        : '已离线',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontWeight: state.members[i].ready
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i != state.members.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '开局准备 ${state.members.where((member) => member.online && member.ready).length} / ${max(game.minPlayers, state.members.length)} 人',
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          state.members
                              .where((member) => member.online && member.ready)
                              .length /
                          max(game.minPlayers, state.members.length),
                      minHeight: 6,
                    ),
                  ),
                ],
                if (!dockControls && controls != null) controls,
                const SizedBox(height: 20),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 16),
                  title: const Text('查看本局玩法'),
                  children: [
                    Text(
                      game.rules,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ] else ...[
                if (client.pending && game!.id == 'undercover')
                  const InfoNote('正在同步操作…', icon: Icons.sync_rounded),
                if (game!.id == 'undercover')
                  UndercoverGameView(
                    state: state,
                    enabled: enabled,
                    showActions: !dockGameAction,
                    onAction: (action) => client.send('action', action: action),
                  )
                else ...[
                  if (game.id == 'draw_guess')
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ScoreStrip(
                        names: state.members
                            .map((member) => member.name)
                            .toList(),
                        scores: state.scores,
                      ),
                    )
                  else
                    ScoreStrip(
                      names: state.members
                          .map((member) => member.name)
                          .toList(),
                      scores: state.scores,
                      teamScores: teamGameIds.contains(game.id)
                          ? state.teamScores
                          : null,
                    ),
                  const SizedBox(height: 20),
                  if (client.pending)
                    const InfoNote('正在同步操作…', icon: Icons.sync_rounded),
                  GameSurface(
                    step: state.step!,
                    ink: state.ink,
                    version: game.id == 'draw_guess'
                        ? state.clockRevision
                        : state.revision,
                    canDraw: state.canDraw,
                    enabled: enabled,
                    finished: state.finished,
                    onAction: (action, input) =>
                        client.send('action', action: action, input: input),
                    onInkChanged: () => client.send('ink', ink: state.ink),
                    onInkProgress: game.id == 'draw_guess'
                        ? () => client.send('ink', ink: state.ink)
                        : null,
                    remainingSeconds: displayedSeconds,
                    hideClock: game.id == 'reaction_duel',
                  ),
                  if (!state.finished &&
                      !(game.id == 'draw_guess' && state.step!.drawing) &&
                      state.step!.options.isEmpty &&
                      state.step!.cells.every((cell) => cell.id.isEmpty))
                    const InfoNote(
                      '等待其他玩家操作。公开裁定或回合确认由房主完成。',
                      icon: Icons.hourglass_empty_rounded,
                    ),
                ],
                const SizedBox(height: 20),
                if (state.host == state.seat &&
                    (!undercoverPlaying || state.finished))
                  OutlinedButton(
                    onPressed: enabled ? reset : null,
                    child: Text(state.finished ? '返回房间，再来一局' : '结束本局，返回房间'),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RoomControls extends StatelessWidget {
  const _RoomControls({
    required this.state,
    required this.game,
    required this.connected,
    required this.pending,
    required this.onReady,
    required this.onStart,
  });
  final RoomSnapshot state;
  final PartyGame game;
  final bool connected;
  final bool pending;
  final VoidCallback onReady;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final ready = state.members[state.seat].ready;
    final host = state.seat == state.host;
    final missing = max(0, game.minPlayers - state.members.length);
    final offline = state.members.where((member) => !member.online).length;
    final unready = state.members
        .where((member) => member.online && !member.ready)
        .length;
    final needsModerator =
        game.id == 'undercover' && state.moderatorSeat == null;
    final canStart =
        !needsModerator &&
        game.supportsPlayerCount(state.members.length) &&
        offline == 0 &&
        unready == 0;
    final enabled = connected && !pending;
    final status = !connected
        ? '连接恢复后就能继续准备'
        : pending
        ? '正在同步，请稍候'
        : needsModerator
        ? '请先选择主持人'
        : missing > 0
        ? '再邀请 $missing 人，就能凑齐这一局'
        : offline > 0
        ? '$offline 位朋友暂时离线，等待重新连接'
        : unready > 0
        ? '还有 $unready 人未准备'
        : host
        ? '所有人已准备，好戏可以开场了'
        : '全员已准备，等待房主开局';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(status, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: !enabled
                ? null
                : !ready
                ? onReady
                : host && canStart
                ? onStart
                : null,
            child: Text(
              pending
                  ? '正在同步…'
                  : !ready
                  ? '我准备好了'
                  : host
                  ? '开始游戏'
                  : '已准备，等待房主',
              textAlign: TextAlign.center,
            ),
          ),
          if (ready)
            TextButton(
              onPressed: enabled ? onReady : null,
              child: const Text('取消准备'),
            ),
        ],
      ),
    );
  }
}
