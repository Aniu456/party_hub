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
  Widget build(BuildContext context) => Dialog(
    constraints: const BoxConstraints(maxWidth: 280),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '邀请朋友',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) => QrImageView(
              data: roomInviteData(code),
              size: min(168, constraints.maxWidth),
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.white,
              semanticsLabel: '房间 $code 的加入二维码',
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code,
              semanticsLabel: '房间码 ${code.split('').join(' ')}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '打开 App 扫码加入',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
