import 'package:dawim/app.dart';
import 'package:dawim/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every TextTheme style resolves to an app font, never Roboto/Noto', (tester) async {
    await tester.pumpWidget(const DawimApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);

    expect(theme.textTheme.bodyMedium!.fontFamily, AppFonts.sans);
    expect(theme.textTheme.headlineMedium!.fontFamily, AppFonts.serifDisplay);

    final allStyles = <TextStyle?>[
      theme.textTheme.displayLarge,
      theme.textTheme.displayMedium,
      theme.textTheme.displaySmall,
      theme.textTheme.headlineLarge,
      theme.textTheme.headlineMedium,
      theme.textTheme.headlineSmall,
      theme.textTheme.titleLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.titleSmall,
      theme.textTheme.bodyLarge,
      theme.textTheme.bodyMedium,
      theme.textTheme.bodySmall,
      theme.textTheme.labelLarge,
      theme.textTheme.labelMedium,
      theme.textTheme.labelSmall,
    ];

    for (final style in allStyles) {
      expect(style, isNotNull);
      final family = style!.fontFamily;
      expect(family, isNotNull);
      expect(family, isNot('Roboto'));
      expect(family!.toLowerCase(), isNot(contains('noto')));
      expect(<String>[AppFonts.serifDisplay, AppFonts.sans], contains(family));
    }
  });

  testWidgets('stock AboutDialog never falls back to Roboto/Noto', (tester) async {
    await tester.pumpWidget(const DawimApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    showAboutDialog(context: context, applicationName: 'Dawim');
    await tester.pumpAndSettle();

    final texts = find.descendant(of: find.byType(AboutDialog), matching: find.byType(Text));
    expect(texts, findsWidgets);

    for (final element in texts.evaluate()) {
      final textWidget = element.widget as Text;
      final inherited = DefaultTextStyle.of(element).style;
      final effective = inherited.merge(textWidget.style);
      final family = effective.fontFamily;
      expect(family, isNotNull, reason: 'Text "${textWidget.data}" has no resolved fontFamily');
      expect(family, isNot('Roboto'));
      expect(family!.toLowerCase(), isNot(contains('noto')));
    }
  });
}
