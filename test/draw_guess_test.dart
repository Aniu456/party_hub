import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/app_style.dart';
import 'package:party_hub/game_catalog.dart';
import 'package:party_hub/game_surface.dart';
import 'package:party_hub/games/board_games.dart';
import 'package:party_hub/games/session.dart';
import 'package:party_hub/games/wire.dart';
import 'package:party_hub/online/room_client.dart';
import 'package:party_hub/online/room_page.dart';

import 'drawing_refresh_test.dart' show drawingCanvas;

class DrawingClient extends RoomClient {
  DrawingClient({bool painter = false, this.playerCount = 3})
    : super(name: '小红') {
    connected = true;
    receive(painter: painter);
  }
  final int playerCount;

  @override
  Future<void> connect() async {}

  void receive({bool painter = false, int revision = 1, int clock = 1}) {
    state = RoomSnapshot({
      'room': '123456',
      'gameId': 'draw_guess',
      'seat': painter ? 0 : 1,
      'host': 0,
      'revision': revision,
      'clockRevision': clock,
      'elapsedMs': 15000,
      'finished': false,
      'canDraw': painter,
      'message': '',
      'members': [
        for (var i = 0; i < playerCount; i++)
          {
            'name': i < 3 ? ['小明', '小红', '小蓝'][i] : '玩家${i + 1}',
            'ready': true,
            'online': true,
          },
      ],
      'scores': List.filled(playerCount, 0),
      'teamScores': [0, 0],
      'ink': <Object?>[],
      'step': encodeStep(drawingStep(painter: painter)),
    });
    notifyListeners();
  }
}

GameStep drawingStep({
  bool painter = false,
  List<String> messages = const [],
}) => GameStep(
  title: '小明正在画图',
  body: '',
  drawing: true,
  drawingHint: painter ? '画题：苹果' : '2 个字',
  guessMessages: messages,
  inputLabel: '其他玩家输入猜测',
  seconds: 75,
  options: painter
      ? const [GameOption('end', '结束本轮', actor: 0)]
      : const [GameOption('g1', '提交猜词', actor: 1)],
);

