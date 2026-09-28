import 'dart:math';

import 'content.dart';
import 'session.dart';

class NumberBombSession extends GameSession {
  NumberBombSession(super.game, super.players, {super.random}) {
    _reset();
  }
  int low = 1;
  int high = 100;
  int target = 0;
  int turn = 0;
  void _reset() {
    low = 1;
    high = 100;
    target = random.nextInt(100) + 1;
    resetClock();
  }

  @override
  GameStep buildStep() => GameStep(
    title: '第 $round / 5 轮 · ${player(turn)}',
    body: '炸弹在 $low–$high 之间。\n$notice',
    inputLabel: '输入猜测的整数',
    options: const [submitOption],
    controller: turn,
    seconds: 30,
  );
  @override
  void handle(String action, String input, Duration elapsed) {
    final value = action == 'timeout'
        ? target
        : requireNumber(input, low, high);
    if (value == target) {
      scores[turn]--;
      notice =
          '${player(turn)}${action == 'timeout' ? '超时' : '踩中炸弹'}，扣 1 分。炸弹是 $target。';
      if (round++ == 5) {
        finishScores();
        return;
      }
      _reset();
    } else {
      if (value < target) {
        low = value + 1;
      } else {
        high = value - 1;
      }
      notice = '$value 安全，范围缩小了。';
    }
    turn = (turn + 1) % count;
    resetClock();
  }
}

class SevenSession extends GameSession {
  SevenSession(super.game, super.players, {super.random});
  int number = 1;
  int turn = 0;
  bool get mustPass => number % 7 == 0 || '$number'.contains('7');
  @override
  GameStep buildStep() => GameStep(
    title: '逢七过 · ${player(turn)}',
    body: '当前数字：$number\n7 的倍数或含 7 的数字必须说「过」。\n共 ${count * 5} 次报数。\n$notice',
    options: [GameOption('number', '报 $number'), const GameOption('pass', '过')],
    controller: turn,
    seconds: 5,
  );
  @override
  void handle(String action, String input, Duration elapsed) {
    final correct = action != 'timeout' && (action == 'pass') == mustPass;
    if (!correct) {
      scores[turn]--;
    }
    notice = '${player(turn)}${correct ? '答对' : '出错，扣 1 分'}';
    if (number++ == count * 5) {
      finishScores();
      return;
    }
    turn = (turn + 1) % count;
    resetClock();
  }
}

class QuizSession extends GameSession {
  QuizSession(super.game, super.players, {super.random}) {
    questions.shuffle(random);
  }
  final questions = List<QuizQuestion>.of(quizQuestions);
  int index = 0;
  int? answering;
  final attempted = <int>{};
  bool reveal = false;
  @override
  GameStep buildStep() {
    final question = questions[index];
    if (reveal) {
      return GameStep(
        title: '答案揭晓',
        body:
            '${question.question}\n答案：${question.options[question.correct]}\n$notice',
        options: const [nextOption],
      );
    }
    return GameStep(
      title: '第 ${index + 1} / 10 题',
      body: question.question,
      seconds: answering == null ? 20 : 10,
      controller: answering,
      options: answering == null
          ? [
              for (var i = 0; i < count; i++)
                if (!attempted.contains(i))
                  GameOption('buzz$i', '${player(i)} 抢答', actor: i),
            ]
          : [
              for (var i = 0; i < question.options.length; i++)
                GameOption('a$i', question.options[i]),
            ],
    );
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (reveal) {
      if (++index == 10) {
        finishScores();
        return;
      }
      reveal = false;
      answering = null;
      attempted.clear();
      notice = '';
    } else if (action.startsWith('buzz')) {
      answering = int.parse(action.substring(4));
      attempted.add(answering!);
    } else if (answering == null) {
      reveal = true;
      notice = '无人抢答';
    } else {
      final correct = action == 'a${questions[index].correct}';
      if (correct) {
        scores[answering!]++;
        reveal = true;
        notice = '${player(answering!)}答对，加 1 分';
      } else {
        notice = '${player(answering!)}未答对';
        answering = null;
        if (attempted.length == count) {
          reveal = true;
        }
      }
    }
    resetClock();
  }
}

