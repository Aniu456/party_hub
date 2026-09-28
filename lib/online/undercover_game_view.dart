import 'package:flutter/material.dart';

import '../app_style.dart';
import 'room_client.dart';

/// 联机卧底的准备区：房主负责房间，主持人独立选择。
class UndercoverLobbyView extends StatelessWidget {
  const UndercoverLobbyView({
    super.key,
    required this.state,
    required this.enabled,
    required this.onSelectModerator,
  });

  final RoomSnapshot state;
  final bool enabled;
  final ValueChanged<int> onSelectModerator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moderator = state.moderatorSeat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('先选一位主持人'),
        Text(
          '主持人查看全部身份，负责发起投票与公布结果，不拿词、不发言、不投票。',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (state.seat == state.host)
          InputDecorator(
            decoration: const InputDecoration(labelText: '本局主持人'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: moderator,
                isExpanded: true,
                hint: const Text('请先选择主持人'),
                items: [
                  for (var i = 0; i < state.members.length; i++)
                    DropdownMenuItem(
                      value: i,
                      enabled: state.members[i].online,
                      child: Text(
                        '${state.members[i].name}${state.members[i].online ? '' : '（离线）'}',
                      ),
                    ),
                ],
                onChanged: enabled
                    ? (seat) {
                        if (seat != null) onSelectModerator(seat);
                      }
                    : null,
              ),
            ),
          )
        else
          Text(
            moderator == null
                ? '等待房主选择主持人'
                : '本局主持人：${state.members[moderator].name}',
            style: theme.textTheme.titleMedium,
          ),
        SectionHeading('本局成员', trailing: '${state.members.length} 人'),
        for (var i = 0; i < state.members.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlayerAvatar(index: i, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.members[i].name}${i == state.seat ? '（你）' : ''}',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        [
                          i == moderator ? '主持人' : '玩家',
                          if (i == state.host) '房主',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    !state.members[i].online
                        ? '已离线'
                        : state.members[i].ready
                        ? '已准备'
                        : '未准备',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: state.members[i].ready && state.members[i].online
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i != state.members.length - 1) const Divider(height: 1),
        ],
        const SizedBox(height: 12),
        Text(
          '至少 4 人：1 名主持人 + 3 名玩家。全员准备后，由房主开局。',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// 只使用服务器按座位过滤后的词语、身份和可用操作。
class UndercoverGameView extends StatefulWidget {
  const UndercoverGameView({
    super.key,
    required this.state,
    required this.enabled,
    required this.onAction,
  });

  final RoomSnapshot state;
  final bool enabled;
  final ValueChanged<String> onAction;

  @override
  State<UndercoverGameView> createState() => _UndercoverGameViewState();
}

class _UndercoverGameViewState extends State<UndercoverGameView>
    with WidgetsBindingObserver {
  bool wordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(UndercoverGameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.ownWord != widget.state.ownWord ||
        oldWidget.state.seat != widget.state.seat) {
      wordVisible = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => wordVisible = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final game = state.undercover;
    final step = state.step!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final moderator = state.seat == state.moderatorSeat;
    if (game == null) {
      return const InfoNote('正在等待游戏状态同步…', icon: Icons.sync_rounded);
    }
    final phaseTitle = switch (game.phase) {
      'talk' => game.tiebreak ? '平票 · 自由讨论' : '自由讨论',
      'vote' => game.tiebreak ? '平票 · 再投一次' : '找出卧底',
      'result' => '投票结果',
      'finished' => '本局结束',
      _ => '正在同步',
    };
    final players = [
      for (var i = 0; i < state.members.length; i++)
        if (i != state.moderatorSeat) i,
    ];
    final voted = game.voted.contains(state.seat);
    final active = game.alive.contains(state.seat);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          moderator
              ? '主持人 · 掌握全局'
              : '${state.members[state.seat].name} · ${active ? '正在参与' : '已出局'}',
          style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(phaseTitle, style: theme.textTheme.headlineSmall),
            Text('第 ${game.round} 轮', style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 20),
        if (moderator) ...[
          const SectionHeading('全部身份 · 仅主持人可见'),
          for (final role in game.roles) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(role.name, style: theme.textTheme.titleMedium),
                      Text(
                        '${role.role} · ${role.alive ? '场上' : '已出局'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('词语：${role.word}', style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
        if (!moderator && state.ownWord != null && !state.finished) ...[
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('我的词语', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (wordVisible)
                  Text(state.ownWord!, style: theme.textTheme.headlineMedium)
                else
                  Text(
                    '仅在你的设备上查看，别让其他玩家看到。',
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() {
                    wordVisible = !wordVisible;
                  }),
                  icon: Icon(
                    wordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(wordVisible ? '收起我的词语' : '查看我的词语'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (game.phase == 'talk') ...[
          const SizedBox(height: 16),
          Text(step.body, style: theme.textTheme.bodyMedium),
          if (!moderator) ...[
            const SizedBox(height: 16),
            Text('本局玩家', style: theme.textTheme.titleMedium),
            for (final seat in players)
              _PlayerStatus(
                name: state.members[seat].name,
                status: game.alive.contains(seat) ? '场上' : '已出局',
                highlighted: false,
              ),
          ],
        ] else if (game.phase == 'vote') ...[
          Text(
            '已投票 ${game.voted.length} / ${game.alive.length}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            moderator
                ? '等所有在场玩家提交后，自动统计结果。'
                : !active
                ? '你已出局，可以继续观看这一局。'
                : voted
                ? '你已提交投票，等待其他玩家。'
                : '谁的描述最可疑？点击一位玩家提交投票。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (step.options.isEmpty)
            for (final seat in game.alive)
              _PlayerStatus(
                name: state.members[seat].name,
                status: game.voted.contains(seat) ? '已投票' : '思考中',
                highlighted: game.voted.contains(seat),
              ),
        ] else ...[
          Text(step.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(step.body, style: theme.textTheme.bodyLarge),
        ],
        if (step.options.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final option in step.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: game.phase == 'vote'
                  ? OutlinedButton(
                      onPressed: widget.enabled
                          ? () => widget.onAction(option.id)
                          : null,
                      child: Text(option.label),
                    )
                  : FilledButton(
                      onPressed: widget.enabled
                          ? () => widget.onAction(option.id)
                          : null,
                      child: Text(option.label),
                    ),
            ),
        ],
      ],
    );
  }
}

class _PlayerStatus extends StatelessWidget {
  const _PlayerStatus({
    required this.name,
    required this.status,
    required this.highlighted,
  });
  final String name;
  final String status;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            status,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: highlighted ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
      ],
    ),
  );
}
