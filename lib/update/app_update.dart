import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

const updateRepository = 'Aniu456/party_hub';
final updateManifestUri = Uri.parse(
  'https://github.com/$updateRepository/releases/latest/download/update.json',
);

class AppRelease {
  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.sha256,
  });

  final String version;
  final int buildNumber;
  final Uri apkUrl;
  final String sha256;

  factory AppRelease.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('更新信息格式错误');
    }
    final version = value['version'];
    final build = value['build_number'];
    final url = value['apk_url'];
    final checksum = value['sha256'];
    if (version is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        build is! int ||
        build <= 0 ||
        build > 2100000000 ||
        url is! String ||
        checksum is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(checksum)) {
      throw const FormatException('更新信息不完整');
    }
    final uri = Uri.parse(url);
    // 只允许当前仓库、当前版本的安装包，不能由清单跳转到任意下载源。
    final expected = Uri.parse(
      'https://github.com/$updateRepository/releases/download/'
      'v$version+$build/party-hub.apk',
    );
    if (uri != expected) {
      throw const FormatException('安装包地址不属于此版本');
    }
    return AppRelease(
      version: version,
      buildNumber: build,
      apkUrl: uri,
      sha256: checksum.toLowerCase(),
    );
  }

  /// Android 用 versionCode 判断覆盖安装，版本名称不用于替代构建号。
  bool isNewerThan(String installedBuild) {
    final current = int.tryParse(installedBuild);
    if (current == null || current <= 0) {
      throw const FormatException('无法读取当前应用版本');
    }
    return buildNumber > current;
  }
}

/// 未发布首版时返回 null；网络故障、损坏清单不能当作“已是最新版”。
Future<AppRelease?> fetchAppRelease({Uri? manifestUri}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    return await (() async {
      final request = await client.getUrl(manifestUri ?? updateManifestUri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode == HttpStatus.notFound) {
        return null;
      }
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('更新服务返回 ${response.statusCode}');
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > 64 * 1024) {
          throw const FormatException('更新信息过大');
        }
      }
      return AppRelease.fromJson(jsonDecode(utf8.decode(bytes)));
    })().timeout(const Duration(seconds: 15));
  } finally {
    client.close(force: true);
  }
}

bool get supportsAppUpdate => !kIsWeb && Platform.isAndroid;
bool _checkingUpdate = false;

Future<void> checkAppUpdate(
  BuildContext context, {
  bool silently = false,
}) async {
  if (!supportsAppUpdate || _checkingUpdate) {
    return;
  }
  _checkingUpdate = true;
  try {
    final installed = await PackageInfo.fromPlatform();
    final release = await fetchAppRelease();
    if (!context.mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        (silently &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    if (release != null && release.isNewerThan(installed.buildNumber)) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AppUpdateDialog(release: release),
      );
    } else if (!silently) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            release == null
                ? '暂未发布可用更新'
                : '当前已是最新版本 ${installed.version}（${installed.buildNumber}）',
          ),
        ),
      );
    }
  } on Exception {
    if (!silently && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('暂时无法检查更新，请检查网络后重试。')));
    }
  } finally {
    _checkingUpdate = false;
  }
}

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({super.key, required this.release});
  final AppRelease release;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  StreamSubscription<OtaEvent>? subscription;
  OtaUpdate? updater;
  bool downloading = false;
  bool installerOpened = false;
  double? progress;
  String? error;

  @override
  void dispose() {
    subscription?.cancel();
    if (downloading) {
      unawaited(updater?.cancel().catchError((Object _) {}));
    }
    super.dispose();
  }

  void download() {
    if (downloading) {
      return;
    }
    unawaited(subscription?.cancel());
    setState(() {
      downloading = true;
      installerOpened = false;
      progress = null;
      error = null;
    });
    final ota = OtaUpdate();
    updater = ota;
    try {
      subscription = ota
          .execute(
            widget.release.apkUrl.toString(),
            destinationFilename: 'party-hub.apk',
            sha256checksum: widget.release.sha256,
          )
          .listen(
            handleEvent,
            onError: (Object _) => fail('下载失败，请稍后重试。'),
            onDone: () {
              if (mounted && downloading) {
                fail('下载已中断，请重试。');
              }
            },
          );
    } on Exception {
      fail('暂时无法启动更新，请稍后重试。');
    }
  }

  void fail(String message) {
    if (mounted) {
      setState(() {
        downloading = false;
        error = message;
      });
    }
  }

  void handleEvent(OtaEvent event) {
    if (!mounted) {
      return;
    }
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        final percent = double.tryParse(event.value ?? '');
        setState(
          () => progress = percent == null
              ? null
              : (percent / 100).clamp(0.0, 1.0),
        );
      case OtaStatus.INSTALLING:
      case OtaStatus.INSTALLATION_DONE:
        setState(() {
          downloading = false;
          installerOpened = true;
        });
      case OtaStatus.CHECKSUM_ERROR:
        fail('安装包校验失败，已停止安装，请重新下载。');
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        fail('需要允许“安装未知应用”，授权后请重试。');
      case OtaStatus.CANCELED:
        fail('下载已取消，可以稍后再更新。');
      case OtaStatus.ALREADY_RUNNING_ERROR:
      case OtaStatus.INSTALLATION_ERROR:
      case OtaStatus.INTERNAL_ERROR:
      case OtaStatus.DOWNLOAD_ERROR:
        fail('更新未完成，请检查网络及安装权限后重试。');
    }
  }

  Future<void> cancel() async {
    try {
      await updater?.cancel();
    } on Exception {
      fail('暂时无法取消，请稍后重试。');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !downloading,
    child: AlertDialog(
      scrollable: true,
      title: Text('发现新版本 ${widget.release.version}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('版本号 ${widget.release.version}（${widget.release.buildNumber}）'),
          const SizedBox(height: 12),
          const Text('下载完成后会打开系统安装界面，确认后更新。首次更新可能需要允许安装此来源的应用。'),
          if (downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              progress == null
                  ? '正在准备下载…'
                  : '正在下载 ${(progress! * 100).round()}%',
            ),
          ],
          if (installerOpened) ...[
            const SizedBox(height: 12),
            const Text('已打开系统安装界面，请完成安装。若取消或尚未授权，可再次点击下载更新。'),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: downloading ? cancel : () => Navigator.pop(context),
          child: Text(downloading ? '取消下载' : '稍后再说'),
        ),
        FilledButton(
          onPressed: downloading ? null : download,
          child: Text(error == null ? '下载更新' : '重新下载'),
        ),
      ],
    ),
  );
}

class CheckUpdateButton extends StatefulWidget {
  const CheckUpdateButton({super.key});

  @override
  State<CheckUpdateButton> createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends State<CheckUpdateButton> {
  bool checking = false;

  @override
  Widget build(BuildContext context) {
    if (!supportsAppUpdate) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      onPressed: checking
          ? null
          : () async {
              setState(() => checking = true);
              await checkAppUpdate(context);
              if (mounted) {
                setState(() => checking = false);
              }
            },
      icon: const Icon(Icons.system_update_rounded),
      label: Text(checking ? '正在检查更新…' : '检查应用更新'),
    );
  }
}
