import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_hub/app_style.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('普通文字缩小 1，按钮总共缩小 2：$brightness', () {
      final configured = partyTheme(brightness);
      final theme = ThemeData.localize(
        configured,
        configured.typography.englishLike,
      );
      expect(theme.textTheme.headlineLarge!.fontSize, 27);
      expect(theme.textTheme.headlineMedium!.fontSize, 25);
      expect(theme.textTheme.headlineSmall!.fontSize, 21);
      expect(theme.textTheme.titleLarge!.fontSize, 17);
      expect(theme.textTheme.titleMedium!.fontSize, 15);
      expect(theme.textTheme.bodyLarge!.fontSize, 14);
      expect(theme.textTheme.bodyMedium!.fontSize, 13);
      expect(theme.textTheme.bodySmall!.fontSize, 11);
      expect(theme.textTheme.labelLarge!.fontSize, 13);
      expect(theme.appBarTheme.titleTextStyle!.fontSize, 15);
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        expect(style.textStyle!.resolve({})!.fontSize, 12);
        expect(
          style.minimumSize!.resolve({})!.height,
          greaterThanOrEqualTo(48),
        );
      }
      expect(theme.chipTheme.labelStyle!.fontSize, 12);
    });
  }

  testWidgets('按钮字号实际为 12 且继续尊重系统文字缩放', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: partyTheme(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              const Text('普通文字'),
              FilledButton(onPressed: () {}, child: const Text('主按钮')),
              OutlinedButton(onPressed: () {}, child: const Text('描边按钮')),
              TextButton(onPressed: () {}, child: const Text('文字按钮')),
              ChoiceChip(
                label: const Text('人数'),
                selected: true,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    for (final label in ['主按钮', '描边按钮', '文字按钮', '人数']) {
      final richText = tester.widget<RichText>(
        find.descendant(of: find.text(label), matching: find.byType(RichText)),
      );
      expect(richText.text.style!.fontSize, 12);
      expect(richText.textScaler.scale(12), closeTo(21.6, .001));
    }
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(54),
    );
    expect(tester.takeException(), isNull);
  });
}
