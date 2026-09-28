import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本机昵称；不创建账号，也不作为联机权限凭证。
class UserProfile extends ChangeNotifier {
  UserProfile(this._preferences);
  static const _nicknameKey = 'party_hub.nickname';
  final SharedPreferencesAsync _preferences;
  String _nickname = '';
  String get nickname => _nickname;
  String? storageError;

  static String? validateNickname(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return '请填写你的昵称';
    }
    if (name.length > 20) {
      return '昵称最多 20 个字符';
    }
    return null;
  }

  Future<void> load() async {
    try {
      _nickname = (await _preferences.getString(_nicknameKey))?.trim() ?? '';
      storageError = null;
    } on PlatformException catch (error, stack) {
      storageError = '暂时无法读取本机昵称，请在用户中心重新保存。';
      debugPrintStack(label: '读取昵称失败：$error', stackTrace: stack);
    }
    notifyListeners();
  }

  /// 仅在存储成功后更新内存和界面；失败时保留旧昵称。
  Future<bool> saveNickname(String value) async {
    final validation = validateNickname(value);
    if (validation != null) {
      throw ArgumentError(validation);
    }
    final name = value.trim();
    if (name == _nickname && storageError == null) {
      return true;
    }
    try {
      await _preferences.setString(_nicknameKey, name);
      _nickname = name;
      storageError = null;
      notifyListeners();
      return true;
    } on PlatformException catch (error, stack) {
      storageError = '昵称未能保存，请重试。';
      debugPrintStack(label: '保存昵称失败：$error', stackTrace: stack);
      notifyListeners();
      return false;
    }
  }
}

class UserProfileScope extends InheritedNotifier<UserProfile> {
  const UserProfileScope({
    super.key,
    required UserProfile? profile,
    required super.child,
  }) : super(notifier: profile);

  static UserProfile? watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UserProfileScope>()?.notifier;
  static UserProfile? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<UserProfileScope>()?.notifier;
}
