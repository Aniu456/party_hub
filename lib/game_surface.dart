import 'dart:math';

import 'package:flutter/material.dart';

import 'app_style.dart';
import 'games/session.dart';

/// 同机与联机共用对局界面；联机传入的 step 已在服务器按玩家权限过滤。
class GameSurface extends StatefulWidget {
  const GameSurface({
    super.key,
    required this.step,
    required this.ink,
    required this.onAction,
    required this.onInkChanged,
    required this.canDraw,
    required this.version,
    this.remainingSeconds,
    this.hideClock = false,
    this.enabled = true,
    this.finished = false,
  });
  final GameStep step;
  final Sketch ink;
  final void Function(String, String) onAction;
  final VoidCallback onInkChanged;
  final bool canDraw;
  final int version;
  final int? remainingSeconds;
  final bool hideClock;
  final bool enabled;
  final bool finished;
  @override
  State<GameSurface> createState() => _GameSurfaceState();
}

class _GameSurfaceState extends State<GameSurface> with WidgetsBindingObserver {
  final input = TextEditingController();
  bool revealed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(GameSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version) {
      revealed = false;
      input.clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => revealed = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    super.dispose();
  }

  void act(String action) {
    FocusScope.of(context).unfocus();
    widget.onAction(action, input.text);
  }

  Future<void> clearDrawing() async {
    final version = widget.version;
    final ink = widget.ink;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空这幅画？'),
        content: const Text('当前笔迹会全部清除。如果只画错了一笔，可以先用撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留画作'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    // 确认期间可能超时或切换回合，不能清掉下一位玩家的新画作。
    if (confirmed == true &&
        mounted &&
        widget.version == version &&
        identical(widget.ink, ink) &&
        widget.canDraw &&
        widget.enabled) {
      setState(ink.clear);
      widget.onInkChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final hidden = step.privateFor != null && !revealed;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.remainingSeconds case final remaining?
            when !widget.hideClock)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (step.seconds case final total? when total > 0)
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                value: (remaining / total).clamp(0.0, 1.0),
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                                backgroundColor: colors.surfaceContainerHighest,
                                color: remaining <= 10
                                    ? colors.error
                                    : colors.primary,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$remaining',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: remaining <= 10
                                          ? colors.error
                                          : colors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '回合计时',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '剩余 $remaining 秒',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: remaining <= 10
                                    ? colors.error
                                    : colors.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (hidden) ...[
          SurfaceCard(
            color: colors.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                SizedBox(
                  width: 144,
                  height: 144,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipOval(child: const PeepPortrait(index: 0)),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.secondaryContainer,
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 22,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '专属你的秘密',
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '请交给 ${step.privateFor}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: colors.onSecondaryContainer),
                ),
                const SizedBox(height: 12),
                Text(
                  '其他人请暂时回避屏幕。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSecondaryContainer),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.enabled
                        ? () => setState(() => revealed = true)
                        : null,
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text('我是本人，查看'),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          SurfaceCard(
            color: widget.finished ? colors.secondaryContainer : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.finished
                          ? Icons.emoji_events_outlined
                          : step.privateFor != null
                          ? Icons.lock_open_rounded
                          : Icons.play_circle_outline_rounded,
                      size: widget.finished ? 32 : 22,
                      color: widget.finished
                          ? colors.onSecondaryContainer
                          : colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.finished
                            ? '这一局，精彩落幕'
                            : step.privateFor != null
                            ? '仅本人可见'
                            : '当前回合',
                        style: TextStyle(
                          color: widget.finished
                              ? colors.onSecondaryContainer
                              : colors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: widget.finished
                        ? colors.onSecondaryContainer
                        : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  step.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: widget.finished
                        ? colors.onSecondaryContainer
                        : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (step.drawing) ...[
            _SketchBoard(
              sketch: widget.ink,
              editable: widget.canDraw && widget.enabled,
              onChanged: () {
                setState(() {});
                widget.onInkChanged();
              },
            ),
            if (widget.canDraw)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: widget.enabled && widget.ink.isNotEmpty
                        ? () {
                            setState(() => widget.ink.removeLast());
                            widget.onInkChanged();
                          }
                        : null,
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    label: const Text('撤销一笔'),
                  ),
                  TextButton.icon(
                    onPressed: widget.enabled && widget.ink.isNotEmpty
                        ? clearDrawing
                        : null,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('清空画板'),
                  ),
                ],
              ),
          ],
          if (step.sketch != null)
            _SketchBoard(
              sketch: step.sketch!,
              editable: false,
              onChanged: () {},
            ),
          for (var i = 0; i < step.gallery.length; i++) ...[
            Text('画作 ${i + 1}'),
            _SketchBoard(
              sketch: step.gallery[i],
              editable: false,
              onChanged: () {},
            ),
            const SizedBox(height: 12),
          ],
          if (step.cells.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GameBoard(
                step: step,
                enabled: widget.enabled,
                onAction: act,
              ),
            ),
          if (step.inputLabel != null && step.options.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: input,
                enabled: widget.enabled,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: step.inputLabel,
                  counterText: '',
                ),
                onSubmitted: step.options.length == 1
                    ? (_) => act(step.options.first.id)
                    : null,
              ),
            ),
          for (final (index, option) in step.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: step.options.length == 1
                      ? colors.primary
                      : colors.surface,
                  foregroundColor: step.options.length == 1
                      ? colors.onPrimary
                      : colors.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  side: step.options.length == 1
                      ? BorderSide.none
                      : BorderSide(color: colors.outlineVariant),
                ),
                onPressed: widget.enabled ? () => act(option.id) : null,
                child: step.options.length == 1
                    ? Text(option.label, textAlign: TextAlign.center)
                    : Row(
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: widget.enabled
                                    ? colors.primaryContainer
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${index + 1}'.padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.enabled
                                      ? colors.onPrimaryContainer
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(option.label)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          if (step.privateFor != null)
            TextButton.icon(
              onPressed: () => setState(() => revealed = false),
              icon: const Icon(Icons.visibility_off_outlined, size: 20),
              label: const Text('遮住屏幕'),
            ),
        ],
      ],
    );
  }
}

