import 'package:flutter/material.dart';

/// 仅用于展示；玩法与服务端协议不依赖 UI 分类。
class GameLook {
  const GameLook(this.category, this.teaser, this.icon);
  final String category;
  final String teaser;
  final IconData icon;
}

const gameLooks = <String, GameLook>{
  'undercover': GameLook('推理社交', '藏好你的词，找出那个人', Icons.theater_comedy_outlined),
  'draw_guess': GameLook('创意表演', '画技不重要，脑洞才重要', Icons.draw_outlined),
  'drawing_telephone': GameLook(
    '创意表演',
    '传到最后，还认得出吗',
    Icons.auto_fix_high_outlined,
  ),
  'werewolf': GameLook('推理社交', '天黑请闭眼，好戏刚开场', Icons.nightlight_outlined),
  'avalon': GameLook('推理社交', '信任，是最难的一次选择', Icons.shield_outlined),
  'lateral_thinking': GameLook(
    '推理社交',
    '一个故事，无数种可能',
    Icons.psychology_alt_outlined,
  ),
  'who_am_i': GameLook('推理社交', '所有人都知道，除了你', Icons.face_outlined),
  'charades': GameLook('团队合作', '你的动作，队友的脑洞', Icons.accessibility_new_rounded),
  'taboo': GameLook('团队合作', '那个词，就差说出口了', Icons.voice_over_off_outlined),
  'hum_guess': GameLook('团队合作', '一段旋律，谁先听懂', Icons.music_note_outlined),
  'word_chain': GameLook('轻松破冰', '接住朋友的最后一个字', Icons.link_rounded),
  'category_relay': GameLook('团队合作', '轮到你了，别让灵感断线', Icons.sync_alt_rounded),
  'seven_pass': GameLook('轻松破冰', '数到七，把紧张传下去', Icons.exposure_plus_1_rounded),
  'number_bomb': GameLook('轻松破冰', '范围越小，心跳越快', Icons.timer_outlined),
  'quiz': GameLook('轻松破冰', '比脑力，也比手速', Icons.bolt_outlined),
  'minority_choice': GameLook('轻松破冰', '这次，少数人说了算', Icons.call_split_rounded),
  'know_your_friends': GameLook(
    '轻松破冰',
    '你真的了解身边的朋友吗',
    Icons.favorite_border_rounded,
  ),
  'two_truths_one_lie': GameLook(
    '推理社交',
    '三句话，哪句骗过了你',
    Icons.chat_bubble_outline_rounded,
  ),
  'same_answer': GameLook('团队合作', '不用说，也能想到一起', Icons.all_inclusive_rounded),
  'memory_relay': GameLook('轻松破冰', '一起把记忆叠得更高', Icons.layers_outlined),
  'spy_codes': GameLook('团队合作', '一个暗号，读懂队友', Icons.key_outlined),
  'team_estimation': GameLook('团队合作', '靠近答案，需要一点默契', Icons.straighten_rounded),
  'puzzle_race': GameLook('团队合作', '拼起线索，一起破局', Icons.extension_outlined),
  'blind_maze': GameLook('团队合作', '你指方向，我来走', Icons.route_outlined),
  'gomoku': GameLook('双人 PK', '黑白之间，走好每一步', Icons.grid_4x4_rounded),
  'reaction_duel': GameLook('双人 PK', '盯紧信号，一触即发', Icons.touch_app_outlined),
};
