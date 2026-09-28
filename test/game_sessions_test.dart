import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/game_catalog.dart';
import 'package:party_hub/games/board_games.dart';
import 'package:party_hub/games/create_session.dart';
import 'package:party_hub/games/quick_games.dart';
import 'package:party_hub/games/role_games.dart';
import 'package:party_hub/games/session.dart';
import 'package:party_hub/games/wire.dart';

GameSession sessionFor(String id, {int? count}) {
  final game = plannedGames.singleWhere((game) => game.id == id);
  return createSession(
    game,
    List.generate(count ?? game.minPlayers, (i) => '玩家${i + 1}'),
    random: Random(17),
  );
}

/// 用各自真实规则推进到结算，而不是把所有游戏视为同一个「下一步」。
void complete(GameSession session) {
  var actions = 0;
  while (!session.finished && actions++ < 1500) {
    switch (session) {
      case NumberBombSession():
        session.act('submit', input: '${session.target}');
      case SevenSession():
        session.act(session.mustPass ? 'pass' : 'number');
      case QuizSession():
        if (session.reveal) {
          session.act('next');
        } else if (session.answering == null) {
          session.act('buzz0');
        } else {
          session.act('a${session.questions[session.index].correct}');
        }
      case RelaySession():
        if (session.teams) {
          if (session.reviewing) {
            session.act('accept');
          } else {
            session.act('submit', input: '类别${session.round}');
          }
        } else {
          session.act('giveup');
        }
      case SecretAnswerSession():
        if (session.reveal) {
          session.act('next');
        } else if (session.truth) {
          if (session.statements.isEmpty) {
            session.act('submit', input: '真事一\n假事\n真事二');
          } else {
            session.act('2');
          }
        } else if (session.minority) {
          session.act(session.turn == 0 ? 'a' : 'b');
        } else {
          session.act('submit', input: '苹果');
        }
      case PromptSession():
        if (!session.playing) {
          session.act('next');
        } else if (session.soup) {
          session.act('solved');
        } else if (session.identity) {
          session.act('correct');
        } else {
          session.act('correct');
          session.act('timeout');
        }
      case EstimationSession():
        if (session.reveal) {
          session.act('next');
        } else {
          session.act(
            'submit',
            input: '${session.quantity + (session.turn == 0 ? 0 : 2)}',
          );
        }
      case PuzzleSession():
        if (!session.started) {
          session.act('next');
        } else {
          session.act(
            'submit',
            input: session.deck[session.index].$2,
            elapsed: const Duration(seconds: 20),
          );
        }
      case DrawingSession():
        if (session.telephone) {
          if (session.turn.isOdd) {
            session.ink.add([const Point(0.1, 0.1), const Point(0.9, 0.9)]);
            session.act('submit');
          } else {
            session.act('submit', input: '苹果');
          }
        } else if (session.phase != 'draw') {
          session.act('next');
        } else {
          final guesser = List.generate(session.count, (i) => i).firstWhere(
            (i) => i != session.turn && !session.correct.contains(i),
          );
          session.act(
            'g$guesser',
            input: session.words[session.turn % session.words.length],
          );
        }
      case GomokuSession():
        final move = session.turn == 0
            ? session.board.take(15).where((v) => v == 1).length
            : 15 + session.board.skip(15).take(15).where((v) => v == 2).length;
        session.act('c$move');
      case ReactionSession():
        if (session.phase == 'ready') {
          session.act('next');
        } else if (session.phase == 'wait') {
          session.act('timeout');
        } else {
          session.act('p0', elapsed: const Duration(milliseconds: 150));
        }
      case SpyCodesSession():
        if (session.cluePhase) {
          session.act('submit', input: '自然 8');
        } else {
          final id = List.generate(25, (i) => i).firstWhere(
            (i) =>
                session.owners[i] == session.turn &&
                !session.revealed.contains(i),
          );
          session.act('c$id');
        }
      case MazeSession():
        if (session.phase == 'map') {
          session.act('next');
        } else {
          final paths = <int, List<int>>{session.position: []};
          final queue = [session.position];
          for (var q = 0; q < queue.length && !paths.containsKey(70); q++) {
            final current = queue[q];
            for (final offset in [-9, 9, -1, 1]) {
              final next = current + offset;
              if (next < 0 ||
                  next >= 81 ||
                  session.walls[next] ||
                  paths.containsKey(next)) {
                continue;
              }
              paths[next] = [...paths[current]!, offset];
              queue.add(next);
            }
          }
          final offset = paths[70]!.first;
          session.act(switch (offset) {
            -9 => 'up',
            9 => 'down',
            -1 => 'left',
            _ => 'right',
          }, elapsed: const Duration(seconds: 30));
        }
      case DeductionSession():
        if (session.phase == 'night') {
          final target = session.bad.contains(session.actor)
              ? session.alive.firstWhere((i) => !session.bad.contains(i))
              : session.actor == session.seer
              ? session.alive.firstWhere(session.bad.contains)
              : session.alive.firstWhere((i) => !session.bad.contains(i));
          session.act('p$target');
        } else if (session.phase == 'vote') {
          final target = session.alive.firstWhere(session.bad.contains);
          session.act(target == session.actor ? 'abstain' : 'p$target');
        } else {
          session.act('next');
        }
      case AvalonSession():
        switch (session.phase) {
          case 'propose':
            for (var i = 0; i < session.teamSize; i++) {
              session.act('p$i');
            }
            session.act('submit');
          case 'approve':
            session.act('yes');
          case 'mission':
            session.act('success');
          case 'assassinate':
            session.act(
              'p${List.generate(session.count, (i) => i).firstWhere((i) => !session.evil.contains(i) && i != session.merlin)}',
            );
          default:
            session.act('next');
        }
    }
    // 所有阶段都能通过网络协议往返，包括画作与棋盘。
    final view = decodeStep(encodeStep(session.step));
    expect(view.title, session.step.title);
  }
  expect(session.finished, isTrue, reason: '${session.game.name}未能在限制内结算');
  expect(session.result, isNotEmpty);
  expect(() => session.act('next'), throwsStateError);
}

