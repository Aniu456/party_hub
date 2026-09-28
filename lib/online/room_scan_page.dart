import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_style.dart';
import 'room_invite.dart';

class RoomScanPage extends StatefulWidget {
  const RoomScanPage({super.key});

  @override
  State<RoomScanPage> createState() => _RoomScanPageState();
}

class _RoomScanPageState extends State<RoomScanPage> {
  bool handled = false;
  bool invalidCode = false;

  void onDetect(BarcodeCapture capture) {
    if (handled || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    for (final barcode in capture.barcodes) {
      if (barcode.format != BarcodeFormat.qrCode) {
        continue;
      }
      final code = parseRoomInvite(barcode.rawValue);
      if (code != null) {
        handled = true;
        Navigator.pop(context, code);
        return;
      }
    }
    if (!invalidCode && capture.barcodes.isNotEmpty) {
      setState(() => invalidCode = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('扫码加入')),
    body: PageContent(
      children: [
        const Text('对准朋友房间里的邀请二维码'),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: min(380, MediaQuery.sizeOf(context).height * 0.5),
            // 使用组件自带的控制器，自动处理前后台暂停与相机释放。
            child: MobileScanner(
              onDetect: onDetect,
              errorBuilder: (context, error) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? '需要相机权限才能扫码。\n请在系统设置中允许相机，返回后重新打开扫码。\n也可以手动输入房间码。'
                          : '相机暂不可用，请重新打开扫码或手动输入房间码。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InfoNote(
          invalidCode
              ? '这不是有效的房间邀请二维码，请扫描朋友房间中展示的二维码。'
              : '识别成功后返回加入页，确认昵称即可加入。',
          error: invalidCode,
          icon: Icons.qr_code_scanner_rounded,
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('改为输入房间码'),
        ),
      ],
    ),
  );
}
