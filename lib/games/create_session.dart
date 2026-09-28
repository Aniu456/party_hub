import 'dart:math';

import '../game_catalog.dart';
import 'board_games.dart';
import 'quick_games.dart';
import 'role_games.dart';
import 'session.dart';

GameSession createSession(
  PartyGame game,
  List<String> players, {
  Random? random,
}) {
  return switch (game.id) {
    'undercover' ||
    'werewolf' => DeductionSession(game, players, random: random),
    'avalon' => AvalonSession(game, players, random: random),
    'draw_guess' ||
    'drawing_telephone' => DrawingSession(game, players, random: random),
    'number_bomb' => NumberBombSession(game, players, random: random),
    'seven_pass' => SevenSession(game, players, random: random),
    'quiz' => QuizSession(game, players, random: random),
    'word_chain' ||
    'category_relay' ||
    'memory_relay' => RelaySession(game, players, random: random),
    'minority_choice' ||
    'know_your_friends' ||
    'two_truths_one_lie' ||
    'same_answer' => SecretAnswerSession(game, players, random: random),
    'charades' ||
    'taboo' ||
    'hum_guess' ||
    'who_am_i' ||
    'lateral_thinking' => PromptSession(game, players, random: random),
    'team_estimation' => EstimationSession(game, players, random: random),
    'puzzle_race' => PuzzleSession(game, players, random: random),
    'gomoku' => GomokuSession(game, players, random: random),
    'reaction_duel' => ReactionSession(game, players, random: random),
    'spy_codes' => SpyCodesSession(game, players, random: random),
    'blind_maze' => MazeSession(game, players, random: random),
    _ => throw ArgumentError('未实现的游戏：${game.id}'),
  };
}

const teamGameIds = {
  'charades',
  'taboo',
  'hum_guess',
  'category_relay',
  'same_answer',
  'spy_codes',
  'team_estimation',
  'puzzle_race',
  'blind_maze',
};
