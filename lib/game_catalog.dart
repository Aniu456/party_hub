/// 首批游戏的规则说明与开局人数范围。
class PartyGame {
  const PartyGame({
    required this.id,
    required this.name,
    required this.rules,
    required this.minPlayers,
    required this.maxPlayers,
  }) : assert(minPlayers > 0),
       assert(maxPlayers >= minPlayers);

  final String id;
  final String name;
  final String rules;
  final int minPlayers;
  final int maxPlayers;

  /// 只校验新一局人数；联机开局还须由服务端检查身份、在线和准备状态。
  bool supportsPlayerCount(int playerCount) {
    return playerCount >= minPlayers && playerCount <= maxPlayers;
  }
}

const plannedGames = <PartyGame>[
  PartyGame(
    id: 'undercover',
    name: '谁是卧底',
    rules: '至少 1 名主持人加 3 名玩家。主持人可查看全部身份和词语，不参与投票；玩家描述后投票淘汰。卧底全部出局则平民胜，仍有卧底且只剩 2 名玩家则卧底胜。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'draw_guess',
    name: '你画我猜',
    rules: '一人画图，其余人限时猜词；猜中者与画者得分，人人画过后按总分排名。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'drawing_telephone',
    name: '画画传话',
    rules: '文字与画图交替传递，每人只能看到上一棒；一圈后展示演变过程，不强制胜负。',
    minPlayers: 3,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'werewolf',
    name: '狼人杀',
    rules: '按固定角色表进行夜晚行动与白天投票；狼人全部出局则好人胜，狼人数量达到存活好人数量则狼人胜。',
    minPlayers: 6,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'avalon',
    name: '阿瓦隆',
    rules: '隐藏阵营、组队与秘密任务；三次任务失败则坏人胜，三次成功后刺杀梅林决定最终胜负。',
    minPlayers: 5,
    maxPlayers: 10,
  ),
  PartyGame(
    id: 'lateral_thinking',
    name: '海龟汤',
    rules: '一名真人主持，其余人通过是非问题还原故事；主持人确认解答或时间到后揭晓。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'who_am_i',
    name: '我是谁',
    rules: '每人看不到自己的身份牌，但能看到他人的；轮流提问猜身份，按猜中顺序计分。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'charades',
    name: '你比我猜',
    rules: '分两队，一人用动作表达词语；限时答对更多的队伍获胜。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'taboo',
    name: '禁词挑战',
    rules: '分两队，描述目标词但不能说出禁词；答对得分，违规跳题，轮换后比较总分。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'hum_guess',
    name: '哼歌猜歌',
    rules: '分成两队，队员轮流看歌名哼唱，队友限时猜歌；轮换后答对更多的队伍获胜。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'word_chain',
    name: '词语接龙',
    rules: '以上一个词的末字接下一个词首字，不得重复；超时或无效者出局，最后留下者胜。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'category_relay',
    name: '分类接力',
    rules: '分成两队，双方轮流派队员按水果、城市等主题给答案；重复、超时或答错则对方得分，固定轮数后比较总分。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'seven_pass',
    name: '逢七过',
    rules: '依次报数，遇到 7 的倍数或包含 7 的数字说「过」；出错扣分，固定轮数后排名。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'number_bomb',
    name: '数字炸弹',
    rules: '猜隐藏数字并逐渐收窄区间；命中者失分，多轮累计排名。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'quiz',
    name: '知识抢答',
    rules: '同题抢答，先抢到的玩家作答；答对得分，固定题数后排名。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'minority_choice',
    name: '少数派选择',
    rules: '秘密二选一，仅人数较少且非空的一方得分；平票或全员一致不加分。',
    minPlayers: 3,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'know_your_friends',
    name: '默契问答',
    rules: '一人作答，其余人预测他的答案；同时揭晓，猜中得分，轮换目标玩家。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'two_truths_one_lie',
    name: '两真一假',
    rules: '每人写两件真事和一件假事，其他人投票找假话；猜中得分，人人出题后排名。',
    minPlayers: 3,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'same_answer',
    name: '心有灵犀',
    rules: '分成两队，每轮双方各派两人围绕同一提示秘密作答；队内答案相同得分，每名玩家轮换参与，累计比较队伍分数。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'memory_relay',
    name: '记忆接力',
    rules: '复述已有词串并添加一词；漏词、顺序错误或超时者出局，最后留下者胜。',
    minPlayers: 2,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'spy_codes',
    name: '谍报暗号',
    rules: '两队各选一名线索员，用一个提示词引导队友选择本队暗号；先找齐本队暗号者胜，误选陷阱立即失败。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'team_estimation',
    name: '团队估数',
    rules: '两队讨论图片数量、长度等估算题，各提交一个答案；与标准答案更接近的队伍得分，等距不加分，多轮累计排名。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'puzzle_race',
    name: '解谜竞速',
    rules: '两队获得相同的一组谜题，队员合作解答；先完成全部题目的队伍获胜，超时则比较已解题数。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'blind_maze',
    name: '盲指迷宫',
    rules: '两队各派指挥员看地图、操作员看局部视野，合作走出同一迷宫；每轮轮换角色，比较完成用时，超时比较进度。',
    minPlayers: 4,
    maxPlayers: 12,
  ),
  PartyGame(
    id: 'gomoku',
    name: '五子棋',
    rules: '两人交替落子，先连成五子者获胜；首版采用无禁手规则，棋盘填满且无人获胜则和局。',
    minPlayers: 2,
    maxPlayers: 2,
  ),
  PartyGame(
    id: 'reaction_duel',
    name: '反应力对决',
    rules: '两人等待随机信号后点击；抢跑判本轮失败，有效反应更快者得分，先得五分者胜。',
    minPlayers: 2,
    maxPlayers: 2,
  ),
];
