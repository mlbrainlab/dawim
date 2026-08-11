import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app_state.dart';

/// Durable home for [DawimState]. The whole state is kept as a single JSON
/// document under one key rather than spread across typed boxes, so it stays
/// trivially serializable for a future cloud sync.
class AppStateRepository {
  AppStateRepository(this._box);

  static const String boxName = 'dawim_state';
  static const String _documentKey = 'state';

  static Future<AppStateRepository> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(boxName);
    return AppStateRepository(box);
  }

  final Box<String> _box;

  DawimState load() {
    final raw = _box.get(_documentKey);
    if (raw == null) return const DawimState();
    return DawimState.fromJson(jsonDecode(raw) as Map<String, dynamic>).normalized();
  }

  Future<void> save(DawimState state) {
    return _box.put(_documentKey, jsonEncode(state.toJson()));
  }
}
