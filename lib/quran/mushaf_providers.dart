import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mushaf_repository.dart';

final mushafRepositoryProvider = FutureProvider<MushafRepository>((ref) {
  return MushafRepository.load();
});
