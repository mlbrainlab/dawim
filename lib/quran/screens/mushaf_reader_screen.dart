import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mushaf_providers.dart';
import '../widgets/mushaf_page_view.dart';

/// Mushaf page order is always right-to-left, regardless of the app's
/// current UI locale.
class MushafReaderScreen extends ConsumerWidget {
  const MushafReaderScreen({super.key, this.initialPage = 1});

  final int initialPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repositoryAsync = ref.watch(mushafRepositoryProvider);

    return Scaffold(
      appBar: AppBar(),
      body: repositoryAsync.when(
        data: (repository) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: PageController(initialPage: initialPage - 1),
              itemCount: repository.pages.length,
              itemBuilder: (context, index) => MushafPageView(page: repository.pages[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}
