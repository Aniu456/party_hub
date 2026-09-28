import 'content.dart';
import 'session.dart';

class DeductionSession extends GameSession {
  DeductionSession(super.game, super.players, {super.random}) {
    final seats = List.generate(
      wolf ? count : count - 1,
      (i) => wolf ? i : i + 1,
    )..shuffle(random);
    final badCount = wolf
        ? (count >= 9 ? 3 : 2)
        : seats.length <= 6
        ? 1
        : seats.length <= 9
        ? 2
        : 3;
    bad.addAll(seats.take(badCount));
    if (wolf) {
      seer = seats[badCount];
      guard = seats[badCount + 1];
    }
    alive.addAll(
      List.generate(wolf ? count : count - 1, (i) => wolf ? i : i + 1),
    );
    cursor = wolf ? 0 : 1;
    pair = wordPairs[random.nextInt(wordPairs.length)];
  }
  bool get wolf => game.id == 'werewolf';
  final bad = <int>{};
  final alive = <int>[];
  final votes = <int, int>{};
  final nightVotes = <int>[];
  List<int> candidates = [];
  List<int> speakers = [];
  List<int> nightActors = [];
  int? seer;
  int? guard;
  int? protected;
  late final (String, String) pair;
  String phase = 'reveal';
  int cursor = 0;
  bool secondVote = false;
  String inspection = '';
  int get actor => switch (phase) {
    'reveal' => cursor,
    'night' || 'inspect' => nightActors[cursor],
    'talk' => speakers[cursor],
    'vote' => alive[cursor],
    _ => 0,
  };
  String role(int seat) => !wolf && seat == 0
      ? '主持人'
      : bad.contains(seat)
      ? (wolf ? '狼人' : '卧底')
      : seat == seer
      ? '预言家'
      : seat == guard
      ? '守卫'
      : '平民';
  String get allRoles =>
      List.generate(count, (i) => '${player(i)}：${role(i)}').join('\n');
  @override
  int? get moderatorSeat => wolf ? null : 0;
  @override
  String? moderatorOverview(int seat) {
    if (wolf || seat != 0) {
      return null;
    }
    return '主持人：${player(0)}\n第 $round 轮 · 不参与拿词、发言或投票\n\n${[for (var i = 1; i < count; i++) '${player(i)}：${role(i)} · ${bad.contains(i) ? pair.$2 : pair.$1} · ${alive.contains(i) ? '存活' : '已出局'}'].join('\n')}';
  }

  @override
  GameStep buildStep() {
    if (phase == 'reveal') {
      return GameStep(
        title: '查看你的${wolf ? '身份' : '词语'}',
        body: wolf
            ? '${role(actor)}${bad.contains(actor) ? '\n狼队：${bad.map(player).join('、')}' : ''}\n记住身份后交给下一位。'
            : '你的词语：${bad.contains(actor) ? pair.$2 : pair.$1}\n不要直接说出词语，也不要给其他人看。',
        privateFor: player(actor),
        options: const [nextOption],
      );
    }
    if (phase == 'night') {
      return GameStep(
        title: '第 $round 夜 · ${role(actor)}行动',
        body: bad.contains(actor)
            ? '选择袭击目标。狼队多数票决定目标，平票则无人被袭击。'
            : actor == seer
            ? '选择查验一人的阵营。'
            : '选择今晚保护的玩家，可保护自己。',
        privateFor: player(actor),
        options: picks(
          alive.where(
            (id) => bad.contains(actor)
                ? !bad.contains(id)
                : actor == seer
                ? id != actor
                : true,
          ),
        ),
      );
    }
    if (phase == 'inspect') {
      return GameStep(
        title: '查验结果',
        body: inspection,
        privateFor: player(actor),
        options: const [nextOption],
      );
    }
    if (phase == 'dawn') {
      return GameStep(title: '天亮了', body: notice, options: const [nextOption]);
    }
    if (phase == 'talk') {
      return GameStep(
        title: '第 $round 轮 · ${player(actor)}发言',
        body:
            '${wolf ? '讨论身份与线索。' : '描述你的词语，不要直接说出答案。'}\n存活：${alive.map(player).join('、')}\n${secondVote ? '平票候选补充发言。' : notice}',
        controller: actor,
        seconds: 45,
        options: const [GameOption('next', '发言结束')],
      );
    }
    if (phase == 'vote') {
      return GameStep(
        title: '投票淘汰一人',
        body: '不能投自己，提交后不能更改。',
        privateFor: player(actor),
        options: [
          ...picks(candidates.where((id) => id != actor)),
          const GameOption('abstain', '弃票'),
        ],
      );
    }
    return GameStep(title: '投票结果', body: notice, options: const [nextOption]);
  }

