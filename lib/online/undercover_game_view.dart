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
    this.showActions = true,
  });

  final RoomSnapshot state;
  final bool enabled;
  final ValueChanged<String> onAction;
  final bool showActions;

  @override
  State<UndercoverGameView> createState() => _UndercoverGameViewState();
}

class _UndercoverGameViewState extends State<UndercoverGameView> {
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
        Row(
          children: [
            PlayerAvatar(index: state.seat, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${state.members[state.seat].name} · ${moderator
                    ? '主持人'
                    : active
                    ? '玩家'
                    : '已出局'}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
            Text('第 ${game.round} 轮', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 16),
        Text(phaseTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 10),
        if (game.phase == 'talk')
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.primary, width: 2)),
            ),
            child: Text(step.body, style: theme.textTheme.bodyMedium),
          ),
        const SizedBox(height: 24),
        if (!moderator && state.ownWord != null && !state.finished) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.primary.withValues(alpha: .35)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '我的词语',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.ownWord!,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (moderator) ...[
          Text('全部身份 · 仅主持人可见', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (var i = 0; i < game.roles.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _RoleRow(role: game.roles[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (game.phase == 'vote') ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  moderator || voted || !active ? '投票进度' : '选出你怀疑的人',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${game.voted.length} / ${game.alive.length} 已投',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            moderator
                ? '等所有在场玩家提交后，自动统计结果。'
                : !active
                ? '你已出局，可以继续观看这一局。'
                : voted
                ? '投票已提交，等大家一起揭晓。'
                : '点击玩家提交，投票后不能更改。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (step.options.isNotEmpty)
            _PlayerGrid(
              children: [
                for (final option in step.options.where(
                  (o) => o.id != 'abstain',
                ))
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: colors.primary.withValues(alpha: .4),
                      ),
                    ),
                    onPressed: widget.enabled
                        ? () => widget.onAction(option.id)
                        : null,
                    child: Column(
                      children: [
                        if (int.tryParse(
                              option.id.replaceFirst(RegExp(r'^p'), ''),
                            )
                            case final int seat)
                          PlayerAvatar(index: seat, size: 42)
                        else
                          const Icon(Icons.person_outline_rounded, size: 42),
                        const SizedBox(height: 10),
                        Text(option.label, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
              ],
            )
          else
            _PlayerGrid(
              children: [
                for (final seat in game.alive)
                  _PlayerTile(
                    seat: seat,
                    name: state.members[seat].name,
                    status: game.voted.contains(seat) ? '已投票' : '待投票',
                    highlighted: game.voted.contains(seat),
                  ),
              ],
            ),
          for (final option in step.options.where((o) => o.id == 'abstain'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: widget.enabled
                    ? () => widget.onAction(option.id)
                    : null,
                child: Text(option.label),
              ),
            ),
        ] else if (game.phase == 'talk' && !moderator) ...[
          Row(
            children: [
              Expanded(child: Text('本局玩家', style: theme.textTheme.titleMedium)),
              Text(
                '${game.alive.length} 人在场',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PlayerGrid(
            children: [
              for (final seat in players)
                _PlayerTile(
                  seat: seat,
                  name:
                      '${state.members[seat].name}${seat == state.seat ? '（你）' : ''}',
                  status: !game.alive.contains(seat)
                      ? '已出局'
                      : !state.members[seat].online
                      ? '离线'
                      : '场上',
                  highlighted: seat == state.seat,
                ),
            ],
          ),
        ] else if (game.phase != 'talk') ...[
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Text(step.body, style: theme.textTheme.bodyLarge),
          ),
        ],
        if (widget.showActions &&
            game.phase != 'vote' &&
            step.options.isNotEmpty) ...[
          const SizedBox(height: 24),
          for (final option in step.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton(
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

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.role});
  final UndercoverRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlayerAvatar(index: role.seat, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      role.role,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      role.alive ? '场上' : '已出局',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              '词语：${role.word}',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerGrid extends StatelessWidget {
  const _PlayerGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
      final columns = (constraints.maxWidth / (104 * scale)).floor().clamp(
        1,
        3,
      );
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.seat,
    required this.name,
    required this.status,
    required this.highlighted,
  });
  final int seat;
  final String name;
  final String status;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? theme.colorScheme.primary.withValues(alpha: .4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          PlayerAvatar(index: seat, size: 40),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(status, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
