import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/game_catalog.dart';
import 'package:party_hub/game_surface.dart';
import 'package:party_hub/games/session.dart';
import 'package:party_hub/games/wire.dart';
import 'package:party_hub/local_game_page.dart';
import 'package:party_hub/online/room_client.dart';
import 'package:party_hub/online/room_page.dart';

RoomSnapshot snapshot({int elapsedMs = 0, int revision = 0}) => RoomSnapshot({
  'room': '123456',
  'gameId': 'number_bomb',
  'seat': 0,
  'host': 0,
  'revision': revision,
  'clockRevision': revision,
  'elapsedMs': elapsedMs,
  'finished': false,
  'canDraw': false,
  'message': '',
  'members': [
    for (final name in ['甲', '乙'])
      {'name': name, 'ready': true, 'online': true},
  ],
  'scores': [0, 0],
  'teamScores': [0, 0],
  'ink': <Object?>[],
  'step': encodeStep(
    GameStep(
      title: '回合 $revision',
      body: '倒计时测试',
      seconds: 30,
      options: const [GameOption('submit', '提交')],
    ),
  ),
});

class ClockClient extends RoomClient {
  ClockClient() : super(name: '甲') {
    state = snapshot();
    connected = true;
  }
  // 保持 snapshotAge 停止，使测试不依赖机器执行速度。
  @override
  Future<void> connect() async {}

  void receive(RoomSnapshot next) {
    state = next;
    notifyListeners();
  }
}

class ExpiredSession extends GameSession {
  ExpiredSession()
    : super(plannedGames.singleWhere((g) => g.id == 'number_bomb'), ['甲', '乙']);
  int timeouts = 0;
  @override
  GameStep buildStep() =>
      GameStep(title: '超时测试', body: '', seconds: timeouts == 0 ? 0 : null);
  @override
  void handle(String action, String input, Duration elapsed) {
    if (action == 'timeout') {
      timeouts++;
      resetClock();
    }
  }
}

void main() {
  testWidgets('联机同一显示秒不重建，到零后也不持续重建', (tester) async {
    final client = ClockClient();
    await tester.pumpWidget(MaterialApp(home: RoomPage(client: client)));
    final first = tester.widget<GameSurface>(find.byType(GameSurface));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.widget<GameSurface>(find.byType(GameSurface)), same(first));
    }
    // 仅推进快照时间，确认定时器仍能刷新显示。
    client.state = snapshot(elapsedMs: 1000);
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      tester.widget<GameSurface>(find.byType(GameSurface)).remainingSeconds,
      29,
    );
    client.state = snapshot(elapsedMs: 30000);
    await tester.pump(const Duration(milliseconds: 250));
    final zero = tester.widget<GameSurface>(find.byType(GameSurface));
    expect(zero.remainingSeconds, 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.widget<GameSurface>(find.byType(GameSurface)), same(zero));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('联机同一秒收到新回合仍立即刷新', (tester) async {
    final client = ClockClient();
    await tester.pumpWidget(MaterialApp(home: RoomPage(client: client)));
    client.receive(snapshot(revision: 1));
    await tester.pump();
    final surface = tester.widget<GameSurface>(find.byType(GameSurface));
    expect(surface.step.title, '回合 1');
    expect(surface.remainingSeconds, 30);
    expect(surface.version, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('同机仍在 100 ms 检测超时且只推进一次', (tester) async {
    final session = ExpiredSession();
    await tester.pumpWidget(MaterialApp(home: LocalGamePage(session: session)));
    await tester.pump(const Duration(milliseconds: 99));
    expect(session.timeouts, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(session.timeouts, 1);
    expect(
      tester.widget<GameSurface>(find.byType(GameSurface)).remainingSeconds,
      isNull,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(session.timeouts, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
