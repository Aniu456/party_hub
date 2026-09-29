import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/open_peeps.dart';

void main() {
  test('随包 peep 仅半身像，且文件真实存在', () {
    expect(peepAssets, isNotEmpty);
    expect(peepAssets.length, 49);
    expect(peepAssets.toSet().length, peepAssets.length);
    for (final path in peepAssets) {
      expect(path, startsWith('assets/open_peeps/blue/busts/'));
      expect(path, isNot(contains('/standing/')));
      expect(path, isNot(contains('/sitting/')));
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('pubspec 只声明 busts，工作区无 standing/sitting 目录', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/open_peeps/blue/busts/'));
    expect(pubspec, isNot(contains('assets/open_peeps/blue/standing/')));
    expect(pubspec, isNot(contains('assets/open_peeps/blue/sitting/')));
    expect(Directory('assets/open_peeps/blue/busts').existsSync(), isTrue);
    expect(Directory('assets/open_peeps/blue/standing').existsSync(), isFalse);
    expect(Directory('assets/open_peeps/blue/sitting').existsSync(), isFalse);
  });
}
