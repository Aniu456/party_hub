part of 'game_surface.dart';

class _SketchBoard extends StatefulWidget {
  const _SketchBoard({
    required this.sketch,
    required this.editable,
    required this.onChanged,
    this.onProgress,
    this.version = 0,
    this.color = 0xFF222222,
    this.inkUpdates,
  });
  final Sketch sketch;

  /// 联机时笔迹就地更新（不重建页面），由此通知画板重绘。
  final Listenable? inkUpdates;
  final bool editable;
  final VoidCallback onChanged;
  final VoidCallback? onProgress;
  final int version;
  final int color;
  @override
  State<_SketchBoard> createState() => _SketchBoardState();
}

class _SketchBoardState extends State<_SketchBoard> {
  final repaint = ValueNotifier(0);
  Timer? progressTimer;
  List<Point<double>>? activeStroke;

  void publishProgress() {
    if (widget.onProgress == null || progressTimer != null) {
      return;
    }
    progressTimer = Timer(inkProgressInterval, () {
      progressTimer = null;
      widget.onProgress?.call();
    });
  }

  void finishStroke() {
    progressTimer?.cancel();
    progressTimer = null;
    if (activeStroke == null) {
      return;
    }
    activeStroke = null;
    widget.onChanged();
  }

  @override
  void didUpdateWidget(_SketchBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.version != widget.version || !widget.editable) {
      progressTimer?.cancel();
      progressTimer = null;
      activeStroke = null;
    }
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    repaint.dispose();
    super.dispose();
  }

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
                final stroke = SketchStroke([
                  point(
                    details.localPosition,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                ], color: widget.color);
                activeStroke = stroke;
                widget.sketch.add(stroke);
                repaint.value++;
                publishProgress();
              }
            : null,
        onPanUpdate: widget.editable
            ? (details) {
                final stroke = activeStroke;
                if (stroke == null ||
                    !widget.sketch.contains(stroke) ||
                    stroke.length >= 2000) {
                  return;
                }
                stroke.add(
                  point(
                    details.localPosition,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                );
                repaint.value++;
                publishProgress();
              }
            : null,
        onPanEnd: widget.editable ? (_) => finishStroke() : null,
        onPanCancel: widget.editable ? finishStroke : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _SketchPainter(
                widget.sketch,
                repaint: widget.inkUpdates == null
                    ? repaint
                    : Listenable.merge([repaint, widget.inkUpdates]),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SketchPainter extends CustomPainter {
  _SketchPainter(this.sketch, {super.repaint});
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
      paint.color = Color(
        stroke is SketchStroke ? stroke.color : sketchColors.first,
      );
      final path = Path()
        ..moveTo(stroke.first.x * size.width, stroke.first.y * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.x * size.width, stroke.first.y * size.height),
          1.5,
          Paint()..color = paint.color,
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
