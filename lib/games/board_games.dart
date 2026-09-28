import 'content.dart';
import 'session.dart';

Sketch copySketch(Sketch sketch) => [
  for (final stroke in sketch) List.of(stroke),
];

class DrawingSession extends GameSession {
  DrawingSession(super.game, super.players, {super.random}) {
    words.shuffle(random);
  }
  final words = List.of(drawingWords);
  final correct = <int>{};
  final history = <String>[];
  final pictures = <Sketch>[];
  int turn = 0;
  String phase = 'secret';
  String previousText = '';
  Sketch? previousSketch;
  bool get telephone => game.id == 'drawing_telephone';
  @override
  GameStep get step => finished && telephone
      ? GameStep(title: '传话大揭秘', body: result, gallery: pictures)
      : super.step;
  @override
  GameStep buildStep() {
    if (telephone) {
      final draw = turn.isOdd;
      return GameStep(
        title:
            '${player(turn)} · ${draw
                ? '把文字画出来'
                : turn == 0
                ? '写下开头'
                : '猜上一棒画了什么'}',
        body: draw ? previousText : '只看上一棒，不看更早的内容。',
        privateFor: player(turn),
        drawing: draw,
        sketch: !draw ? previousSketch : null,
        inputLabel: draw ? null : '输入描述',
        seconds: 90,
        options: const [submitOption],
      );
    }
    if (phase == 'secret') {
      return GameStep(
        title: '${player(turn)}查看画题',
        body: '这一轮画：${words[turn % words.length]}\n记住后进入画板，画题将隐藏。',
        privateFor: player(turn),
        options: const [nextOption],
      );
    }
    if (phase == 'result') {
      return GameStep(
        title: '画题揭晓',
        body:
            '答案：${words[turn % words.length]}\n猜中：${correct.isEmpty ? '无人' : correct.map(player).join('、')}',
        sketch: ink,
        options: const [nextOption],
      );
    }
    return GameStep(
      title: '${player(turn)}正在画图',
      body: '画者不能写出答案或拼音。每人猜对加 1 分，画者也加 1 分。\n$notice',
      drawing: true,
      controller: turn,
      inputLabel: '其他玩家输入猜测',
      seconds: 75,
      options: [
        for (var i = 0; i < count; i++)
          if (i != turn && !correct.contains(i))
            GameOption('g$i', '${player(i)}提交猜词', actor: i),
        GameOption('end', '结束本轮', actor: turn),
      ],
    );
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (telephone) {
      if (turn.isOdd) {
        if (ink.isEmpty && action != 'timeout') {
          throw ArgumentError('请先画一点内容');
        }
        previousSketch = copySketch(ink);
        pictures.add(previousSketch!);
        history.add('${player(turn)}：画作 ${pictures.length}');
        ink.clear();
      } else {
        previousText = action == 'timeout'
            ? '（超时未作答）'
            : requireText(input, max: 60);
        history.add('${player(turn)}：$previousText');
      }
      if (++turn == count) {
        finish(history.join('\n'));
      }
      resetClock();
      return;
    }
    if (phase == 'secret') {
      phase = 'draw';
      resetClock();
      return;
    }
    if (phase == 'result') {
      if (++turn == count) {
        finishScores();
        return;
      }
      phase = 'secret';
      correct.clear();
      ink.clear();
      notice = '';
      resetClock();
      return;
    }
    if (action == 'end' || action == 'timeout') {
      phase = 'result';
      resetClock();
      return;
    }
    final guesser = int.parse(action.substring(1));
    if (normalizeAnswer(requireText(input)) == words[turn % words.length]) {
      correct.add(guesser);
      scores[guesser]++;
      scores[turn]++;
      notice = '${player(guesser)}猜对了！';
      if (correct.length == count - 1) {
        phase = 'result';
        resetClock();
      }
    } else {
      notice = '${player(guesser)}还没猜对，再试一下。';
    }
  }
}

class GomokuSession extends GameSession {
  GomokuSession(super.game, super.players, {super.random});
  final board = List.filled(225, 0);
  int turn = 0;
  @override
  GameStep buildStep() => GameStep(
    title: '${player(turn)} · ${turn == 0 ? '黑棋' : '白棋'}落子',
    body: '无禁手，先连成五子获胜。',
    controller: turn,
    columns: 15,
    cells: [
      for (var i = 0; i < board.length; i++)
        BoardCell(
          board[i] == 0 ? 'c$i' : '',
          board[i] == 0
              ? '·'
              : board[i] == 1
              ? '●'
              : '○',
          tone: board[i],
        ),
    ],
  );
  @override
  GameStep get step => finished
      ? GameStep(
          title: '本局结束',
          body: result,
          columns: 15,
          cells: [
            for (final cell in board)
              BoardCell(
                '',
                cell == 0
                    ? '·'
                    : cell == 1
                    ? '●'
                    : '○',
                tone: cell,
              ),
          ],
        )
      : super.step;
  @override
  void handle(String action, String input, Duration elapsed) {
    final index = int.parse(action.substring(1));
    board[index] = turn + 1;
    final x = index % 15;
    final y = index ~/ 15;
    for (final direction in [(1, 0), (0, 1), (1, 1), (1, -1)]) {
      var total = 1;
      for (final sign in [-1, 1]) {
        var col = x + direction.$1 * sign;
        var row = y + direction.$2 * sign;
        while (col >= 0 &&
            col < 15 &&
            row >= 0 &&
            row < 15 &&
            board[row * 15 + col] == turn + 1) {
          total++;
          col += direction.$1 * sign;
          row += direction.$2 * sign;
        }
      }
      if (total >= 5) {
        finish('${player(turn)}五子连珠，获胜！');
        return;
      }
    }
    if (!board.contains(0)) {
      finish('棋盘已满，平局。');
      return;
    }
    turn = 1 - turn;
  }
}

