import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/game_catalog.dart';
import 'package:party_hub/main.dart';

void main() {
  test('首批至少二十款游戏，标识唯一且各自遵守人数上下限', () {
    expect(plannedGames.length, greaterThanOrEqualTo(20));
    expect(
      plannedGames.map((game) => game.id).toSet().length,
      plannedGames.length,
    );
    for (final game in plannedGames) {
      expect(game.minPlayers, isPositive);
      expect(game.supportsPlayerCount(0), isFalse);
      expect(game.supportsPlayerCount(game.minPlayers - 1), isFalse);
      expect(game.supportsPlayerCount(game.minPlayers), isTrue);
      expect(game.supportsPlayerCount(game.maxPlayers), isTrue);
      expect(game.supportsPlayerCount(game.maxPlayers + 1), isFalse);
    }
  });

  test('谁是卧底三人不可开局，四人可以', () {
    final game = plannedGames.singleWhere((game) => game.id == 'undercover');
    expect(game.minPlayers, 4);
    expect(game.supportsPlayerCount(3), isFalse);
    expect(game.supportsPlayerCount(4), isTrue);
  });

  test('双人和三人玩法不受全局四人门槛限制', () {
    for (final id in ['draw_guess', 'word_chain', 'number_bomb']) {
      final game = plannedGames.singleWhere((game) => game.id == id);
      expect(game.supportsPlayerCount(2), isTrue, reason: game.name);
    }
    for (final id in [
      'drawing_telephone',
      'minority_choice',
      'two_truths_one_lie',
    ]) {
      final game = plannedGames.singleWhere((game) => game.id == id);
      expect(game.supportsPlayerCount(2), isFalse, reason: game.name);
      expect(game.supportsPlayerCount(3), isTrue, reason: game.name);
    }
  });

  test('双人 PK 必须恰好两人', () {
    for (final id in ['gomoku', 'reaction_duel']) {
      final game = plannedGames.singleWhere((game) => game.id == id);
      expect(game.supportsPlayerCount(1), isFalse);
      expect(game.supportsPlayerCount(2), isTrue);
      expect(game.supportsPlayerCount(3), isFalse);
    }
  });

  testWidgets('大厅可以选择同机和联机玩法', (tester) async {
    await tester.pumpWidget(const PartyHubApp());
    expect(find.text('26 款游戏'), findsOneWidget);
    expect(find.text('输入房间码加入'), findsOneWidget);
    await tester.ensureVisible(find.text('谁是卧底'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('谁是卧底'));
    await tester.pumpAndSettle();
    expect(find.text('至少 1 名主持人 + 3 名玩家才能开局。'), findsOneWidget);
    expect(find.text('同机开局'), findsOneWidget);
    expect(find.text('创建联机房间'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
