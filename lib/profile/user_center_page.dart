import 'package:flutter/material.dart';

import '../app_style.dart';
import '../update/app_update.dart';
import 'user_profile.dart';

class UserCenterPage extends StatefulWidget {
  const UserCenterPage({super.key, required this.profile});
  final UserProfile profile;
  @override
  State<UserCenterPage> createState() => _UserCenterPageState();
}

class _UserCenterPageState extends State<UserCenterPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  bool saving = false;
  bool saved = false;

  @override
  void initState() {
    super.initState();
    name.text = widget.profile.nickname;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => saving = true);
    final success = await widget.profile.saveNickname(name.text);
    if (!mounted) {
      return;
    }
    setState(() {
      saving = false;
      saved = success;
      if (success) {
        name.text = widget.profile.nickname;
      }
    });
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('昵称已保存，下次开局自动填写')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('用户中心')),
        body: Form(
          key: form,
          child: PageContent(
            children: [
              SurfaceCard(
                color: colors.secondaryContainer,
                child: Column(
                  children: [
                    const PlayerAvatar(index: 0, size: 96),
                    const SizedBox(height: 16),
                    Text(
                      widget.profile.nickname.isEmpty
                          ? '朋友，还差一个昵称'
                          : widget.profile.nickname,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: colors.onSecondaryContainer),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '不用注册，也不用记密码',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
              const SectionHeading('你的游戏名片'),
              const Text('设置一次昵称，下次开局直接用。'),
              const SizedBox(height: 20),
              TextFormField(
                controller: name,
                enabled: !saving,
                maxLength: 20,
                textInputAction: TextInputAction.done,
                validator: UserProfile.validateNickname,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: '游戏昵称',
                  hintText: '朋友们怎么称呼你',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                onChanged: (_) => setState(() => saved = false),
                onFieldSubmitted: (_) => save(),
              ),
              if (widget.profile.storageError != null)
                InfoNote(widget.profile.storageError!, error: true),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: saving || saved ? null : save,
                child: Text(
                  saving
                      ? '正在保存…'
                      : saved
                      ? '已保存'
                      : '保存昵称',
                ),
              ),
              const SizedBox(height: 16),
              const InfoNote(
                '昵称保存在这台设备。创建或加入联机房间时会自动填写，并显示给同房间的朋友。修改昵称将在下次入局时生效。',
                icon: Icons.smartphone_rounded,
              ),
              const InfoNote(
                '同机开局会把你的昵称填在第一位，其他朋友分别填写自己的昵称。谁是卧底的第一位为主持人。',
                icon: Icons.people_outline_rounded,
              ),
              const CheckUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }
}