class RelaySession extends GameSession {
  RelaySession(super.game, super.players, {super.random}) {
    alive.addAll(List.generate(count, (i) => i));
    category = categories[random.nextInt(categories.length)];
  }
  final alive = <int>[];
  final words = <String>[];
  int cursor = 0;
  int teamTurn = 0;
  late final String category;
  String pending = '';
  bool reviewing = false;
  int get turn => game.id == 'category_relay'
      ? members(teamTurn)[((round - 1) ~/ 2) % members(teamTurn).length]
      : alive[cursor];
  bool get memory => game.id == 'memory_relay';
  bool get teams => game.id == 'category_relay';
  @override
  GameStep buildStep() {
    if (reviewing) {
      return GameStep(
        title: '共同确认答案',
        body:
            '${player(turn)}提交：$pending\n${teams ? '是否属于「$category」且没有重复？' : '是否是有效词语？'}',
        options: const [GameOption('accept', '有效'), GameOption('reject', '无效')],
      );
    }
    return GameStep(
      title: teams
          ? '${team(teamTurn)} · ${player(turn)}'
          : '${player(turn)}的回合',
      body:
          '${memory
              ? '按顺序复述已有 ${words.length} 个词，再添加一个词。用空格分隔，不能查看前面的词串。'
              : teams
              ? '主题：$category\n双方各 5 回合。\n已用：${words.join('、')}'
              : '末字接首字，不得重复。\n${words.isEmpty ? '从任意词开始' : '上一词：${words.last}'}'}\n$notice',
      inputLabel: memory ? '完整词串 + 新词' : '输入词语',
      privateFor: memory ? player(turn) : null,
      controller: turn,
      seconds: 30,
      options: const [submitOption, GameOption('giveup', '放弃本轮')],
    );
  }

  void _lose() {
    if (teams) {
      teamScores[1 - teamTurn]++;
      _advance();
      return;
    }
    final name = player(turn);
    alive.removeAt(cursor);
    if (alive.length == 1) {
      finish('${player(alive.single)}获胜！\n$name 已出局。');
      return;
    }
    cursor %= alive.length;
    notice = '$name 出局。${memory ? '词串重新开始。' : ''}';
    if (memory) {
      words.clear();
    }
  }

  void _advance() {
    if (teams) {
      if (round++ == 10) {
        finishScores(teams: true);
        return;
      }
      teamTurn = 1 - teamTurn;
    } else {
      cursor = (cursor + 1) % alive.length;
    }
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (action == 'giveup' || action == 'timeout' || action == 'reject') {
      reviewing = false;
      _lose();
    } else if (action == 'accept') {
      words.add(pending);
      if (teams) {
        teamScores[teamTurn]++;
      }
      reviewing = false;
      _advance();
    } else if (memory) {
      final entries = requireText(input, max: 500).split(RegExp(r'\s+'));
      if (entries.length != words.length + 1 ||
          List.generate(
            words.length,
            (i) => entries[i] != words[i],
          ).any((different) => different)) {
        _lose();
      } else {
        words.add(entries.last);
        _advance();
      }
    } else {
      final word = requireText(input, max: 20);
      if (words.contains(word)) {
        throw ArgumentError('已经使用过这个词');
      }
      if (!teams &&
          words.isNotEmpty &&
          word.runes.first != words.last.runes.last) {
        throw ArgumentError(
          '请以「${String.fromCharCode(words.last.runes.last)}」开头',
        );
      }
      pending = word;
      reviewing = true;
    }
    resetClock();
  }
}

