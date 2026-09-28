import 'dart:math';

import 'session.dart';

List<List<List<double>>> encodeSketch(Sketch sketch) => [
  for (final stroke in sketch)
    [
      for (final point in stroke) [point.x, point.y],
    ],
];

Sketch decodeSketch(Object? value) {
  if (value is! List || value.length > 300) {
    throw const FormatException('画作格式不正确');
  }
  var total = 0;
  final result = <List<Point<double>>>[];
  for (final rawStroke in value) {
    if (rawStroke is! List || rawStroke.length > 2000) {
      throw const FormatException('笔迹太长');
    }
    total += rawStroke.length;
    if (total > 12000) {
      throw const FormatException('画作太复杂，请清空重画');
    }
    final stroke = <Point<double>>[];
    for (final point in rawStroke) {
      if (point is! List ||
          point.length != 2 ||
          point[0] is! num ||
          point[1] is! num) {
        throw const FormatException('坐标格式不正确');
      }
      final x = (point[0] as num).toDouble();
      final y = (point[1] as num).toDouble();
      if (!x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1) {
        throw const FormatException('坐标超出画板');
      }
      stroke.add(Point(x, y));
    }
    result.add(stroke);
  }
  return result;
}

Map<String, Object?> encodeStep(GameStep step) => {
  'title': step.title,
  'body': step.body,
  'privateFor': step.privateFor,
  'inputLabel': step.inputLabel,
  'seconds': step.seconds,
  'drawing': step.drawing,
  'sketch': step.sketch == null ? null : encodeSketch(step.sketch!),
  'gallery': [for (final sketch in step.gallery) encodeSketch(sketch)],
  'columns': step.columns,
  'controller': step.controller,
  'options': [
    for (final option in step.options)
      {'id': option.id, 'label': option.label, 'actor': option.actor},
  ],
  'cells': [
    for (final cell in step.cells)
      {'id': cell.id, 'label': cell.label, 'tone': cell.tone},
  ],
};

GameStep decodeStep(Map<String, Object?> data) {
  final columns = wireInt(data, 'columns');
  if (columns < 1 || columns > 20) {
    throw const FormatException('棋盘列数无效');
  }
  return GameStep(
    title: wireString(data, 'title'),
    body: wireString(data, 'body'),
    privateFor: data['privateFor'] == null
        ? null
        : wireString(data, 'privateFor'),
    inputLabel: data['inputLabel'] == null
        ? null
        : wireString(data, 'inputLabel'),
    seconds: data['seconds'] == null ? null : wireInt(data, 'seconds'),
    controller: data['controller'] == null ? null : wireInt(data, 'controller'),
    drawing: wireBool(data, 'drawing'),
    sketch: data['sketch'] == null ? null : decodeSketch(data['sketch']),
    gallery: wireList(data, 'gallery').map(decodeSketch).toList(),
    columns: columns,
    options: [
      for (final value in wireList(data, 'options')) _decodeOption(value),
    ],
    cells: [for (final value in wireList(data, 'cells')) _decodeCell(value)],
  );
}

GameOption _decodeOption(Object? value) {
  final data = wireMap(value);
  return GameOption(
    wireString(data, 'id'),
    wireString(data, 'label'),
    actor: data['actor'] == null ? null : wireInt(data, 'actor'),
  );
}

BoardCell _decodeCell(Object? value) {
  final data = wireMap(value);
  return BoardCell(
    wireString(data, 'id'),
    wireString(data, 'label'),
    tone: wireInt(data, 'tone'),
  );
}

Map<String, Object?> wireMap(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('对象格式不正确');
  }
  return value;
}

String wireString(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! String) {
    throw FormatException('$key 不是文本');
  }
  return value;
}

int wireInt(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! int) {
    throw FormatException('$key 不是整数');
  }
  return value;
}

bool wireBool(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! bool) {
    throw FormatException('$key 不是布尔值');
  }
  return value;
}

List<Object?> wireList(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! List) {
    throw FormatException('$key 不是列表');
  }
  return value;
}
