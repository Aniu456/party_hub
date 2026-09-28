import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

String roomInviteData(String code) {
  if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
    throw ArgumentError.value(code, 'code', '房间码必须是 6 位数字');
  }
  return 'partyhub://join/$code';
}

/// 扫码只提取公开房间码，不接受外部地址、会话令牌或其他指令。
String? parseRoomInvite(String? data) {
  if (data == null || data.length != 22) {
    return null;
  }
  return RegExp(r'^partyhub://join/([0-9]{6})$').firstMatch(data)?.group(1);
}

class RoomInviteDialog extends StatelessWidget {
  const RoomInviteDialog({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('邀请朋友扫码加入'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QrImageView(
          data: roomInviteData(code),
          size: min(220, MediaQuery.sizeOf(context).width - 96),
          padding: const EdgeInsets.all(28),
          backgroundColor: Colors.white,
          semanticsLabel: '房间 $code 的加入二维码',
        ),
        const SizedBox(height: 16),
        Text(
          code,
          semanticsLabel: '房间码 ${code.split('').join(' ')}',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '朋友打开 App → 加入房间 → 扫码加入\n也可以输入上方六位房间码',
          textAlign: TextAlign.center,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
    ],
  );
}