  void _talk({List<int>? only}) {
    speakers = List.of(only ?? alive);
    cursor = 0;
    phase = 'talk';
    resetClock();
  }

  void _night() {
    phase = 'night';
    cursor = 0;
    protected = null;
    nightVotes.clear();
    nightActors = [
      for (final id in alive)
        if (bad.contains(id)) id,
      if (alive.contains(seer)) seer!,
      if (alive.contains(guard)) guard!,
    ];
    resetClock();
  }

  void _checkWinner() {
    final evil = alive.where(bad.contains).length;
    if (evil == 0) {
      finish('${wolf ? '好人' : '平民'}获胜！\n$allRoles');
    } else if (wolf ? evil >= alive.length - evil : alive.length <= 2) {
      finish('${wolf ? '狼人' : '卧底'}获胜！\n$allRoles');
    }
  }

  void _advanceNight() {
    if (++cursor < nightActors.length) {
      return;
    }
    final tally = <int, int>{};
    for (final id in nightVotes) {
      tally[id] = (tally[id] ?? 0) + 1;
    }
    var highest = 0;
    for (final value in tally.values) {
      if (value > highest) {
        highest = value;
      }
    }
    final leaders = tally.keys.where((id) => tally[id] == highest).toList();
    final victim = leaders.length == 1 ? leaders.single : null;
    if (victim != null && victim != protected) {
      alive.remove(victim);
      notice = '${player(victim)}昨夜出局。';
    } else {
      notice = '昨夜无人出局。';
    }
    _checkWinner();
    phase = 'dawn';
  }

  void _resolveVotes() {
    final tally = <int, int>{};
    for (final id in votes.values) {
      if (id >= 0) {
        tally[id] = (tally[id] ?? 0) + 1;
      }
    }
    var highest = 0;
    for (final value in tally.values) {
      if (value > highest) {
        highest = value;
      }
    }
    final tied = tally.keys.where((id) => tally[id] == highest).toList();
    if (tied.length == 1) {
      alive.remove(tied.single);
      notice = '${player(tied.single)}以 $highest 票出局。';
      _checkWinner();
      phase = 'result';
      secondVote = false;
    } else if (!secondVote && tied.isNotEmpty) {
      secondVote = true;
      candidates = tied;
      notice = '最高票平票，候选人补充发言后再投一次。';
      _talk(only: tied);
    } else {
      notice = '平票或全员弃票，本轮无人出局。';
      phase = 'result';
      secondVote = false;
    }
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    switch (phase) {
      case 'reveal':
        if (++cursor == count) {
          if (wolf) {
            _night();
          } else {
            candidates = List.of(alive);
            _talk();
          }
        }
      case 'night':
        final selected = int.parse(action.substring(1));
        if (bad.contains(actor)) {
          nightVotes.add(selected);
          _advanceNight();
        } else if (actor == seer) {
          inspection =
              '${player(selected)}属于${bad.contains(selected) ? '狼人' : '好人'}阵营。';
          phase = 'inspect';
        } else {
          protected = selected;
          _advanceNight();
        }
      case 'inspect':
        phase = 'night';
        _advanceNight();
      case 'dawn':
        candidates = List.of(alive);
        _talk();
      case 'talk':
        if (++cursor == speakers.length) {
          phase = 'vote';
          cursor = 0;
          votes.clear();
        }
        resetClock();
      case 'vote':
        votes[actor] = action == 'abstain'
            ? -1
            : int.parse(action.substring(1));
        if (++cursor == alive.length) {
          _resolveVotes();
        }
      case 'result':
        round++;
        if (wolf) {
          _night();
        } else {
          candidates = List.of(alive);
          _talk();
        }
    }
  }
}

