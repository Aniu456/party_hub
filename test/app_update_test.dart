import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ota_update/ota_update.dart';
import 'package:party_hub/update/app_update.dart';

Map<String, Object> manifest({String version = '1.2.0', int build = 12}) => {
  'version': version,
  'build_number': build,
  'apk_url':
      'https://github.com/Aniu456/party_hub/releases/download/'
      'v$version+$build/party-hub.apk',
  'sha256': 'a' * 64,
};

class RealHttpOverrides extends HttpOverrides {}

void main() {
  test('仅更高构建号可更新，同名新构建可以更新，旧版不能降级', () {
    final release = AppRelease.fromJson(manifest());
    expect(release.isNewerThan('11'), isTrue);
    expect(release.isNewerThan('12'), isFalse);
    expect(release.isNewerThan('13'), isFalse);
    expect(() => release.isNewerThan('unknown'), throwsFormatException);
    expect(AppRelease.fromJson(manifest(build: 13)).isNewerThan('12'), isTrue);
  });

  test('拒绝缺失校验值、预发布版本、错误构建号和跨仓库下载地址', () {
    for (final invalid in [
      null,
      {...manifest()}..remove('sha256'),
      {...manifest(), 'sha256': 'bad'},
      {...manifest(), 'version': '1.2.0-beta'},
      {...manifest(), 'build_number': '12'},
      {...manifest(), 'build_number': 0},
      {...manifest(), 'build_number': 2100000001},
      {...manifest(), 'apk_url': 'https://example.com/app.apk'},
      {
        ...manifest(),
        'apk_url': 'https://github.com/other/app/releases/download/v1.2.0+12/party-hub.apk',
      },
      {...manifest(), 'apk_url': '${manifest()['apk_url']}?redirect=other'},
      {
        ...manifest(),
        'apk_url': '${manifest()['apk_url']}'.replaceFirst('https:', 'http:'),
      },
      {
        ...manifest(),
        'apk_url': '${manifest()['apk_url']}'.replaceFirst('+12/', '+11/'),
      },
    ]) {
      expect(() => AppRelease.fromJson(invalid), throwsFormatException);
    }
  });

  test('读取发布清单；404 无发布，服务错误和损坏清单不会假报最新版', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        switch (request.uri.path) {
          case '/valid':
            request.response.write(jsonEncode(manifest()));
          case '/missing':
            request.response.statusCode = HttpStatus.notFound;
          case '/failed':
            request.response.statusCode = HttpStatus.serviceUnavailable;
          case '/large':
            request.response.write('a' * (65 * 1024));
          default:
            request.response.write('<html>invalid response</html>');
        }
        await request.response.close();
      });
      Uri url(String path) =>
          Uri.parse('http://127.0.0.1:${server.port}/$path');
      expect(
        (await fetchAppRelease(manifestUri: url('valid')))!.buildNumber,
        12,
      );
      expect(await fetchAppRelease(manifestUri: url('missing')), isNull);
      await expectLater(
        fetchAppRelease(manifestUri: url('failed')),
        throwsA(isA<HttpException>()),
      );
      await expectLater(
        fetchAppRelease(manifestUri: url('invalid')),
        throwsFormatException,
      );
      await expectLater(
        fetchAppRelease(manifestUri: url('large')),
        throwsFormatException,
      );
    }, RealHttpOverrides());
  });

  testWidgets('下载前须确认，并将 URL 和校验值传给原生安装器', (tester) async {
    const channel = MethodChannel('sk.fourq.ota_update/stream');
    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    MethodCall? downloadCall;
    var listenCount = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'listen') {
        listenCount++;
        downloadCall = call;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(
      MaterialApp(
        home: AppUpdateDialog(release: AppRelease.fromJson(manifest())),
      ),
    );
    expect(downloadCall, isNull);
    await tester.tap(find.text('下载更新'));
    await tester.pump();
    expect(downloadCall!.arguments['url'], manifest()['apk_url']);
    expect(downloadCall!.arguments['checksum'], manifest()['sha256']);
    expect(find.text('取消下载'), findsOneWidget);
    Future<void> event(OtaStatus status, [String value = '']) async {
      await messenger.handlePlatformMessage(
        channel.name,
        codec.encodeSuccessEnvelope([status.index.toString(), value]),
        (_) {},
      );
      await tester.pump();
    }

    await event(OtaStatus.DOWNLOADING, '42');
    expect(find.text('正在下载 42%'), findsOneWidget);
    await event(OtaStatus.CHECKSUM_ERROR);
    await messenger.handlePlatformMessage(channel.name, null, (_) {});
    await tester.pump();
    expect(find.text('安装包校验失败，已停止安装，请重新下载。'), findsOneWidget);
    expect(find.text('重新下载'), findsOneWidget);
    await tester.tap(find.text('重新下载'));
    await tester.pump();
    await tester.pump();
    expect(listenCount, 2);
    expect(find.text('取消下载'), findsOneWidget);
    await event(OtaStatus.INSTALLING);
    expect(find.textContaining('已打开系统安装界面'), findsOneWidget);
    expect(find.textContaining('更新成功'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