class _GameBoard extends StatefulWidget {
  const _GameBoard({
    required this.step,
    required this.enabled,
    required this.onAction,
  });
  final GameStep step;
  final bool enabled;
  final ValueChanged<String> onAction;
  @override
  State<_GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<_GameBoard> {
  final transform = TransformationController();
  bool zoomed = false;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final gomoku = step.columns == 15;
    final board = GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: step.cells.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: step.columns,
        crossAxisSpacing: gomoku ? 1 : 4,
        mainAxisSpacing: gomoku ? 1 : 4,
      ),
      itemBuilder: (context, index) {
        final cell = step.cells[index];
        final canTap = cell.id.isNotEmpty && widget.enabled;
        return Semantics(
          label:
              '第 ${index ~/ step.columns + 1} 行，第 ${index % step.columns + 1} 列 ${cell.label}',
          button: cell.id.isNotEmpty,
          enabled: canTap,
          child: Material(
            color: gomoku
                ? const Color(0xFFF2E5C8)
                : switch (cell.tone) {
                    1 => const Color(0xFFF3D6C3),
                    2 => const Color(0xFFDCE6F2),
                    3 => const Color(0xFFD3D7CD),
                    _ => const Color(0xFFE9EDDD),
                  },
            borderRadius: BorderRadius.circular(gomoku ? 0 : 8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: canTap ? () => widget.onAction(cell.id) : null,
              child: Center(
                child: gomoku && cell.tone > 0
                    ? FractionallySizedBox(
                        widthFactor: .76,
                        heightFactor: .76,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cell.tone == 1 ? partyInk : Colors.white,
                            border: Border.all(color: partyInk),
                          ),
                        ),
                      )
                    : Text(
                        cell.label,
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14, color: partyInk),
                      ),
              ),
            ),
          ),
        );
      },
    );
    if (!gomoku) {
      return board;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('可放大棋盘，拖动后落子')),
            IconButton(
              tooltip: zoomed ? '还原棋盘' : '放大棋盘',
              onPressed: () => setState(() {
                zoomed = !zoomed;
                transform.value = zoomed
                    ? Matrix4.diagonal3Values(2.5, 2.5, 1)
                    : Matrix4.identity();
              }),
              icon: Icon(
                zoomed ? Icons.zoom_out_rounded : Icons.zoom_in_rounded,
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
              color: const Color(0xFFC6B58E),
              child: InteractiveViewer(
                transformationController: transform,
                minScale: 1,
                maxScale: 3,
                panEnabled: zoomed,
                onInteractionEnd: (_) => setState(
                  () => zoomed = transform.value.getMaxScaleOnAxis() > 1,
                ),
                child: board,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SketchBoard extends StatefulWidget {
  const _SketchBoard({
    required this.sketch,
    required this.editable,
    required this.onChanged,
  });
  final Sketch sketch;
  final bool editable;
  final VoidCallback onChanged;
  @override
  State<_SketchBoard> createState() => _SketchBoardState();
}

class _SketchBoardState extends State<_SketchBoard> {
  Point<double> point(Offset offset, double width, double height) =>
      Point((offset.dx / width).clamp(0, 1), (offset.dy / height).clamp(0, 1));
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onPanStart: widget.editable
            ? (details) {
                if (widget.sketch.length >= 300) {
                  return;
                }
                widget.sketch.add([
                  point(
                    details.localPosition,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                ]);
                setState(() {});
              }
            : null,
        onPanUpdate: widget.editable
            ? (details) {
                if (widget.sketch.isEmpty ||
                    widget.sketch.last.length >= 2000) {
                  return;
                }
                widget.sketch.last.add(
                  point(
                    details.localPosition,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                );
                setState(() {});
              }
            : null,
        onPanEnd: widget.editable ? (_) => widget.onChanged() : null,
        onPanCancel: widget.editable ? widget.onChanged : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CustomPaint(
            painter: _SketchPainter(widget.sketch),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

class _SketchPainter extends CustomPainter {
  _SketchPainter(this.sketch);
  final Sketch sketch;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in sketch) {
      if (stroke.isEmpty) {
        continue;
      }
      final path = Path()
        ..moveTo(stroke.first.x * size.width, stroke.first.y * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.x * size.width, stroke.first.y * size.height),
          1.5,
          Paint()..color = const Color(0xFF222222),
        );
      } else {
        canvas.drawPath(path, paint);
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SketchPainter oldDelegate) => true;
}

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