/// 联机卧底按连接身份分发词语与选项，不使用同机交接顺序。
class OnlineUndercoverSession extends DeductionSession {
  OnlineUndercoverSession(super.game, super.players, {super.random});

  final confirmed = <int>{};
  bool get concurrentActions =>
      !finished && (phase == 'reveal' || phase == 'vote');

  String? wordFor(int seat) => seat > 0 && seat < count
      ? (bad.contains(seat) ? pair.$2 : pair.$1)
      : null;

  GameStep stepFor(int seat) {
    if (finished) {
      return step;
    }
    if (phase == 'reveal') {
      final progress = '已确认 ${confirmed.length} / ${count - 1} 人';
      if (seat == moderatorSeat || confirmed.contains(seat)) {
        return GameStep(
          title: seat == moderatorSeat ? '等待玩家查看词语' : '已记住词语',
          body: '$progress，所有玩家确认后开始发言。',
        );
      }
      return GameStep(
        title: '查看你的词语',
        body: '你的词语：${wordFor(seat)}\n不要直接说出词语，也不要给其他人看。',
        privateFor: player(seat),
        options: const [GameOption('confirm_word', '我记住了')],
      );
    }
    if (phase == 'vote') {
      final progress = '已提交 ${votes.length} / ${alive.length} 票';
      if (seat == moderatorSeat ||
          !alive.contains(seat) ||
          votes.containsKey(seat)) {
        return GameStep(
          title: votes.containsKey(seat) ? '已提交投票' : '等待玩家投票',
          body: '$progress，全部提交后公布结果。',
        );
      }
      return GameStep(
        title: '投票淘汰一人',
        body: '不能投自己，提交后不能更改。\n$progress',
        options: [
          ...picks(candidates.where((id) => id != seat)),
          const GameOption('abstain', '弃票'),
        ],
      );
    }
    return step;
  }

  bool canActFor(int seat, String action) {
    if (finished || seat < 0 || seat >= count || action == 'timeout') {
      return false;
    }
    final view = stepFor(seat);
    if (!view.options.any((option) => option.id == action)) {
      return false;
    }
    return concurrentActions ||
        seat == (view.controller ?? moderatorSeat) ||
        (phase == 'talk' && seat == moderatorSeat);
  }

  void actFor(int seat, String action, String input, Duration elapsed) {
    if (!canActFor(seat, action)) {
      throw StateError('当前不能执行此操作');
    }
    if (phase == 'reveal') {
      confirmed.add(seat);
      if (confirmed.length == count - 1) {
        candidates = List.of(alive);
        _talk();
      }
    } else if (phase == 'vote') {
      votes[seat] = action == 'abstain' ? -1 : int.parse(action.substring(1));
      if (votes.length == alive.length) {
        _resolveVotes();
      }
    } else {
      act(action, input: input, elapsed: elapsed);
    }
  }
}