Widget drawingView({
  required Sketch ink,
  bool painter = false,
  int version = 1,
  VoidCallback? onProgress,
  VoidCallback? onChanged,
  void Function(String, String)? onAction,
  List<String> messages = const [],
  Brightness brightness = Brightness.light,
  double textScale = 1,
  double keyboardHeight = 0,
}) => MaterialApp(
  theme: partyTheme(brightness),
  home: Scaffold(
    body: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GameSurface(
            step: drawingStep(painter: painter, messages: messages),
            ink: ink,
            canDraw: painter,
            version: version,
            remainingSeconds: 60,
            onAction: onAction ?? (_, _) {},
            onInkChanged: onChanged ?? () {},
            onInkProgress: onProgress,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('12 人房间的积分横向查看，猜词入口仍在首屏', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = DrawingClient(playerCount: 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: partyTheme(Brightness.light),
        home: RoomPage(client: client),
      ),
    );
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(find.byType(TextField)).dy, lessThan(812));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('真实房间布局首屏可猜词，其他玩家操作不清除草稿', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = DrawingClient();
    await tester.pumpWidget(
      MaterialApp(
        theme: partyTheme(Brightness.light),
        home: RoomPage(client: client),
      ),
    );
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(find.byType(TextField)).dy, lessThan(812));
    await tester.enterText(find.byType(TextField), '苹果');
    client.receive(revision: 2);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '苹果',
    );
    client.receive(revision: 3, clock: 2);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  test('答对只给画者和猜中者加分，所有人猜中才揭晓', () {
    final session = DrawingSession(
      plannedGames.singleWhere((game) => game.id == 'draw_guess'),
      ['画者', '小明', '小红'],
      random: Random(17),
    );
    session.act('next');
    final clock = session.clockRevision;
    final answer = session.words.first;
    session.act('g1', input: answer);
    expect(session.phase, 'draw');
    expect(session.scores, [1, 1, 0]);
    expect(session.clockRevision, clock);
    expect(session.step.guessMessages, ['小明猜对了！']);
    expect(session.step.guessMessages.join(), isNot(contains(answer)));
    expect(() => session.act('g0', input: answer), throwsStateError);
    expect(() => session.act('g1', input: answer), throwsStateError);
    session.act('g2', input: '错误猜测');
    expect(session.phase, 'draw');
    expect(session.step.guessMessages.last, '小红：错误猜测');
    session.act('g2', input: answer);
    expect(session.phase, 'result');
    expect(session.scores, [2, 1, 1]);
    session.act('next');
    expect(session.history, isEmpty);
  });

  test('多色笔迹往返及复制保留颜色，旧黑色数据仍兼容', () {
    final sketch = <List<Point<double>>>[
      [const Point(.1, .2)],
      SketchStroke([const Point(.3, .4)], color: sketchColors[1]),
      SketchStroke([const Point(.5, .6)], color: sketchColors[4]),
    ];
    final decoded = decodeSketch(encodeSketch(sketch));
    expect(decoded, sketch);
    expect((decoded[1] as SketchStroke).color, sketchColors[1]);
    final copied = copySketch(decoded);
    decoded[1].clear();
    expect(copied[1], hasLength(1));
    expect((copied[1] as SketchStroke).color, sketchColors[1]);
    expect(
      () => decodeSketch([
        {'color': 123, 'points': []},
      ]),
      throwsFormatException,
    );
  });

  testWidgets('画者只有画板工具，不显示输入框；抬手前同步当前颜色', (tester) async {
    final ink = <List<Point<double>>>[];
    var progress = 0;
    var finished = 0;
    await tester.pumpWidget(
      drawingView(
        ink: ink,
        painter: true,
        onProgress: () => progress++,
        onChanged: () => finished++,
      ),
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('画题：苹果'), findsOneWidget);
    await tester.tap(find.byTooltip('红色画笔'));
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(drawingCanvas()),
    );
    await gesture.moveBy(const Offset(30, 0));
    // 进度同步节流：间隔内不发送，到点才发送一次。
    await tester.pump(inkProgressInterval - const Duration(milliseconds: 20));
    expect(progress, 0);
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump(const Duration(milliseconds: 20));
    expect(progress, 1);
    expect(finished, 0);
    expect((ink.single as SketchStroke).color, sketchColors[1]);
    await gesture.moveBy(const Offset(30, 10));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(finished, 1);
    expect(progress, 1);
    await tester.tap(find.byTooltip('撤销一笔'));
    await tester.pump();
    expect(ink, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('画板及别人猜词刷新保留草稿，自己提交后清空，切回合清空', (tester) async {
    final ink = <List<Point<double>>>[];
    String? action;
    String? answer;
    void submit(String a, String text) {
      action = a;
      answer = text;
    }

    await tester.pumpWidget(drawingView(ink: ink, onAction: submit));
    await tester.enterText(find.byType(TextField), '苹果');
    ink.add([const Point(.1, .1)]);
    await tester.pumpWidget(
      drawingView(ink: ink, messages: ['小红猜对了！'], onAction: submit),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '苹果',
    );
    await tester.tap(find.byTooltip('提交猜词'));
    await tester.pump();
    expect(action, 'g1');
    expect(answer, '苹果');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), '下一次猜测');
    await tester.pumpWidget(drawingView(ink: [], version: 2));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.byTooltip('红色画笔'), findsNothing);
  });

  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    testWidgets('绘画界面适配 $size、深色大字体和键盘', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        drawingView(
          ink: [],
          painter: true,
          brightness: Brightness.dark,
          textScale: 3.2,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(drawingView(ink: [], keyboardHeight: 300));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(drawingCanvas()).width, greaterThanOrEqualTo(140));
    });
  }
}
