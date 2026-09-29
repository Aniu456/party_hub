import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/game_surface.dart';
import 'package:party_hub/games/session.dart';
import 'package:party_hub/games/wire.dart';
import 'package:party_hub/online/room_client.dart';
import 'package:party_hub/online/room_page.dart';

import 'drawing_refresh_test.dart' show drawingCanvas;

Map<String, Object?> stateMessage({
  bool painter = false,
  Sketch? ink,
  int elapsedMs = 1000,
  String message = '',
}) => {
  'type': 'state',
  'room': '123456',
  'gameId': 'draw_guess',
  'seat': painter ? 0 : 1,
  'host': 0,
  'revision': 3,
  'clockRevision': 1,
  'elapsedMs': elapsedMs,
  'finished': false,
  'canDraw': painter,
  'message': message,
  'members': [
    for (final name in ['小明', '小红', '小刚'])
      {'name': name, 'ready': true, 'online': true},
  ],
  'scores': [0, 0, 0],
  'teamScores': [0, 0],
  'ink': encodeSketch(ink ?? []),
  'step': encodeStep(
    GameStep(
      title: '小明正在画图',
      body: '',
      drawing: true,
      inputLabel: '其他玩家输入猜测',
      seconds: 75,
      options: painter
          ? const [GameOption('end', '结束本轮', actor: 0)]
          : const [GameOption('g1', '提交猜词', actor: 1)],
    ),
  ),
};

Sketch strokes(int count, {int points = 3}) => [
  for (var s = 0; s < count; s++)
    SketchStroke([
      for (var i = 0; i < points; i++) Point(i / points, s / max(count, 1)),
    ], color: sketchColors[s % sketchColors.length]),
];

class InkClient extends RoomClient {
  InkClient({bool painter = false}) : super(name: '小红') {
    connected = true;
    handleMessage(stateMessage(painter: painter));
  }
  final sent = <Map<String, Object?>>[];

  @override
  Future<void> connect() async {}

  @override
  bool get canTransmit => connected;

  @override
  void transmit(String message) =>
      sent.add(jsonDecode(message) as Map<String, Object?>);
}

Future<void> showRoom(WidgetTester tester, RoomClient client) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: RoomPage(client: client)));
  await tester.pump();
}

void main() {
  testWidgets('仅笔迹变化的回包只重绘画板，不重建整页', (tester) async {
    final client = InkClient();
    await showRoom(tester, client);
    final surface = tester.widget<GameSurface>(find.byType(GameSurface));
    final board = surface.ink;
    var inkSignals = 0;
    client.inkUpdates.addListener(() => inkSignals++);

    await tester.ensureVisible(drawingCanvas());
    await tester.pump();
    final canvas = tester.renderObject(drawingCanvas());
    var paints = 0;
    final previousPaintHook = debugOnProfilePaint;
    debugOnProfilePaint = (object) {
      if (identical(object, canvas)) {
        paints++;
      }
    };
    try {
      client.handleMessage(stateMessage(ink: strokes(2), elapsedMs: 1300));
      await tester.pump();
    } finally {
      debugOnProfilePaint = previousPaintHook;
    }
    expect(paints, greaterThan(0));

    expect(tester.widget<GameSurface>(find.byType(GameSurface)), same(surface));
    expect(identical(client.state!.ink, board), isTrue);
    expect(board.length, 2);
    expect((board[1] as SketchStroke).color, sketchColors[1]);
    expect(inkSignals, 1);
    // 快照时间仍更新，倒计时由页面定时器读取。
    expect(client.state!.elapsedMs, 1300);

    // 其他字段变化仍整页刷新。
    client.handleMessage(stateMessage(ink: strokes(2), message: '小刚猜对了！'));
    await tester.pump();
    expect(
      tester.widget<GameSurface>(find.byType(GameSurface)),
      isNot(same(surface)),
    );
    expect(find.text('小刚猜对了！'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('画者收到自己笔迹的回包不重建页面，保留本机笔迹', (tester) async {
    final client = InkClient(painter: true);
    await showRoom(tester, client);
    final surface = tester.widget<GameSurface>(find.byType(GameSurface));
    final local = client.state!.ink..addAll(strokes(3));
    client.handleMessage(
      stateMessage(painter: true, ink: strokes(1), elapsedMs: 1500),
    );
    await tester.pump();
    expect(tester.widget<GameSurface>(find.byType(GameSurface)), same(surface));
    expect(identical(client.state!.ink, local), isTrue);
    expect(local.length, 3);
    await tester.pumpWidget(const SizedBox());
  });

  test('相同笔迹不重复发送，内容变化或服务器报错后重新发送', () {
    final client = InkClient(painter: true);
    final ink = strokes(1);
    client.send('ink', ink: ink);
    client.send('ink', ink: ink);
    expect(client.sent, hasLength(1));
    expect(client.pending, isFalse);

    ink.first.add(const Point(.9, .9));
    client.send('ink', ink: ink);
    expect(client.sent, hasLength(2));

    client.handleMessage({'type': 'error', 'message': '画作太复杂，请清空重画'});
    client.send('ink', ink: ink);
    expect(client.sent, hasLength(3));

    // 非笔迹操作不受去重影响。
    client.send('action', action: 'end');
    client.send('action', action: 'end');
    expect(client.sent.where((m) => m['type'] == 'action'), hasLength(2));
    client.dispose();
  });

  test('上限规模的多色画作编码往返保持一致', () {
    // 300 笔 × 40 点 = 12000 点，恰为协议上限。
    final sketch = strokes(300, points: 40);
    final decoded = decodeSketch(jsonDecode(jsonEncode(encodeSketch(sketch))));
    expect(decoded, hasLength(300));
    for (var s = 0; s < sketch.length; s++) {
      expect(decoded[s], orderedEquals(sketch[s]));
      expect(
        (decoded[s] as SketchStroke).color,
        (sketch[s] as SketchStroke).color,
      );
    }
    final tooMany = strokes(300, points: 41);
    expect(
      () => decodeSketch(jsonDecode(jsonEncode(encodeSketch(tooMany)))),
      throwsFormatException,
    );
  });
}
