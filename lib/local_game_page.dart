import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'app_style.dart';
import 'game_catalog.dart';
import 'game_surface.dart';
import 'games/board_games.dart';
import 'games/create_session.dart';
import 'games/session.dart';
import 'profile/user_profile.dart';

class LocalSetupPage extends StatefulWidget {
  const LocalSetupPage({super.key, required this.game});
  final PartyGame game;
  @override
  State<LocalSetupPage> createState() => _LocalSetupPageState();
}

class _LocalSetupPageState extends State<LocalSetupPage> {
  final names = <TextEditingController>[];
  final form = GlobalKey<FormState>();
  bool starting = false;
  String? saveError;
  @override
  void initState() {
    super.initState();
    names.addAll(
      List.generate(
        widget.game.minPlayers,
        (i) => TextEditingController(
          text: i == 0 ? UserProfileScope.read(context)?.nickname : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in names) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> start() async {
    if (starting || !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      starting = true;
      saveError = null;
    });
    try {
      final session = createSession(
        widget.game,
        names.map((controller) => controller.text).toList(),
      );
      final profile = UserProfileScope.read(context);
      if (profile != null && !await profile.saveNickname(names.first.text)) {
        if (mounted) {
          setState(() => saveError = profile.storageError);
        }
        return;
      }
      if (!mounted) {
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LocalGamePage(session: session),
        ),
      );
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${error.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('同机开局')),
    body: Form(
      key: form,
      child: PageContent(
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: GameArtwork(game: widget.game, height: 80),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('${playerCountLabel(widget.game)} · 一台设备就能玩'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('先认识一下大家', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('填好昵称，围坐一起。轮到私密回合时，把手机交给对应的朋友。'),
          if (widget.game.id == 'undercover')
            const InfoNote(
              '至少 4 人：1 名主持人 + 3 名玩家。第一位是主持人，可查看全部身份和词语，不参与投票。',
              icon: Icons.visibility_outlined,
            ),
          if (teamGameIds.contains(widget.game.id))
            const InfoNote(
              '按座位交替分为橙队与蓝队，每队至少两人。请按想要的分队顺序填写昵称。',
              icon: Icons.groups_outlined,
            ),
          SectionHeading(
            '入局名单',
            trailing: '${names.length} / ${widget.game.maxPlayers} 人',
          ),
          for (var i = 0; i < names.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: PlayerAvatar(index: i),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: names[i],
                      enabled: !starting,
                      maxLength: 20,
                      textInputAction: i == names.length - 1
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) {
                          return '请填写昵称';
                        }
                        if (names
                                .where((item) => item.text.trim() == name)
                                .length >
                            1) {
                          return '昵称重复了，换一个吧';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '怎么称呼你',
                        labelText:
                            '${widget.game.id == 'undercover'
                                ? i == 0
                                      ? '主持人'
                                      : '玩家 $i'
                                : '玩家 ${i + 1}'}${teamGameIds.contains(widget.game.id)
                                ? i.isEven
                                      ? ' · 橙队'
                                      : ' · 蓝队'
                                : ''}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: !starting && names.length < widget.game.maxPlayers
                    ? () => setState(() => names.add(TextEditingController()))
                    : null,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('增加玩家'),
              ),
              TextButton(
                onPressed: !starting && names.length > widget.game.minPlayers
                    ? () => setState(() => names.removeLast().dispose())
                    : null,
                child: const Text('减少玩家'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (saveError != null) InfoNote(saveError!, error: true),
          FilledButton.icon(
            onPressed: starting ? null : start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(starting ? '正在开局…' : '开始游戏'),
          ),
          const SizedBox(height: 8),
          const Text('私密信息只给本人看，传递手机前记得遮住屏幕。', textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class LocalGamePage extends StatefulWidget {
  const LocalGamePage({super.key, required this.session});
  final GameSession session;
  @override
  State<LocalGamePage> createState() => _LocalGamePageState();
}

class _LocalGamePageState extends State<LocalGamePage>
    with WidgetsBindingObserver {
  late GameSession session;
  final clock = Stopwatch();
  final remaining = ValueNotifier<int?>(null);
  Timer? timer;
  int version = 0;
  bool exiting = false;

  void syncRemaining() {
    final seconds = session.step.seconds;
    final next = seconds == null
        ? null
        : max(0, seconds - clock.elapsed.inSeconds);
    if (remaining.value != next) {
      remaining.value = next;
    }
  }

  @override
  void initState() {
    super.initState();
    session = widget.session;
    clock.start();
    syncRemaining();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || session.finished || !clock.isRunning) {
        return;
      }
      final seconds = session.step.seconds;
      if (seconds != null && clock.elapsedMilliseconds >= seconds * 1000) {
        act('timeout', '');
      } else {
        // 保留 100 ms 的超时检测；秒数变化只通知倒计时子树，不重建整页。
        syncRemaining();
      }
    });
  }

  void act(String action, String input) {
    try {
      final revision = session.clockRevision;
      session.act(action, input: input, elapsed: clock.elapsed);
      if (revision != session.clockRevision) {
        clock.reset();
      }
      setState(() => version++);
      syncRemaining();
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${error.message}')));
    } on StateError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      clock.start();
    } else {
      clock.stop();
      if (session is ReactionSession && !session.finished) {
        (session as ReactionSession).cancelRound();
        clock.reset();
        setState(() => version++);
        syncRemaining();
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    remaining.dispose();
    clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> leave() async {
    if (session.finished || await confirmExit(context)) {
      if (mounted) {
        setState(() => exiting = true);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = session.step;
    return PopScope(
      canPop: exiting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(leave());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${session.game.name} · 同机'),
          leading: IconButton(
            onPressed: leave,
            tooltip: '退出本局',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
        ),
        body: PageContent(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  session.finished ? '本局结束' : '游戏进行中',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '同机 · ${session.count} 人',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ScoreStrip(
              names: session.players,
              scores: session.scores,
              teamScores: teamGameIds.contains(session.game.id)
                  ? session.teamScores
                  : null,
              moderator: session.moderatorSeat,
            ),
            const SizedBox(height: 20),
            if (session.moderatorSeat != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  onPressed: () => showModeratorOverview(
                    context,
                    session.player(session.moderatorSeat!),
                    session.moderatorOverview(session.moderatorSeat!)!,
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('主持人上帝视角'),
                ),
              ),
            GameSurface(
              step: step,
              ink: session.ink,
              version: version,
              canDraw: step.drawing,
              onAction: act,
              onInkChanged: () => setState(() {}),
              remainingClock: remaining,
              hideClock: session is ReactionSession,
              finished: session.finished,
            ),
            if (session.finished) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    session = createSession(session.game, session.players);
                    clock.reset();
                    clock.start();
                    version++;
                  });
                  syncRemaining();
                },
                child: const Text('再来一局'),
              ),
              TextButton(onPressed: leave, child: const Text('返回')),
            ],
          ],
        ),
      ),
    );
  }
}