class SecretAnswerSession extends GameSession {
  SecretAnswerSession(super.game, super.players, {super.random});
  final answers = <int, String>{};
  int turn = 0;
  bool reveal = false;
  String statements = '';
  int lie = 0;
  int get subject => (round - 1) % count;
  bool get truth => game.id == 'two_truths_one_lie';
  bool get minority => game.id == 'minority_choice';
  bool get same => game.id == 'same_answer';
  String get prompt => prompts[(round - 1) % prompts.length];
  List<int> get participants => same
      ? [
          for (var t = 0; t < 2; t++)
            for (var j = 0; j < 2; j++)
              members(t)[((round - 1) + j) % members(t).length],
        ]
      : [
          subject,
          for (var i = 0; i < count; i++)
            if (i != subject) i,
        ];
  int get actor => participants[turn];
  @override
  GameStep buildStep() {
    if (reveal) {
      return GameStep(
        title: '第 $round 轮 · 揭晓',
        body: notice,
        options: const [nextOption],
      );
    }
    if (truth && statements.isEmpty) {
      return GameStep(
        title: '写下两真一假',
        body: '每行写一句，共三句。提交后私下指定哪句是假话。',
        inputLabel: '三句话，每行一句',
        privateFor: player(subject),
        options: const [submitOption],
      );
    }
    if (truth && lie == 0) {
      return GameStep(
        title: '哪句是假话？',
        body: statements,
        privateFor: player(subject),
        options: const [
          GameOption('1', '第 1 句'),
          GameOption('2', '第 2 句'),
          GameOption('3', '第 3 句'),
        ],
      );
    }
    return GameStep(
      title: '${player(actor)} · 私密作答',
      body: truth
          ? statements
          : minority
          ? '你选哪一个？人数较少的一方得分。'
          : same
          ? '两位队友各自回答，答案一致得分。\n$prompt'
          : actor == subject
          ? '你的答案是什么？\n$prompt'
          : '猜猜${player(subject)}的答案。\n$prompt',
      privateFor: player(actor),
      inputLabel: minority || truth ? null : '输入答案',
      options: truth
          ? const [
              GameOption('1', '第 1 句是假话'),
              GameOption('2', '第 2 句是假话'),
              GameOption('3', '第 3 句是假话'),
            ]
          : minority
          ? [
              GameOption('a', choices[(round - 1) % choices.length].$1),
              GameOption('b', choices[(round - 1) % choices.length].$2),
            ]
          : const [submitOption],
    );
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (reveal) {
      if (round++ >=
          (truth || !minority && !same
              ? count
              : same
              ? count
              : 5)) {
        finishScores(teams: same);
        return;
      }
      reveal = false;
      answers.clear();
      turn = 0;
      statements = '';
      lie = 0;
      return;
    }
    if (truth && statements.isEmpty) {
      final lines = requireText(
        input,
        max: 300,
      ).split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.length != 3) {
        throw ArgumentError('请分三行写三句话');
      }
      statements = lines
          .asMap()
          .entries
          .map((entry) => '${entry.key + 1}. ${entry.value}')
          .join('\n');
      return;
    }
    if (truth && lie == 0) {
      lie = int.parse(action);
      turn = 1;
      return;
    }
    answers[actor] = truth || minority ? action : requireText(input, max: 40);
    if (++turn < participants.length) {
      return;
    }
    if (minority) {
      final a = answers.values.where((value) => value == 'a').length;
      final b = count - a;
      for (final entry in answers.entries) {
        if ((entry.value == 'a' && a < b) || (entry.value == 'b' && b < a)) {
          scores[entry.key]++;
        }
      }
      notice =
          'A：$a 人，B：$b 人。平票或全员一致不得分。\n${answers.entries.map((e) => '${player(e.key)}：${e.value == 'a' ? 'A' : 'B'}').join('\n')}';
    } else if (same) {
      for (var t = 0; t < 2; t++) {
        final values = answers.entries
            .where((e) => e.key % 2 == t)
            .map((e) => normalizeAnswer(e.value))
            .toList();
        if (values.length == 2 && values[0] == values[1]) {
          teamScores[t]++;
        }
      }
      notice = answers.entries
          .map((e) => '${player(e.key)}：${e.value}')
          .join('\n');
    } else {
      final answer = truth ? '$lie' : normalizeAnswer(answers[subject]!);
      for (final entry in answers.entries) {
        if (entry.key != subject && normalizeAnswer(entry.value) == answer) {
          scores[entry.key]++;
        }
      }
      notice = truth
          ? '假话是第 $lie 句。\n$statements'
          : '${player(subject)}的答案：${answers[subject]}';
      notice +=
          '\n${answers.entries.where((e) => e.key != subject).map((e) => '${player(e.key)}：${e.value}').join('\n')}';
    }
    reveal = true;
  }
}

