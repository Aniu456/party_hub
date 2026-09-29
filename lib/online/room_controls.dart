part of 'room_page.dart';

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
