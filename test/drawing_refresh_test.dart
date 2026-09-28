import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/game_surface.dart';
import 'package:party_hub/games/session.dart';

Finder drawingCanvas() => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_SketchPainter',
);

Widget drawingPage(
  Sketch ink,
  VoidCallback onChanged, {
  bool editable = true,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: GameSurface(
        step: const GameStep(title: '画画', body: '', drawing: true),
        ink: ink,
        onAction: (_, _) {},
        onInkChanged: onChanged,
        canDraw: editable,
        version: 0,
      ),
    ),
  ),
);

void main() {
  testWidgets('拖动画笔直接重绘，结束一笔才通知外层，撤销仍生效', (tester) async {
    final ink = <List<Point<double>>>[];
    var changes = 0;
    await tester.pumpWidget(drawingPage(ink, () => changes++));
    await tester.ensureVisible(drawingCanvas());
    await tester.pumpAndSettle();
    final render = tester.renderObject(drawingCanvas());
    var builds = 0;
    var paints = 0;
    final previousBuildHook = debugOnRebuildDirtyWidget;
    final previousPaintHook = debugOnProfilePaint;
    try {
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (element.widget.runtimeType.toString() == '_SketchBoard') {
          builds++;
        }
      };
      debugOnProfilePaint = (object) {
        if (identical(object, render)) {
          paints++;
        }
      };
      final gesture = await tester.startGesture(
        tester.getCenter(drawingCanvas()) - const Offset(80, 0),
      );
      for (var i = 0; i < 40; i++) {
        await gesture.moveBy(Offset(4, i.isEven ? 2 : -2));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(ink.single.length, greaterThan(25));
      expect(paints, greaterThan(25));
      expect(builds, 0);
      expect(changes, 0);
      await gesture.up();
      await tester.pump();
      expect(changes, 1);
      expect(builds, 1);
    } finally {
      debugOnRebuildDirtyWidget = previousBuildHook;
      debugOnProfilePaint = previousPaintHook;
    }
    await tester.ensureVisible(find.text('撤销一笔'));
    await tester.tap(find.text('撤销一笔'));
    await tester.pump();
    expect(ink, isEmpty);
    expect(changes, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('只读画板不能修改笔迹', (tester) async {
    final ink = <List<Point<double>>>[
      [const Point(.1, .1), const Point(.2, .2)],
    ];
    var changes = 0;
    await tester.pumpWidget(drawingPage(ink, () => changes++, editable: false));
    await tester.ensureVisible(drawingCanvas());
    await tester.pumpAndSettle();
    await tester.drag(drawingCanvas(), const Offset(100, 0));
    await tester.pump();
    expect(ink, [
      [const Point(.1, .1), const Point(.2, .2)],
    ]);
    expect(changes, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
