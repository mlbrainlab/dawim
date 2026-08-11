import 'package:dawim/app.dart';
import 'package:dawim/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Arabic locale renders RTL with the verbatim hadith tagline', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('ar');
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const DawimApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));

    expect(Directionality.of(context), TextDirection.rtl);

    final l10n = AppLocalizations.of(context);
    // Verbatim per CLAUDE.md non-negotiable — no respelling, no diacritic changes.
    expect(l10n.tagline, 'أدومها وإن قلّ');
    expect(find.text('أدومها وإن قلّ'), findsOneWidget);
  });

  testWidgets('English locale renders LTR with the verbatim tagline', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en');
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const DawimApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));

    expect(Directionality.of(context), TextDirection.ltr);

    final l10n = AppLocalizations.of(context);
    expect(l10n.tagline, 'Constant, even if small.');
  });
}