void main() {
  for (final game in plannedGames) {
    test('${game.name}：最少人数完整对局并结算', () => complete(sessionFor(game.id)));
    test(
      '${game.name}：最多人数完整对局并结算',
      () => complete(sessionFor(game.id, count: game.maxPlayers)),
    );
  }
  test('开局校验真实名单及各游戏人数，不依赖 assert', () {
    expect(() => sessionFor('undercover', count: 3), throwsArgumentError);
    expect(() => sessionFor('gomoku', count: 3), throwsArgumentError);
    expect(
      () => createSession(plannedGames.first, ['甲', '甲', '乙', '丙']),
      throwsArgumentError,
    );
    expect(
      () => createSession(plannedGames.first, ['甲', '', '乙', '丙']),
      throwsArgumentError,
    );
  });
  test('四人卧底局是主持人加三名玩家，主持人不拿词不投票', () {
    final s = sessionFor('undercover') as DeductionSession;
    expect(s.moderatorSeat, 0);
    expect(s.role(0), '主持人');
    expect(s.alive, [1, 2, 3]);
    expect(s.bad.length, 1);
    expect(s.bad.contains(0), isFalse);
    expect(s.step.privateFor, '玩家2');
    expect(s.moderatorOverview(0), contains('卧底'));
    expect(s.moderatorOverview(1), isNull);
    for (var i = 0; i < 6; i++) {
      s.act('next');
    }
    expect(s.phase, 'vote');
    expect(s.step.options.any((option) => option.id == 'p0'), isFalse);
    expect(s.actor, isNot(0));
  });
  test('数字炸弹缩小范围，无效输入不改变状态', () {
    final s = sessionFor('number_bomb') as NumberBombSession;
    final low = s.low;
    expect(() => s.act('submit', input: '101'), throwsArgumentError);
    expect(s.low, low);
    final guess = s.target == 1 ? 100 : 1;
    s.act('submit', input: '$guess');
    expect(s.low <= s.target && s.target <= s.high, isTrue);
    expect(s.turn, 1);
  });
  test('逢七过错误扣分，正确不扣分', () {
    final s = sessionFor('seven_pass') as SevenSession;
    s.act('pass');
    expect(s.scores[0], -1);
    s.act('number');
    expect(s.scores[1], 0);
  });
  test('五子棋不能覆盖落子、不能越界，五连后停止', () {
    final s = sessionFor('gomoku');
    s.act('c0');
    expect(() => s.act('c0'), throwsStateError);
    expect(() => s.act('c225'), throwsStateError);
  });
  test('反应力抢跑由对手得分', () {
    final s = sessionFor('reaction_duel') as ReactionSession;
    s.act('next');
    s.act('p0');
    expect(s.scores, [0, 1]);
    expect(s.phase, 'ready');
  });
  test('谁是卧底平票二次投票仍平票则不淘汰', () {
    final s = sessionFor('undercover') as DeductionSession;
    for (var i = 0; i < 6; i++) {
      s.act('next');
    }
    for (final action in ['p2', 'p1', 'abstain']) {
      s.act(action);
    }
    expect(s.secondVote, isTrue);
    expect(s.alive.length, 3);
    s.act('next');
    s.act('next');
    for (final action in ['p2', 'p1', 'abstain']) {
      s.act(action);
    }
    expect(s.phase, 'result');
    expect(s.alive.length, 3);
  });
  test('谍报暗号陷阱立即判负', () {
    final s = sessionFor('spy_codes') as SpyCodesSession;
    s.act('submit', input: '自然 1');
    s.act('c${s.owners.indexOf(-2)}');
    expect(s.finished, isTrue);
    expect(s.result, contains('蓝队获胜'));
  });
  test('少数派全员一致不加分', () {
    final s = sessionFor('minority_choice') as SecretAnswerSession;
    for (var i = 0; i < s.count; i++) {
      s.act('a');
    }
    expect(s.scores, everyElement(0));
  });
  test('两真一假必须三句，答案不会出现在投票界面', () {
    final s = sessionFor('two_truths_one_lie') as SecretAnswerSession;
    expect(() => s.act('submit', input: '只有一句'), throwsArgumentError);
    s.act('submit', input: '甲\n乙\n丙');
    s.act('2');
    expect(s.step.body, '1. 甲\n2. 乙\n3. 丙');
    expect(s.step.privateFor, '玩家2');
  });
  test('画板协议拒绝越界、非有限坐标及错误结构', () {
    for (final data in [
      null,
      [
        [
          [1.1, 0],
        ],
      ],
      [
        [
          [double.nan, 0],
        ],
      ],
      [
        [
          ['x', 0],
        ],
      ],
    ]) {
      expect(() => decodeSketch(data), throwsFormatException);
    }
  });
  test('协议错误字段报告格式异常', () {
    expect(() => decodeStep({'title': 2}), throwsFormatException);
  });
}