class PromptSession extends GameSession {
  PromptSession(super.game, super.players, {super.random}) {
    deck = List.generate(40, (i) => i)..shuffle(random);
  }
  late final List<int> deck;
  int card = 0;
  bool playing = false;
  final solved = <int>{};
  bool get identity => game.id == 'who_am_i';
  bool get soup => game.id == 'lateral_thinking';
  int get teamIndex => (round - 1) % 2;
  int get performer =>
      members(teamIndex)[((round - 1) ~/ 2) % members(teamIndex).length];
  int get identityPlayer => (round - 1) % count;
  int get observer => (identityPlayer + 1) % count;
  String get cardText => switch (game.id) {
    'taboo' =>
      '${tabooCards[deck[card % deck.length] % tabooCards.length].$1}\n禁词：${tabooCards[deck[card % deck.length] % tabooCards.length].$2}',
    'hum_guess' => songs[deck[card % deck.length] % songs.length],
    _ => drawingWords[deck[card % deck.length] % drawingWords.length],
  };
  @override
  GameStep buildStep() {
    if (soup) {
      final story = soups[deck.first % soups.length];
      return GameStep(
        title: story.$1,
        body: playing
            ? '${story.$2}\n大家口头提问，主持人回答「是／否／无关」。'
            : '主持人查看谜底后，请记住答案，再向其他人公布谜面。\n谜面：${story.$2}\n谜底：${story.$3}',
        privateFor: playing ? null : player(0),
        seconds: playing ? 600 : null,
        options: playing
            ? const [
                GameOption('solved', '已还原故事'),
                GameOption('reveal', '结束并揭晓'),
              ]
            : const [nextOption],
      );
    }
    if (identity) {
      return GameStep(
        title: '猜猜${player(identityPlayer)}是谁',
        body: playing
            ? '${player(identityPlayer)}口头提问，其他人只回答是或否；猜中后共同确认。'
            : '请让${player(identityPlayer)}回避。其他人记住他的身份：\n${identityWords[(deck.first + identityPlayer) % identityWords.length]}',
        privateFor: playing ? null : player(observer),
        seconds: playing ? 90 : null,
        options: playing
            ? const [GameOption('correct', '猜对了'), GameOption('skip', '放弃')]
            : const [nextOption],
      );
    }
    return GameStep(
      title: '${team(teamIndex)} · ${player(performer)}',
      body: playing
          ? '题目：$cardText\n${game.id == 'charades'
                ? '只能做动作，不能说话。'
                : game.id == 'hum_guess'
                ? '只能哼唱，不能说歌名。'
                : '描述时不能说目标词和禁词。'}\n同机模式由表演者持机，队友口头猜。'
          : '第 $round / ${max(4, count * 2)} 回合，60 秒。由${player(performer)}出题；另一队监督违规。',
      privateFor: playing ? player(performer) : null,
      seconds: playing ? 60 : null,
      options: playing
          ? const [
              GameOption('correct', '队友答对 +1'),
              GameOption('skip', '跳过 / 违规'),
            ]
          : const [nextOption],
    );
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (soup) {
      if (!playing) {
        playing = true;
        resetClock();
      } else {
        final story = soups[deck.first % soups.length];
        finish('${action == 'solved' ? '成功还原！' : '本题结束'}\n${story.$3}');
      }
      return;
    }
    if (!playing) {
      playing = true;
      resetClock();
      return;
    }
    if (identity) {
      if (action == 'correct') {
        scores[identityPlayer] = count - solved.length;
        solved.add(identityPlayer);
      }
      if (round++ == count) {
        finishScores();
        return;
      }
      playing = false;
      resetClock();
      return;
    }
    if (action == 'timeout') {
      if (round++ >= max(4, count * 2)) {
        finishScores(teams: true);
        return;
      }
      playing = false;
      resetClock();
    } else {
      if (action == 'correct') {
        teamScores[teamIndex]++;
      }
      card++;
    }
  }
}

