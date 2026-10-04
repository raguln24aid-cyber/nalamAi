import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'app.dart';
import 'core/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // A single structured line per log — never logs OCR/photo content (see ARCHITECTURE.md
    // "Logging" decision); callers only ever pass short status strings here.
    debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  await Env.load();

  runApp(const ProviderScope(child: NalamAiApp()));
}
