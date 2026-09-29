import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_style.dart';
import '../game_catalog.dart';
import '../profile/user_profile.dart';
import 'room_client.dart';
import 'room_page.dart';
import 'room_scan_page.dart';

class RoomEntryPage extends StatefulWidget {
  const RoomEntryPage({super.key, this.game});
  final PartyGame? game;
  @override
  State<RoomEntryPage> createState() => _RoomEntryPageState();
}

class _RoomEntryPageState extends State<RoomEntryPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final code = TextEditingController();
  bool entering = false;
  String? saveError;
  bool scanning = false;
  @override
  void initState() {
    super.initState();
    name.text = UserProfileScope.read(context)?.nickname ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> enter() async {
    if (entering || !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      entering = true;
      saveError = null;
    });
    final profile = UserProfileScope.read(context);
    try {
      if (profile != null && !await profile.saveNickname(name.text)) {
        if (mounted) {
          setState(() => saveError = profile.storageError);
        }
        return;
      }
      if (!mounted) {
        return;
      }
      final client = RoomClient(
        name: name.text.trim(),
        gameId: widget.game?.id,
        joinCode: code.text.trim(),
      );
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => RoomPage(client: client)),
      );
    } finally {
      if (mounted) {
        setState(() => entering = false);
      }
    }
  }

  Future<void> scan() async {
    if (entering || scanning) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => scanning = true);
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RoomScanPage()),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      scanning = false;
      if (result != null) {
        code.text = result;
      }
    });
    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已识别房间码，确认昵称后点击加入房间')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final game = widget.game;
    final joining = game == null;
    return Scaffold(
      appBar: AppBar(title: Text(joining ? '加入房间' : '创建房间')),
      body: Form(
        key: form,
        child: PageContent(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final artwork = SizedBox(
                    width: 68,
                    height: 68,
                    child: joining
                        ? const PlayerAvatar(index: 2, size: 68)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GameArtwork(game: game, height: 68),
                          ),
                  );
                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        joining ? '朋友的邀请' : '即将开局',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        joining ? '快乐，就差你了' : game.name,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 19,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                  if (MediaQuery.textScalerOf(context).scale(16) > 24) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [artwork, const SizedBox(height: 14), details],
                    );
                  }
                  return Row(
                    children: [
                      artwork,
                      const SizedBox(width: 16),
                      Expanded(child: details),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(
              joining ? '扫码或输入房间码，马上与朋友会合。' : '创建后邀请朋友扫码或输入房间码，大家准备好就能开始。',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              enabled: !entering,
              maxLength: 20,
              textInputAction: joining
                  ? TextInputAction.next
                  : TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: UserProfile.validateNickname,
              decoration: const InputDecoration(
                labelText: '你的昵称',
                hintText: '朋友们怎么称呼你',
                counterText: '',
                errorMaxLines: 4,
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '昵称会保存在本机，下次自动填写。',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
            if (joining) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: entering || scanning ? null : scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('扫码加入'),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '六位房间码',
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: code,
                      enabled: !entering,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                          ? null
                          : '请输入完整的 6 位房间码',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: colors.primary,
                      ),
                      decoration: const InputDecoration(
                        hintText: '000000',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20),
                        counterText: '',
                        errorMaxLines: 4,
                      ),
                      onFieldSubmitted: (_) => enter(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '向开房的朋友获取',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (saveError != null) InfoNote(saveError!, error: true),
            FilledButton(
              onPressed: entering ? null : enter,
              child: Text(
                entering
                    ? '正在进入…'
                    : joining
                    ? '加入房间'
                    : '创建房间',
              ),
            ),
            const SizedBox(height: 12),
            const InfoNote(
              '每人使用自己的设备。讨论、口述和动作类玩法，需要面对面或自行语音通话。',
              icon: Icons.chat_bubble_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
