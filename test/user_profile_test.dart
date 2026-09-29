import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/app_style.dart';
import 'package:party_hub/game_catalog.dart';
import 'package:party_hub/local_game_page.dart';
import 'package:party_hub/main.dart';
import 'package:party_hub/online/room_entry_page.dart';
import 'package:party_hub/profile/user_center_page.dart';
import 'package:party_hub/profile/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class TestPreferences extends InMemorySharedPreferencesAsync {
  TestPreferences() : super.empty();
  bool failWrites = false;
  bool failReads = false;
  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    if (failWrites) {
      throw PlatformException(code: 'storage_unavailable');
    }
    return super.setString(key, value, options);
  }

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    if (failReads) {
      throw PlatformException(code: 'storage_unavailable');
    }
    return super.getString(key, options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestPreferences store;
  setUp(() {
    store = TestPreferences();
    SharedPreferencesAsyncPlatform.instance = store;
  });

  test('昵称去除首尾空白，新的用户模型能从存储恢复', () async {
    final profile = UserProfile(SharedPreferencesAsync());
    await profile.load();
    expect(profile.nickname, isEmpty);
    expect(await profile.saveNickname('  小明  '), isTrue);
    final restored = UserProfile(SharedPreferencesAsync());
    await restored.load();
    expect(restored.nickname, '小明');
    expect(restored.storageError, isNull);
  });

  test('无效昵称不会覆盖已经保存的名字', () async {
    final profile = UserProfile(SharedPreferencesAsync());
    await profile.saveNickname('小明');
    await expectLater(profile.saveNickname('  '), throwsArgumentError);
    await expectLater(profile.saveNickname('一' * 21), throwsArgumentError);
    expect(profile.nickname, '小明');
  });

  test('存储失败保留旧昵称并提示，之后可以重试', () async {
    final profile = UserProfile(SharedPreferencesAsync());
    await profile.saveNickname('小明');
    store.failWrites = true;
    expect(await profile.saveNickname('阿蓝'), isFalse);
    expect(profile.nickname, '小明');
    expect(profile.storageError, contains('未能保存'));
    store.failWrites = false;
    expect(await profile.saveNickname('阿蓝'), isTrue);
    final restored = UserProfile(SharedPreferencesAsync());
    await restored.load();
    expect(restored.nickname, '阿蓝');
  });

  test('读取失败被明确呈现，不伪装成读取成功', () async {
    store.failReads = true;
    final profile = UserProfile(SharedPreferencesAsync());
    await profile.load();
    expect(profile.storageError, contains('无法读取'));
  });

  testWidgets('大厅进入用户中心，保存昵称后可修改', (tester) async {
    final profile = UserProfile(SharedPreferencesAsync());
    await tester.pumpWidget(PartyHubApp(profile: profile));
    await tester.tap(find.byTooltip('用户中心'));
    await tester.pumpAndSettle();
    expect(find.text('不用注册，也不用记密码'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '阿蓝');
    await tester.ensureVisible(find.text('保存昵称'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存昵称'));
    await tester.pumpAndSettle();
    expect(profile.nickname, '阿蓝');
    expect(find.text('已保存'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '小明');
    await tester.pump();
    await tester.ensureVisible(find.text('保存昵称'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存昵称'));
    await tester.pumpAndSettle();
    expect(profile.nickname, '小明');
  });

  testWidgets('创建、加入、同机页面都会自动填写本机昵称', (tester) async {
    final profile = UserProfile(SharedPreferencesAsync());
    await profile.saveNickname('小明');
    for (final screen in [
      const RoomEntryPage(),
      RoomEntryPage(game: plannedGames.first),
      LocalSetupPage(game: plannedGames.first),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              UserProfileScope(profile: profile, child: child!),
          home: screen,
        ),
      );
      final first = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(first.controller!.text, '小明');
      for (final field
          in tester
              .widgetList<TextFormField>(find.byType(TextFormField))
              .skip(1)) {
        expect(field.controller!.text, isEmpty);
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('首次同机开局也会保存本人的昵称', (tester) async {
    final profile = UserProfile(SharedPreferencesAsync());
    final game = plannedGames.singleWhere((game) => game.id == 'gomoku');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            UserProfileScope(profile: profile, child: child!),
        home: LocalSetupPage(game: game),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, '小明');
    await tester.enterText(find.byType(TextFormField).last, '阿蓝');
    await tester.ensureVisible(find.text('开始游戏'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始游戏'));
    await tester.pumpAndSettle();
    expect(profile.nickname, '小明');
    expect(find.byType(LocalGamePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('用户中心保存失败不显示成功，输入保留', (tester) async {
    final profile = UserProfile(SharedPreferencesAsync());
    store.failWrites = true;
    await tester.pumpWidget(
      MaterialApp(home: UserCenterPage(profile: profile)),
    );
    await tester.enterText(find.byType(TextFormField), '小明');
    await tester.pump();
    await tester.ensureVisible(find.text('保存昵称'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存昵称'));
    await tester.pumpAndSettle();
    expect(find.text('昵称未能保存，请重试。'), findsOneWidget);
    expect(find.text('已保存'), findsNothing);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '小明',
    );
  });

  for (final size in [const Size(320, 640), const Size(844, 390)]) {
    testWidgets('用户中心适配大字体 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = UserProfile(SharedPreferencesAsync());
      await profile.saveNickname('这是一个比较长的朋友昵称');
      await tester.pumpWidget(
        MaterialApp(
          theme: partyTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3.2)),
            child: child!,
          ),
          home: UserCenterPage(profile: profile),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
