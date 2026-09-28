import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:party_hub/online/room_invite.dart';
import 'package:party_hub/online/room_page.dart';
import 'package:party_hub/online/room_scan_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TestCamera extends MobileScannerPlatform {
  final captures = StreamController<BarcodeCapture?>.broadcast();
  bool denied = false;
  int starts = 0;
  int stops = 0;
  int disposals = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => captures.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts++;
    if (denied) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> dispose() async {
    disposals++;
  }

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  void scan(String data, {BarcodeFormat format = BarcodeFormat.qrCode}) {
    captures.add(
      BarcodeCapture(
        barcodes: [Barcode(rawValue: data, format: format)],
      ),
    );
  }
}

// 广播流取消跨越真实与测试时钟，交替排空两个队列后检查释放回调。
Future<void> flushCameraDisposal(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

void main() {
  late TestCamera camera;
  late MobileScannerPlatform original;
  setUp(() {
    original = MobileScannerPlatform.instance;
    camera = TestCamera();
    MobileScannerController.resetPlatformSessionOwner();
    MobileScannerPlatform.instance = camera;
  });
  tearDown(() async {
    MobileScannerPlatform.instance = original;
    await camera.captures.close();
  });

  test('房间邀请保留前导零，只接受本应用的六位房间码', () {
    expect(parseRoomInvite(roomInviteData('012345')), '012345');
    expect(() => roomInviteData('12345'), throwsArgumentError);
    for (final data in [
      null,
      '',
      '123456',
      'https://example.com/123456',
      'partyhub://join/12345',
      'partyhub://join/1234567',
      'partyhub://join/１２３４５６',
      'partyhub://join/123456?token=secret',
      'partyhub://join/123456#token',
      'partyhub://join/123456\n',
      'partyhub://other/123456',
    ]) {
      expect(parseRoomInvite(data), isNull, reason: '$data');
    }
  });

  testWidgets('小屏大字体仍可显示与关闭邀请二维码', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const RoomInviteDialog(code: '012345'),
              ),
              child: const Text('邀请'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('邀请'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel,
      '房间 012345 的加入二维码',
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomInviteDialog), findsNothing);
  });

  testWidgets('无效码不跳转，有效码只返回一次且保留昵称', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoomEntryPage()));
    await tester.enterText(find.byType(TextFormField).first, '小明');
    await tester.tap(find.text('扫码加入'));
    await tester.pumpAndSettle();
    camera.scan('https://example.com');
    await tester.pumpAndSettle();
    expect(find.textContaining('这不是有效的房间邀请二维码'), findsOneWidget);
    camera.scan(roomInviteData('999999'), format: BarcodeFormat.code128);
    await tester.pumpAndSettle();
    expect(find.byType(RoomScanPage), findsOneWidget);
    camera.scan(roomInviteData('012345'));
    camera.scan(roomInviteData('999999'));
    await tester.pumpAndSettle();
    await flushCameraDisposal(tester);
    expect(find.byType(RoomScanPage), findsNothing);
    expect(find.byType(RoomEntryPage), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '小明',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '012345',
    );
    expect(camera.stops, 1);
    expect(camera.disposals, 1);
  });

  testWidgets('相机权限被拒绝仍能返回手输，保留已有房间码', (tester) async {
    camera.denied = true;
    await tester.pumpWidget(const MaterialApp(home: RoomEntryPage()));
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('扫码加入'));
    await tester.pumpAndSettle();
    expect(find.textContaining('需要相机权限才能扫码'), findsOneWidget);
    await tester.ensureVisible(find.text('改为输入房间码'));
    await tester.tap(find.text('改为输入房间码'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      '123456',
    );
  });

  testWidgets('离开前台暂停相机，返回恢复，退出释放', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoomScanPage()));
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.stops, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await flushCameraDisposal(tester);
    expect(camera.disposals, 1);
  });
}