class AvalonSession extends GameSession {
  AvalonSession(super.game, super.players, {super.random}) {
    final seats = List.generate(count, (i) => i)..shuffle(random);
    final evilCount = count <= 6
        ? 2
        : count <= 9
        ? 3
        : 4;
    evil.addAll(seats.take(evilCount));
    assassin = seats.first;
    merlin = seats[evilCount];
  }
  final evil = <int>{};
  late final int assassin;
  late final int merlin;
  int leader = 0;
  int cursor = 0;
  int rejections = 0;
  int approvals = 0;
  int successes = 0;
  int failures = 0;
  int sabotage = 0;
  String phase = 'reveal';
  final selected = <int>[];
  final history = <String>[];
  int get teamSize => (count == 5
      ? [2, 3, 2, 3, 3]
      : count == 6
      ? [2, 3, 4, 3, 4]
      : count == 7
      ? [2, 3, 3, 4, 4]
      : [3, 4, 4, 5, 5])[round - 1];
  int get failsNeeded => count >= 7 && round == 4 ? 2 : 1;
  String role(int id) => id == merlin
      ? '梅林'
      : id == assassin
      ? '刺客'
      : evil.contains(id)
      ? '坏人'
      : '忠臣';
  String get roles =>
      List.generate(count, (i) => '${player(i)}：${role(i)}').join('\n');
  @override
  GameStep buildStep() {
    switch (phase) {
      case 'reveal':
        return GameStep(
          title: '查看身份',
          body:
              '${role(cursor)}\n${evil.contains(cursor) || cursor == merlin ? '坏人：${evil.map(player).join('、')}' : '通过讨论找出可信队友。'}',
          privateFor: player(cursor),
          options: const [nextOption],
        );
      case 'propose':
        return GameStep(
          title: '第 $round 次任务 · ${player(leader)}组队',
          body:
              '选择 $teamSize 人。连续 5 次提案被否决，坏人获胜。当前否决 $rejections 次。\n${history.join('\n')}',
          controller: leader,
          cells: [
            for (var i = 0; i < count; i++)
              BoardCell('p$i', player(i), tone: selected.contains(i) ? 1 : 0),
          ],
          columns: 3,
          options: const [submitOption],
        );
      case 'approve':
        return GameStep(
          title: '同意这支队伍吗？',
          body: '任务队：${selected.map(player).join('、')}',
          privateFor: player(cursor),
          options: const [GameOption('yes', '同意'), GameOption('no', '反对')],
        );
      case 'mission':
        final actor = selected[cursor];
        return GameStep(
          title: '秘密执行任务',
          body: '好人只能成功，坏人可选择破坏。本次需要 $failsNeeded 张失败票才失败。',
          privateFor: player(actor),
          options: [
            const GameOption('success', '任务成功'),
            if (evil.contains(actor)) const GameOption('fail', '破坏任务'),
          ],
        );
      case 'assassinate':
        return GameStep(
          title: '刺杀梅林',
          body: '好人已成功完成三次任务。刺客最后选择谁是梅林。',
          privateFor: player(assassin),
          options: picks(
            List.generate(count, (i) => i).where((id) => !evil.contains(id)),
          ),
        );
      default:
        return GameStep(
          title: '任务 / 提案结果',
          body: notice,
          options: const [nextOption],
        );
    }
  }

  void _proposal() {
    selected.clear();
    leader = (leader + 1) % count;
    phase = 'propose';
  }

  @override
  void handle(String action, String input, Duration elapsed) {
    switch (phase) {
      case 'reveal':
        if (++cursor == count) {
          phase = 'propose';
        }
      case 'propose':
        if (action == 'submit') {
          if (selected.length != teamSize) {
            throw ArgumentError('必须选择 $teamSize 人');
          }
          approvals = 0;
          cursor = 0;
          phase = 'approve';
        } else {
          final id = int.parse(action.substring(1));
          if (selected.contains(id)) {
            selected.remove(id);
          } else if (selected.length < teamSize) {
            selected.add(id);
          }
        }
      case 'approve':
        if (action == 'yes') {
          approvals++;
        }
        if (++cursor == count) {
          if (approvals > count / 2) {
            cursor = 0;
            sabotage = 0;
            rejections = 0;
            phase = 'mission';
          } else {
            rejections++;
            notice = '同意 $approvals 票，提案被否决。';
            if (rejections == 5) {
              finish('连续五次否决，坏人获胜！\n$roles');
            } else {
              phase = 'rejected';
            }
          }
        }
      case 'mission':
        if (action == 'fail') {
          sabotage++;
        }
        if (++cursor == selected.length) {
          final failed = sabotage >= failsNeeded;
          if (failed) {
            failures++;
          } else {
            successes++;
          }
          notice = '第 $round 次任务${failed ? '失败' : '成功'}，有 $sabotage 张失败票。';
          history.add(notice);
          if (failures == 3) {
            finish('三次任务失败，坏人获胜！\n$roles');
          } else if (successes == 3) {
            phase = 'assassinate';
          } else {
            phase = 'result';
          }
        }
      case 'assassinate':
        final victim = int.parse(action.substring(1));
        finish('${victim == merlin ? '刺杀命中梅林，坏人获胜' : '刺杀失败，好人获胜'}！\n$roles');
      case 'rejected':
        _proposal();
      case 'result':
        round++;
        _proposal();
    }
  }
}
