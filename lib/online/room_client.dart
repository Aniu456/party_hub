import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../games/session.dart';
import '../games/wire.dart';

const roomEndpoint = String.fromEnvironment(
  'PARTY_HUB_WS',
  defaultValue: 'ws://127.0.0.1:18991/ws',
);

class RoomMember {
  const RoomMember(this.name, this.ready, this.online);
  final String name;
  final bool ready;
  final bool online;
}

class RoomSnapshot {
  RoomSnapshot(Map<String, Object?> data)
    : code = wireString(data, 'room'),
      gameId = wireString(data, 'gameId'),
      seat = wireInt(data, 'seat'),
      host = wireInt(data, 'host'),
      revision = wireInt(data, 'revision'),
      clockRevision = wireInt(data, 'clockRevision'),
      elapsedMs = wireInt(data, 'elapsedMs'),
      finished = wireBool(data, 'finished'),
      canDraw = wireBool(data, 'canDraw'),
      message = wireString(data, 'message'),
      moderatorOverview = data['moderatorOverview'] == null
          ? null
          : wireString(data, 'moderatorOverview'),
      members = [for (final value in wireList(data, 'members')) _member(value)],
      scores = [for (final value in wireList(data, 'scores')) _integer(value)],
      teamScores = [
        for (final value in wireList(data, 'teamScores')) _integer(value),
      ],
      ink = decodeSketch(data['ink']),
      step = data['step'] == null ? null : decodeStep(wireMap(data['step'])) {
    if (members.isEmpty ||
        seat < 0 ||
        seat >= members.length ||
        host < 0 ||
        host >= members.length) {
      throw const FormatException('房间成员格式不正确');
    }
  }
  static int _integer(Object? value) {
    if (value is! int) {
      throw const FormatException('分数格式不正确');
    }
    return value;
  }

  static RoomMember _member(Object? value) {
    final data = wireMap(value);
    return RoomMember(
      wireString(data, 'name'),
      wireBool(data, 'ready'),
      wireBool(data, 'online'),
    );
  }

  final String code;
  final String gameId;
  final int seat;
  final int host;
  final int revision;
  final int clockRevision;
  final int elapsedMs;
  final bool finished;
  final bool canDraw;
  final String message;
  final String? moderatorOverview;
  final List<RoomMember> members;
  final List<int> scores;
  final List<int> teamScores;
  final Sketch ink;
  final GameStep? step;
}

class RoomClient extends ChangeNotifier {
  RoomClient({required this.name, this.gameId, this.joinCode});
  final String name;
  final String? gameId;
  final String? joinCode;
  String? _token;
  String? _code;
  WebSocket? _socket;
  Timer? _retry;
  bool _closed = false;
  bool connecting = false;
  bool connected = false;
  bool pending = false;
  String error = '';
  RoomSnapshot? state;
  final snapshotAge = Stopwatch();

  Future<void> connect() async {
    if (_closed || connecting) {
      return;
    }
    connecting = true;
    error = '';
    notifyListeners();
    try {
      final socket = await WebSocket.connect(roomEndpoint)
          .timeout(const Duration(seconds: 12));
      if (_closed) {
        await socket.close();
        return;
      }
      _socket = socket;
      socket.pingInterval = const Duration(seconds: 20);
      connected = true;
      socket.listen(
        (Object? raw) {
          try {
            if (raw is! String) {
              throw const FormatException('服务器消息格式不正确');
            }
            final data = wireMap(jsonDecode(raw));
            switch (wireString(data, 'type')) {
              case 'welcome':
                _token = wireString(data, 'token');
                _code = wireString(data, 'room');
              case 'state':
                state = RoomSnapshot(data);
                snapshotAge
                  ..reset()
                  ..start();
                pending = false;
              case 'error':
                error = wireString(data, 'message');
                pending = false;
              default:
                throw const FormatException('未知服务器消息');
            }
            if (!_closed) {
              notifyListeners();
            }
          } on FormatException catch (exception) {
            error = exception.message;
            pending = false;
            if (!_closed) {
              notifyListeners();
            }
          }
        },
        onError: (Object exception) {
          _disconnected(socket);
        },
        onDone: () => _disconnected(socket),
      );
      socket.add(
        jsonEncode(
          _token != null
              ? {'type': 'resume', 'room': _code, 'token': _token}
              : gameId != null
              ? {'type': 'create', 'name': name, 'gameId': gameId}
              : {'type': 'join', 'name': name, 'room': joinCode},
        ),
      );
    } on SocketException {
      error = '连接失败，请检查网络后重试';
      _scheduleRetry();
    } on WebSocketException {
      error = '无法连接游戏服务，请稍后重试';
      _scheduleRetry();
    } on TimeoutException {
      error = '连接超时，请稍后重试';
      _scheduleRetry();
    } on HandshakeException {
      error = '无法验证服务器安全连接';
    } finally {
      connecting = false;
      if (!_closed) {
        notifyListeners();
      }
    }
  }

  void _scheduleRetry() {
    if (!_closed && _token != null) {
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 3), () => unawaited(connect()));
    }
  }

  void _disconnected(WebSocket socket) {
    if (_closed || socket != _socket) {
      return;
    }
    connected = false;
    pending = false;
    error = '连接已断开，正在尝试恢复原来的座位';
    _scheduleRetry();
    notifyListeners();
  }

  void send(String type, {String? action, String input = '', Sketch? ink}) {
    if (!connected || _socket == null) {
      return;
    }
    if (type != 'ink') {
      pending = true;
    }
    error = '';
    _socket!.add(
      jsonEncode({
        'type': type,
        'revision': state?.revision,
        'action': ?action,
        'input': input,
        if (ink != null) 'ink': encodeSketch(ink),
      }),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    _retry?.cancel();
    if (connected) {
      _socket?.add(jsonEncode({'type': 'leave'}));
    }
    unawaited(_socket?.close() ?? Future<void>.value());
    snapshotAge.stop();
    super.dispose();
  }
}
