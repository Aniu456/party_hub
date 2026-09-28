import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/game_catalog.dart';
import 'package:party_hub/games/create_session.dart';
import 'package:party_hub/local_game_page.dart';

void main() {
  for (final game in plannedGames) {
    testWidgets('${game.name}在手机尺寸可打开并展示真实操作', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = createSession(
        game,
        List.generate(game.minPlayers, (i) => '玩家${i + 1}'),
        random: Random(17),
      );
      await tester.pumpWidget(
        MaterialApp(home: LocalGamePage(session: session)),
      );
      if (session.step.privateFor != null) {
        await tester.tap(find.text('我是本人，查看'));
        await tester.pump();
      }
      expect(find.text(session.step.title), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('谁是卧底提交后遮住下一人的词语', (tester) async {
    final game = plannedGames.first;
    final session = createSession(game, [
      '甲',
      '乙',
      '丙',
      '丁',
    ], random: Random(17));
    await tester.pumpWidget(MaterialApp(home: LocalGamePage(session: session)));
    expect(find.textContaining('你的词语：'), findsNothing);
    await tester.tap(find.text('我是本人，查看'));
    await tester.pump();
    expect(find.textContaining('你的词语：'), findsOneWidget);
    await tester.tap(find.text('继续'));
    await tester.pump();
    expect(find.text('请交给 丙'), findsOneWidget);
    expect(find.text('主持人上帝视角'), findsOneWidget);
    expect(find.textContaining('你的词语：'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