class EstimationSession extends GameSession {
  EstimationSession(super.game, super.players, {super.random}) {
    _newQuestion();
  }
  int quantity = 0;
  int turn = 0;
  final guesses = <int>[];
  bool reveal = false;
  void _newQuestion() {
    quantity = random.nextInt(25) + 12;
    guesses.clear();
    turn = 0;
    reveal = false;
    resetClock();
  }

  @override
  GameStep buildStep() => reveal
      ? GameStep(
          title: '答案：$quantity',
          body: notice,
          options: const [nextOption],
        )
      : GameStep(
          title: '第 $round / 5 题 · ${team(turn)}估数',
          body: '估算下面圆点的数量。两队轮流秘密提交答案，不使用计算工具。',
          privateFor: player(members(turn).first),
          inputLabel: '圆点数量',
          seconds: 30,
          cells: [
            for (var i = 0; i < 64; i++)
              BoardCell(
                '',
                ((i * 17 + round * 3) % 64) < quantity ? '●' : '',
                tone: 0,
              ),
          ],
          columns: 8,
          options: const [submitOption],
        );
  @override
  void handle(String action, String input, Duration elapsed) {
    if (reveal) {
      if (round++ == 5) {
        finishScores(teams: true);
        return;
      }
      _newQuestion();
      return;
    }
    guesses.add(action == 'timeout' ? -1 : requireNumber(input, 0, 1000));
    if (++turn == 2) {
      final distances = guesses
          .map((guess) => guess < 0 ? 100000 : (guess - quantity).abs())
          .toList();
      if (distances[0] != distances[1]) {
        teamScores[distances[0] < distances[1] ? 0 : 1]++;
      }
      notice =
          '${team(0)}：${guesses[0] < 0 ? '超时' : guesses[0]}\n${team(1)}：${guesses[1] < 0 ? '超时' : guesses[1]}\n更接近者加 1 分，等距不得分。';
      reveal = true;
    }
    resetClock();
  }
}

class PuzzleSession extends GameSession {
  PuzzleSession(super.game, super.players, {super.random}) {
    deck.shuffle(random);
  }
  final deck = List.of(puzzles);
  int turn = 0;
  int index = 0;
  bool started = false;
  final solved = [0, 0];
  final times = [0, 0];
  @override
  GameStep buildStep() => !started
      ? GameStep(
          title: '${team(turn)}准备挑战',
          body: '同机请另一队回避。两队相同的三道谜题，最多 180 秒；先比较答对数，相同则用时短者获胜。',
          options: const [nextOption],
        )
      : GameStep(
          title: '${team(turn)} · 第 ${index + 1}/3 题',
          body: '${deck[index].$1}\n$notice',
          inputLabel: '输入答案',
          privateFor: player(members(turn).first),
          seconds: 180,
          options: const [submitOption, GameOption('skip', '跳过此题')],
        );
  void _endTeam(Duration elapsed) {
    times[turn] = elapsed.inMilliseconds;
    if (turn == 0) {
      turn = 1;
      index = 0;
      started = false;
      notice = '';
      resetClock();
      return;
    }
    final winner = solved[0] != solved[1]
        ? (solved[0] > solved[1] ? 0 : 1)
        : times[0] != times[1]
        ? (times[0] < times[1] ? 0 : 1)
        : -1;
    finish(
      '${winner < 0 ? '平局' : '${team(winner)}获胜'}\n橙队：${solved[0]} 题，${times[0] / 1000} 秒\n蓝队：${solved[1]} 题，${times[1] / 1000} 秒\n\n${deck.take(3).map((q) => '${q.$1} → ${q.$2}').join('\n')}',
    );
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    if (!started) {
      started = true;
      resetClock();
      return;
    }
    if (action == 'timeout') {
      _endTeam(const Duration(seconds: 180));
      return;
    }
    if (action == 'submit') {
      if (normalizeAnswer(requireText(input)) != deck[index].$2) {
        notice = '还不对，再讨论一下。';
        return;
      }
      solved[turn]++;
    }
    notice = '';
    if (++index == 3) {
      _endTeam(elapsed);
    }
  }
}
