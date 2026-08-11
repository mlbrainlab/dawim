import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/digits.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_fonts.dart';
import '../models/mushaf_page.dart';
import '../mushaf_font_loader.dart';
import '../mushaf_providers.dart';
import '../mushaf_repository.dart';
import '../widgets/mushaf_page_view.dart';

/// Mushaf page order is always right-to-left, regardless of the app's
/// current UI locale. Header/footer chrome follows the UI locale.
class MushafReaderScreen extends ConsumerWidget {
  const MushafReaderScreen({super.key, this.initialPage = 1});

  final int initialPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryAsync = ref.watch(mushafRepositoryProvider);
    final uiDirection = Directionality.of(context);

    return Scaffold(
      body: SafeArea(
        child: repositoryAsync.when(
          data: (repository) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: PageController(initialPage: initialPage - 1),
                itemCount: repository.pages.length,
                itemBuilder: (context, index) {
                  // Warm the neighbors' fonts so swiping never shows a gap.
                  for (final neighbor in [index - 1, index + 1]) {
                    if (neighbor >= 0 && neighbor < repository.pages.length) {
                      MushafFontLoader.instance.ensurePageLoaded(repository.pages[neighbor]);
                    }
                  }
                  return _MushafPageFrame(
                    repository: repository,
                    page: repository.pages[index],
                    uiDirection: uiDirection,
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
        ),
      ),
    );
  }
}

class _MushafPageFrame extends StatelessWidget {
  const _MushafPageFrame({
    required this.repository,
    required this.page,
    required this.uiDirection,
  });

  final MushafRepository repository;
  final MushafPage page;
  final TextDirection uiDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    final surahNumber = int.parse(page.firstVerseKey.split(':')[0]);
    final surah = repository.surahByNumber(surahNumber)!;
    final surahName = locale.languageCode == 'ar' ? surah.nameArabic : surah.nameSimple;
    final juzNumber = repository.juzNumberForVerse(page.firstVerseKey) ?? 1;

    final chromeStyle = theme.textTheme.labelLarge?.copyWith(
      fontFamily: AppFonts.sans,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
    );

    // Page number sits on the outer edge, alternating like a physical book.
    final footerAlignment = page.pageNumber.isOdd ? Alignment.centerRight : Alignment.centerLeft;

    return Directionality(
      textDirection: uiDirection,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(surahName, style: chromeStyle),
                Text(
                  l10n.juzHeaderLabel(localizedDigits(juzNumber, locale)),
                  style: chromeStyle,
                ),
              ],
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: MushafFontLoader.instance.isPageReady(page.pageNumber)
                    ? MushafPageView(page: page)
                    : FutureBuilder<void>(
                        future: MushafFontLoader.instance.ensurePageLoaded(page),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const SizedBox.expand();
                          }
                          return MushafPageView(page: page);
                        },
                      ),
              ),
            ),
            Align(
              alignment: footerAlignment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(localizedDigits(page.pageNumber, locale), style: chromeStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
