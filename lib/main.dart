import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Hive's initFlutter resolves an app directory via platform channels, so
  // the binding has to exist before any provider touches storage.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DawimApp()));
}
