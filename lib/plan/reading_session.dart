import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state_providers.dart';
import 'daily_segment.dart';
import 'reading_verifier.dart';

/// Identifies the slot a reader session belongs to.
class ReadingSlotRef {
  const ReadingSlotRef({required this.juzNumber, required this.slot});

  final int juzNumber;
  final ReadingSlot slot;
}

/// Drives verified reading time while the mushaf is open for a slot.
///
/// Seconds accrue only under [ReadingVerifier.shouldAccrue] — foreground, on
/// a page inside the slot, and not parked on one page. Accrual is buffered in
/// memory and flushed to storage at most every [_flushIntervalSeconds] (and
/// on pause or dispose) so hive isn't written once a second.
class ReadingSessionController extends ChangeNotifier {
  ReadingSessionController({required this.ref, required this.slotRef, required int initialPage})
    : _currentPage = initialPage {
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _isForeground = state == AppLifecycleState.resumed;
        if (!_isForeground) _flush();
      },
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  static const int _flushIntervalSeconds = 10;

  final WidgetRef ref;
  final ReadingSlotRef slotRef;

  late final Timer _ticker;
  late final AppLifecycleListener _lifecycle;

  int _currentPage;
  bool _isForeground = true;
  int _secondsSinceLastPageChange = 0;
  int _unflushedSeconds = 0;
  int _unflushedPage = 0;

  void onPageChanged(int page) {
    _flush();
    _currentPage = page;
    _secondsSinceLastPageChange = 0;
    ref.read(appStateProvider.notifier).notePageViewed(slotRef.juzNumber, slotRef.slot.index, page);
    notifyListeners();
  }

  void _onTick() {
    final counts = ReadingVerifier.shouldAccrue(
      isForeground: _isForeground,
      currentPage: _currentPage,
      slot: slotRef.slot,
      secondsSinceLastPageChange: _secondsSinceLastPageChange,
    );
    _secondsSinceLastPageChange++;
    if (!counts) return;

    if (_unflushedPage != _currentPage) {
      _flush();
      _unflushedPage = _currentPage;
    }
    _unflushedSeconds++;
    if (_unflushedSeconds >= _flushIntervalSeconds) _flush();
    notifyListeners();
  }

  void _flush() {
    if (_unflushedSeconds <= 0) return;
    final seconds = _unflushedSeconds;
    final page = _unflushedPage == 0 ? _currentPage : _unflushedPage;
    _unflushedSeconds = 0;
    ref
        .read(appStateProvider.notifier)
        .noteSecondsRead(slotRef.juzNumber, slotRef.slot.index, page, seconds);
  }

  @override
  void dispose() {
    _flush();
    _ticker.cancel();
    _lifecycle.dispose();
    super.dispose();
  }
}