class ReactionSession extends GameSession {
  ReactionSession(super.game, super.players, {super.random}) {
    delay = random.nextInt(4) + 2;
  }
  int delay = 2;
  String phase = 'ready';
  @override
  GameStep buildStep() => GameStep(
    title: phase == 'go'
        ? '现在点击！'
        : phase == 'wait'
        ? '等待信号，别抢跑'
        : '第 $round 回合',
    body: phase == 'ready'
        ? '$notice\n信号出现后点自己的按钮，先得 5 分获胜。联机以服务器收到点击的先后判定，网络延迟会影响结果。'
        : phase == 'go'
        ? '点击自己的按钮！'
        : '等屏幕出现「现在点击」再动手。',
    seconds: phase == 'wait'
        ? delay
        : phase == 'go'
        ? 5
        : null,
    options: phase == 'ready'
        ? const [nextOption]
        : [
            for (var i = 0; i < 2; i++)
              GameOption('p$i', '${player(i)}点击', actor: i),
          ],
  );
  @override
  void handle(String action, String input, Duration elapsed) {
    if (phase == 'ready') {
      phase = 'wait';
      delay = random.nextInt(4) + 2;
      resetClock();
      return;
    }
    if (phase == 'wait' && action == 'timeout') {
      phase = 'go';
      resetClock();
      return;
    }
    if (action == 'timeout') {
      notice = '双方超时，无人得分。';
    } else {
      final clicker = int.parse(action.substring(1));
      final winner = phase == 'wait' ? 1 - clicker : clicker;
      scores[winner]++;
      notice = phase == 'wait'
          ? '${player(clicker)}抢跑，${player(winner)}加 1 分。'
          : '${player(winner)}先点击，用时 ${elapsed.inMilliseconds} ms，加 1 分。';
      if (scores[winner] == 5) {
        finishScores();
        return;
      }
    }
    phase = 'ready';
    round++;
    resetClock();
  }

  void cancelRound() {
    phase = 'ready';
    notice = '本回合因切换后台取消，请重新准备。';
    resetClock();
  }
}

class SpyCodesSession extends GameSession {
  SpyCodesSession(super.game, super.players, {super.random}) {
    words.shuffle(random);
    owners.shuffle(random);
  }
  final words = List.of(drawingWords.take(25));
  final owners = [
    for (var i = 0; i < 8; i++) 0,
    for (var i = 0; i < 7; i++) 1,
    -2,
    for (var i = 0; i < 9; i++) -1,
  ];
  final revealed = <int>{};
  int turn = 0;
  bool cluePhase = true;
  String clue = '';
  int remaining = 0;
  int get captain => members(turn).first;
  int get guesser =>
      members(turn)[1 + ((round - 1) ~/ 2) % (members(turn).length - 1)];
  @override
  GameStep buildStep() => GameStep(
    title: '${team(turn)} · ${cluePhase ? '线索员给提示' : '猜暗号'}',
    body: cluePhase
        ? '只能给一个不在棋盘上的提示词和数量，如「天空 2」。不能直接报坐标。\n本队：${List.generate(25, (i) => i).where((i) => owners[i] == turn && !revealed.contains(i)).map((i) => words[i]).join('、')}\n对方：${List.generate(25, (i) => i).where((i) => owners[i] == 1 - turn && !revealed.contains(i)).map((i) => words[i]).join('、')}\n陷阱：${words[owners.indexOf(-2)]}'
        : '线索：$clue\n还可选 $remaining 次。\n$notice',
    privateFor: cluePhase ? player(captain) : null,
    controller: cluePhase ? captain : guesser,
    inputLabel: cluePhase ? '提示词 数量' : null,
    cells: cluePhase
        ? const []
        : [
            for (var i = 0; i < 25; i++)
              BoardCell(
                revealed.contains(i) ? '' : 'c$i',
                words[i],
                tone: revealed.contains(i)
                    ? owners[i] == 0
                          ? 1
                          : owners[i] == 1
                          ? 2
                          : 3
                    : 0,
              ),
          ],
    options: cluePhase
        ? const [submitOption]
        : const [GameOption('end', '结束猜测')],
  );
  void _switch() {
    turn = 1 - turn;
    round++;
    cluePhase = true;
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (cluePhase) {
      final parts = requireText(input, max: 30).split(RegExp(r'\s+'));
      if (parts.length != 2 ||
          words.any((word) => parts.first.contains(word))) {
        throw ArgumentError('格式：提示词 数量，不能包含棋盘词语');
      }
      remaining = requireNumber(parts.last, 1, 8);
      clue = input;
      cluePhase = false;
      return;
    }
    if (action == 'end') {
      _switch();
      return;
    }
    final id = int.parse(action.substring(1));
    revealed.add(id);
    if (owners[id] == -2) {
      finish('${team(turn)}误选陷阱「${words[id]}」，${team(1 - turn)}获胜！');
      return;
    }
    for (var t = 0; t < 2; t++) {
      if (List.generate(
        25,
        (i) => i,
      ).where((i) => owners[i] == t).every(revealed.contains)) {
        finish('${team(t)}找齐全部暗号，获胜！');
        return;
      }
    }
    notice = '「${words[id]}」属于${owners[id] < 0 ? '中立' : team(owners[id])}。';
    if (owners[id] != turn || --remaining == 0) {
      _switch();
    }
  }
}

