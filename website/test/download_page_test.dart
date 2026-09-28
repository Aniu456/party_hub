import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub_website/main.dart';
import 'package:url_launcher/link.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Page fits width $width and links to the real APK', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const DownloadApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final links = tester.widgetList<Link>(find.byType(Link));
      expect(
        links.where((link) => link.uri == Uri.base.resolve(apkUrl)).length,
        3,
      );
      expect(
        links.every(
          (link) =>
              link.uri?.hasScheme == true &&
              link.uri?.hasFragment == false &&
              link.uri?.path.contains('/downloads/') == true,
        ),
        isTrue,
      );
      expect(find.text('iPhone 可以下载吗？'), findsOneWidget);

      await tester.ensureVisible(find.text('iPhone 可以下载吗？'));
      await tester.tap(find.text('iPhone 可以下载吗？'));
      await tester.pumpAndSettle();
      expect(find.textContaining('APK 无法在 iPhone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Large text stays usable and install help opens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const DownloadApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('下载或安装遇到问题？'));
    await tester.tap(find.text('下载或安装遇到问题？'));
    await tester.pumpAndSettle();
    expect(find.text('下载与安装帮助'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.text('下载与安装帮助'), findsNothing);
  });
}
