import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/app_style.dart';
import 'package:party_hub/games/session.dart';
import 'package:party_hub/game_surface.dart';
import 'package:party_hub/games/wire.dart';
import 'package:party_hub/online/room_client.dart';
import 'package:party_hub/online/room_page.dart';

RoomSnapshot snapshot({
  int seat = 1,
  int? moderatorSeat = 0,
  GameStep? step,
  String? ownWord,
  String? overview,
  String phase = 'talk',
}) => RoomSnapshot({
  'room': '123456',
  'gameId': 'undercover',
  'seat': seat,
  'host': 1,
  'moderatorSeat': moderatorSeat,
  'revision': 1,
  'clockRevision': 0,
  'elapsedMs': 0,
  'finished': false,
  'canDraw': false,
  'message': '',
  'ownWord': ownWord,
  'moderatorOverview': overview,
  'undercover': step == null
      ? null
      : {
          'phase': phase,
          'round': 1,
          'alive': [1, 2, 3],
          'voted': <int>[],
          'roles': overview == null
              ? <Object>[]
              : [
                  {
                    'seat': 2,
                    'name': '小明',
                    'role': '卧底',
                    'word': '咖啡',
                    'alive': true,
                  },
                ],
        },
  'members': [
    for (final name in ['阿蓝', '房主', '小明', '小白'])
      {'name': name, 'ready': true, 'online': true},
  ],
  'scores': [0, 0, 0, 0],
  'teamScores': [0, 0],
  'ink': <Object?>[],
  'step': step == null ? null : encodeStep(step),
});

class TestRoomClient extends RoomClient {
  TestRoomClient(RoomSnapshot snapshot) : super(name: '测试玩家') {
    state = snapshot;
    connected = true;
  }
  final commands = <(String, String)>[];
  final actions = <String?>[];

  @override
  Future<void> connect() async {}

  @override
  void send(String type, {String? action, String input = '', Sketch? ink}) {
    commands.add((type, input));
    actions.add(action);
  }
}

const waiting = GameStep(title: '自由讨论', body: '大家面对面自由讨论，准备好后由主持人发起投票。');

Future<void> showRoom(WidgetTester tester, TestRoomClient client) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: partyTheme(Brightness.light),
      home: RoomPage(client: client),
    ),
  );
  await tester.pump();
}

void main() {
  test('主持人座位兼容缺省，并拒绝越界座位', () {
    expect(snapshot(moderatorSeat: null).moderatorSeat, isNull);
    expect(() => snapshot(moderatorSeat: 4), throwsFormatException);
  });

  testWidgets('主持人直接看到全部身份，即使自己不是房主', (tester) async {
    await showRoom(
      tester,
      TestRoomClient(snapshot(seat: 0, step: waiting, overview: '小明：卧底 · 咖啡')),
    );
    expect(find.text('全部身份 · 仅主持人可见'), findsOneWidget);
    expect(find.text('词语：咖啡'), findsOneWidget);
    expect(find.byType(GameSurface), findsNothing);
    expect(find.text('主持人上帝视角'), findsNothing);
    expect(find.textContaining('请交给'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('普通房主不展示主持人身份表且自己的词默认隐藏', (tester) async {
    await showRoom(
      tester,
      TestRoomClient(
        snapshot(step: waiting, overview: '不能展示的全员身份', ownWord: '牛奶'),
      ),
    );
    expect(find.text('不能展示的全员身份'), findsNothing);
    expect(find.textContaining('牛奶'), findsNothing);
    await tester.tap(find.text('查看我的词语'));
    await tester.pump();
    expect(find.text('牛奶'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.textContaining('牛奶'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('自由讨论无需看词确认，不显示发言人和倒计时', (tester) async {
    final client = TestRoomClient(snapshot(ownWord: '牛奶', step: waiting));
    await showRoom(tester, client);
    expect(find.text('自由讨论'), findsOneWidget);
    expect(find.textContaining('看词进度'), findsNothing);
    expect(find.textContaining('正在描述'), findsNothing);
    expect(find.textContaining('记住了'), findsNothing);
    expect(find.textContaining('秒'), findsNothing);
    expect(find.text('发起投票'), findsNothing);
    await tester.tap(find.text('查看我的词语'));
    await tester.pump();
    expect(find.text('牛奶'), findsOneWidget);
    expect(client.commands, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('主持人直接发起投票，无需等待玩家逐个确认或发言', (tester) async {
    final client = TestRoomClient(
      snapshot(
        seat: 0,
        overview: '身份',
        step: const GameStep(
          title: '自由讨论',
          body: '面对面讨论',
          options: [GameOption('start_vote', '发起投票')],
        ),
      ),
    );
    await showRoom(tester, client);
    await tester.tap(find.text('发起投票'));
    expect(client.actions, ['start_vote']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('未选主持人不能开局，房主可以指定其他成员', (tester) async {
    final client = TestRoomClient(snapshot(moderatorSeat: null));
    await showRoom(tester, client);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '开始游戏'))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(DropdownButton<int>));
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('小明').last);
    await tester.pumpAndSettle();
    expect(client.commands, [('moderator', '2')]);
    expect(client.actions, ['小明']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('普通成员只看到主持人选择结果，没有修改入口', (tester) async {
    await showRoom(tester, TestRoomClient(snapshot(seat: 2)));
    expect(find.text('本局主持人：阿蓝'), findsOneWidget);
    expect(find.byType(DropdownButton<int>), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('投票卡使用服务端选项标识提交，词语默认隐藏', (tester) async {
    final client = TestRoomClient(
      snapshot(
        phase: 'vote',
        ownWord: '牛奶',
        step: const GameStep(
          title: '投票',
          body: '请投票',
          options: [
            GameOption('choice_2', '投给小明'),
            GameOption('abstain', '弃票'),
          ],
        ),
      ),
    );
    await showRoom(tester, client);
    await tester.tap(find.text('投给小明'));
    expect(client.commands, [('action', '')]);
    expect(client.actions, ['choice_2']);
    expect(find.textContaining('牛奶'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('窄屏大字号下主持人身份和投票界面不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: partyTheme(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2.4)),
          child: child!,
        ),
        home: RoomPage(
          client: TestRoomClient(
            snapshot(seat: 0, step: waiting, overview: '身份'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
