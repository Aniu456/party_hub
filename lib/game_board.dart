part of 'game_surface.dart';

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
                        style: const TextStyle(fontSize: 12, color: partyInk),
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
