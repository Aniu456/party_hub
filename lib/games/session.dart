import 'dart:collection';
import 'dart:math';

import '../game_catalog.dart';

class GameOption {
  const GameOption(this.id, this.label, {this.actor});
  final String id;
  final String label;
  final int? actor;
}

class BoardCell {
  const BoardCell(this.id, this.label, {this.tone = 0});
  final String id;
  final String label;
  final int tone;
}

/// 坐标归一化到 0–1，避免设备尺寸变化时笔迹错位。
typedef Sketch = List<List<Point<double>>>;

const sketchColors = [
  0xFF222222,
  0xFFE53935,
  0xFFFF9800,
  0xFF2E7D32,
  0xFF3957ED,
  0xFF8E44AD,
];

/// 保留逐笔颜色；普通坐标列表仍按原来的黑色笔迹处理。
class SketchStroke extends ListBase<Point<double>> {
  SketchStroke(Iterable<Point<double>> points, {required this.color})
    : _points = List.of(points);

  final int color;
  final List<Point<double>> _points;

  @override
  int get length => _points.length;
  @override
  set length(int value) => _points.length = value;
  @override
  Point<double> operator [](int index) => _points[index];
  @override
  void operator []=(int index, Point<double> value) => _points[index] = value;
  @override
  void add(Point<double> element) => _points.add(element);
}

class GameStep {
  const GameStep({
    required this.title,
    required this.body,
    this.options = const [],
    this.privateFor,
    this.inputLabel,
    this.seconds,
    this.drawing = false,
    this.sketch,
    this.gallery = const [],
    this.cells = const [],
    this.columns = 5,
    this.controller,
    this.drawingHint,
    this.guessMessages = const [],
  });
  final String title;
  final String body;
  final List<GameOption> options;
  final String? privateFor;
  final String? inputLabel;
  final int? seconds;
  final bool drawing;
  final Sketch? sketch;
  final List<Sketch> gallery;
  final List<BoardCell> cells;
  final int columns;

  /// 联机公开回合的操作玩家；未指定时由房主主持。
  final int? controller;
  final String? drawingHint;
  final List<String> guessMessages;
}

abstract class GameSession {
  GameSession(this.game, List<String> names, {Random? random})
    : players = List.unmodifiable(names.map((name) => name.trim())),
      random = random ?? Random(),
      scores = List.filled(names.length, 0) {
    if (!game.supportsPlayerCount(players.length)) {
      throw ArgumentError(
        '${game.name}需要 ${game.minPlayers}–${game.maxPlayers} 人',
      );
    }
    if (players.any((name) => name.isEmpty) ||
        players.toSet().length != players.length) {
      throw ArgumentError('昵称不能为空或重复');
    }
  }

  final PartyGame game;
  final List<String> players;
  final Random random;
  final List<int> scores;
  final teamScores = [0, 0];
  int round = 1;
  int clockRevision = 0;
  bool finished = false;
  String result = '';
  String notice = '';
  final Sketch ink = [];

  GameStep get step =>
      finished ? GameStep(title: '本局结束', body: result) : buildStep();

  /// 需要独立主持人的游戏返回其座位；其余游戏没有上帝视角。
  int? get moderatorSeat => null;
  String? moderatorOverview(int seat) => null;

  GameStep buildStep();
  void handle(String action, String input, Duration elapsed);

  /// UI 和测试共用的动作入口；不接受当前阶段不可用的动作。
  void act(
    String action, {
    String input = '',
    Duration elapsed = Duration.zero,
  }) {
    if (finished) {
      throw StateError('本局已结束');
    }
    final current = step;
    final valid =
        current.options.any((option) => option.id == action) ||
        current.cells.any((cell) => cell.id == action && cell.id.isNotEmpty) ||
        (action == 'timeout' && current.seconds != null);
    if (!valid) {
      throw StateError('当前阶段无法执行此操作');
    }
    handle(action, input.trim(), elapsed);
  }

  void resetClock() => clockRevision++;
  int get count => players.length;
  String player(int index) => players[index];
  String team(int index) => index == 0 ? '橙队' : '蓝队';
  List<int> members(int index) => [
    for (var i = 0; i < count; i++)
      if (i % 2 == index) i,
  ];

  List<GameOption> picks(Iterable<int> ids, {String prefix = 'p'}) => [
    for (final id in ids) GameOption('$prefix$id', player(id)),
  ];

  String requireText(String text, {int max = 120}) {
    if (text.isEmpty || text.length > max) {
      throw ArgumentError('请输入 1–$max 个字符');
    }
    return text;
  }

  int requireNumber(String text, int minimum, int maximum) {
    final value = int.tryParse(text);
    if (value == null || value < minimum || value > maximum) {
      throw ArgumentError('请输入 $minimum–$maximum 之间的整数');
    }
    return value;
  }

  void finish(String message) {
    finished = true;
    result = message;
  }

  void finishScores({bool teams = false}) {
    final values = teams ? teamScores : scores;
    final highest = values.reduce(max);
    final winners = [
      for (var i = 0; i < values.length; i++)
        if (values[i] == highest) teams ? team(i) : player(i),
    ];
    finish(
      '${winners.join('、')}${winners.length > 1 ? '并列第一' : '获胜'}！\n\n${[for (var i = 0; i < values.length; i++) '${teams ? team(i) : player(i)}：${values[i]} 分'].join('\n')}',
    );
  }
}

const nextOption = GameOption('next', '继续');
const submitOption = GameOption('submit', '提交');
String normalizeAnswer(String text) =>
    text.replaceAll(RegExp(r'\s'), '').toLowerCase();
