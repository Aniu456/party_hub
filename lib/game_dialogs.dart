import 'package:flutter/material.dart';

Future<bool> confirmExit(
  BuildContext context, {
  String message = '退出后本局进度不会保存。',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('退出本局？'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('继续玩'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('退出'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> showModeratorOverview(
  BuildContext context,
  String name,
  String overview,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _ModeratorDialog(name: name, overview: overview),
  );
}

class _ModeratorDialog extends StatefulWidget {
  const _ModeratorDialog({required this.name, required this.overview});
  final String name;
  final String overview;
  @override
  State<_ModeratorDialog> createState() => _ModeratorDialogState();
}

class _ModeratorDialogState extends State<_ModeratorDialog>
    with WidgetsBindingObserver {
  bool visible = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => visible = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.visibility_outlined, size: 32),
    title: Text(visible ? '主持人上帝视角' : '请交给主持人 ${widget.name}'),
    content: SingleChildScrollView(
      child: Text(
        visible ? widget.overview : '此处包含全部身份和词语，请勿让玩家看到屏幕。',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
    actions: [
      if (!visible)
        FilledButton(
          onPressed: () => setState(() => visible = true),
          child: const Text('我是主持人，查看'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
    ],
  );
}
