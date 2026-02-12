import 'package:bible_app/core/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/env.dart';
import 'data/local/hive_boxes.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Env.validate();

  await Hive.initFlutter();

  await Hive.openBox(HiveBoxes.settings);
  await Hive.openBox(HiveBoxes.offlineChapters);
  await Hive.openBox(HiveBoxes.favorites);
  await Hive.openBox(HiveBoxes.history);
  await Hive.openBox(HiveBoxes.notes);
  await Hive.openBox(HiveBoxes.highlights);
  await Hive.openBox(HiveBoxes.bibleYear);

  await NotificationService.instance.init();

  runApp(const ProviderScope(child: BibliaApp()));
}