class MazeSession extends GameSession {
  MazeSession(super.game, super.players, {super.random}) {
    _generate();
  }
  final walls = List.filled(81, true);
  int turn = 0;
  int position = 10;
  String phase = 'map';
  final completed = [false, false];
  final times = [0, 0];
  final progress = [0, 0];
  final visited = <int>{10};
  void _generate() {
    void carve(int cell) {
      walls[cell] = false;
      final directions = [-18, 18, -2, 2]..shuffle(random);
      for (final offset in directions) {
        final next = cell + offset;
        final x = next % 9;
        final y = next ~/ 9;
        if (next >= 0 &&
            next < 81 &&
            x > 0 &&
            x < 8 &&
            y > 0 &&
            y < 8 &&
            (cell % 9 - x).abs() <= 2 &&
            walls[next]) {
          walls[cell + offset ~/ 2] = false;
          carve(next);
        }
      }
    }

    carve(10);
  }

  @override
  GameStep buildStep() {
    final map = phase == 'map';
    return GameStep(
      title: '${team(turn)} · ${map ? '指挥员查看地图' : '操作员走迷宫'}',
      body: map
          ? '请操作员回避。记住地图后指挥队友从起点走到右下角出口。双方挑战同一迷宫，各有 120 秒。'
          : '$notice\n指挥员凭记忆口头指引；灰色区域未知，可见自身周围。',
      privateFor: player(members(turn)[map ? 0 : 1]),
      seconds: map ? null : 120,
      columns: 9,
      cells: [
        for (var i = 0; i < 81; i++)
          BoardCell(
            '',
            i == position
                ? '●'
                : i == 70
                ? '终'
                : !(map ||
                      (i % 9 - position % 9).abs() +
                              (i ~/ 9 - position ~/ 9).abs() <=
                          1)
                ? '?'
                : walls[i]
                ? '■'
                : '',
            tone: i == position ? 1 : 0,
          ),
      ],
      options: map
          ? const [nextOption]
          : const [
              GameOption('up', '↑ 上'),
              GameOption('left', '← 左'),
              GameOption('right', '右 →'),
              GameOption('down', '下 ↓'),
            ],
    );
  }

  void _end(Duration elapsed) {
    times[turn] = elapsed.inMilliseconds;
    progress[turn] = visited.length;
    if (turn == 0) {
      turn = 1;
      position = 10;
      phase = 'map';
      visited.clear();
      visited.add(10);
      notice = '';
      resetClock();
      return;
    }
    final winner = completed[0] != completed[1]
        ? (completed[0] ? 0 : 1)
        : completed[0]
        ? (times[0] == times[1]
              ? -1
              : times[0] < times[1]
              ? 0
              : 1)
        : progress[0] == progress[1]
        ? -1
        : progress[0] > progress[1]
        ? 0
        : 1;
    finish(
      '${winner < 0 ? '平局' : '${team(winner)}获胜'}\n${List.generate(2, (i) => '${team(i)}：${completed[i] ? '完成 ${times[i] / 1000} 秒' : '超时，探索 ${progress[i]} 格'}').join('\n')}',
    );
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (phase == 'map') {
      phase = 'move';
      resetClock();
      return;
    }
    if (action == 'timeout') {
      _end(const Duration(seconds: 120));
      return;
    }
    final offset = switch (action) {
      'up' => -9,
      'down' => 9,
      'left' => -1,
      _ => 1,
    };
    final next = position + offset;
    if (next < 0 || next >= 81 || walls[next]) {
      notice = '这里是墙，换个方向。';
      return;
    }
    position = next;
    visited.add(next);
    notice = '';
    if (next == 70) {
      completed[turn] = true;
      _end(elapsed);
    }
  }
}
