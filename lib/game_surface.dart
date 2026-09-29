import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'games/session.dart';

export 'game_dialogs.dart';

part 'game_board.dart';
part 'sketch_board.dart';

/// 同机与联机共用对局界面；联机传入的 step 已在服务器按玩家权限过滤。
class GameSurface extends StatefulWidget {
  // remainingSeconds 映射私有字段，使 getter 能优先读 remainingClock。
  const GameSurface({
    super.key,
    required this.step,
    required this.ink,
    required this.onAction,
    required this.onInkChanged,
    required this.canDraw,
    required this.version,
    this.onInkProgress,
    int? remainingSeconds,
    this.remainingClock,
    this.hideClock = false,
    this.enabled = true,
    this.finished = false,
    // ignore: prefer_initializing_formals
  }) : _remainingSeconds = remainingSeconds;
  final GameStep step;
  final Sketch ink;
  final void Function(String, String) onAction;
  final VoidCallback onInkChanged;
  final VoidCallback? onInkProgress;
  final bool canDraw;
  final int version;
  final int? _remainingSeconds;

  /// 倒计时独立刷新；有值时秒数变化不必重建整个 [GameSurface]。
  final ValueListenable<int?>? remainingClock;
  final bool hideClock;
  final bool enabled;
  final bool finished;

  /// 当前剩余秒数；优先读 [remainingClock]，供测试与静态传入共用。
  int? get remainingSeconds => remainingClock?.value ?? _remainingSeconds;

  @override
  State<GameSurface> createState() => _GameSurfaceState();
}

class _GameSurfaceState extends State<GameSurface> with WidgetsBindingObserver {
  final input = TextEditingController();
  bool revealed = false;
  int selectedColor = sketchColors.first;
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

  /// 仅倒计时子树监听秒数；其余对局 UI 不随每秒刷新。
  Widget listenRemaining(Widget Function(int? seconds) builder) {
    final clock = widget.remainingClock;
    if (clock != null) {
      return ListenableBuilder(
        listenable: clock,
        builder: (context, _) => builder(clock.value),
      );
    }
    return builder(widget.remainingSeconds);
  }

  void act(String action) {
    final guessing = widget.step.drawing && action.startsWith('g');
    if (!guessing) {
      FocusScope.of(context).unfocus();
    }
    widget.onAction(action, input.text);
    if (guessing) {
      input.clear();
    }
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

  Widget liveDrawing(BuildContext context) {
    final step = widget.step;
    final colors = Theme.of(context).colorScheme;
    final guesses = step.options
        .where((option) => option.id.startsWith('g'))
        .toList();
    final endings = step.options.where((option) => !option.id.startsWith('g'));
    const colorNames = ['黑色', '红色', '橙色', '绿色', '蓝色', '紫色'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                step.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            listenRemaining((seconds) {
              if (seconds == null) {
                return const SizedBox.shrink();
              }
              return Chip(
                avatar: Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: seconds <= 10 ? colors.error : colors.primary,
                ),
                label: Text(
                  '$seconds 秒',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: seconds <= 10 ? colors.error : colors.primary,
                  ),
                ),
              );
            }),
          ],
        ),
        Text(
          widget.canDraw
              ? '你来画，其他人随时猜 · 禁止写答案或拼音'
              : guesses.isNotEmpty
              ? '边看边猜，想到答案就提交'
              : '你已猜中，继续观看画画吧',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (step.drawingHint case final hint?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hint,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final size = min(
              constraints.maxWidth,
              max(140.0, media.size.height - media.viewInsets.bottom - 350),
            );
            return Center(
              child: SizedBox(
                width: size,
                child: _SketchBoard(
                  sketch: widget.ink,
                  editable: widget.canDraw && widget.enabled,
                  version: widget.version,
                  color: selectedColor,
                  onProgress: widget.onInkProgress,
                  onChanged: () {
                    setState(() {});
                    widget.onInkChanged();
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (widget.canDraw) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < sketchColors.length; i++)
                Semantics(
                  selected: selectedColor == sketchColors[i],
                  child: IconButton(
                    tooltip: '${colorNames[i]}画笔',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: widget.enabled
                        ? () => setState(() => selectedColor = sketchColors[i])
                        : null,
                    icon: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(sketchColors[i]),
                        shape: BoxShape.circle,
                      ),
                      child: selectedColor == sketchColors[i]
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: i == 2 ? Colors.black : Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: '撤销一笔',
                onPressed: widget.enabled && widget.ink.isNotEmpty
                    ? () {
                        setState(() => widget.ink.removeLast());
                        widget.onInkChanged();
                      }
                    : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              IconButton(
                tooltip: '清空画板',
                onPressed: widget.enabled && widget.ink.isNotEmpty
                    ? clearDrawing
                    : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              const Spacer(),
              for (final option in endings)
                TextButton(
                  onPressed: widget.enabled ? () => act(option.id) : null,
                  child: Text(option.label),
                ),
            ],
          ),
        ],
        if (guesses.isNotEmpty) ...[
          TextField(
            controller: input,
            enabled: widget.enabled,
            maxLength: 120,
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(
              labelText: '输入你的猜测',
              counterText: '',
              suffixIcon: guesses.length == 1
                  ? IconButton(
                      tooltip: '提交猜词',
                      onPressed: widget.enabled
                          ? () => act(guesses.single.id)
                          : null,
                      icon: const Icon(Icons.send_rounded),
                    )
                  : null,
            ),
            onSubmitted: guesses.length == 1
                ? (_) => act(guesses.single.id)
                : null,
          ),
          if (guesses.length > 1)
            Wrap(
              spacing: 8,
              children: [
                for (final option in guesses)
                  TextButton(
                    onPressed: widget.enabled ? () => act(option.id) : null,
                    child: Text(option.label),
                  ),
              ],
            ),
        ],
        if (step.guessMessages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 88),
              child: ListView(
                shrinkWrap: true,
                reverse: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final message in step.guessMessages.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final hidden = step.privateFor != null && !revealed;
    final colors = Theme.of(context).colorScheme;
    final liveGuessing = step.drawing && step.inputLabel != null;
    if (liveGuessing && !hidden) {
      return liveDrawing(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        listenRemaining((remaining) {
          if (remaining == null || widget.hideClock) {
            return const SizedBox.shrink();
          }
          return Padding(
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
          );
        }),
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
                    fontSize: 12,
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
                          fontSize: 12,
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
              version: widget.version,
              onProgress: widget.onInkProgress,
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
                                  fontSize: 11,
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
