import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../data/local/hive_boxes.dart';

class AppSettings {
  final ThemeMode themeMode;
  final double textScale;

  const AppSettings({required this.themeMode, required this.textScale});

  AppSettings copyWith({ThemeMode? themeMode, double? textScale}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
    );
  }
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController()
      : super(const AppSettings(themeMode: ThemeMode.system, textScale: 1.0)) {
    _load();
  }

  Box get _box => Hive.box(HiveBoxes.settings);

  Future<void> _load() async {
    final mode = _box.get("themeMode", defaultValue: "system").toString();
    final scaleRaw = _box.get("textScale", defaultValue: 1.0);

    final themeMode = switch (mode) {
      "light" => ThemeMode.light,
      "dark" => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final textScale = (scaleRaw is num)
        ? scaleRaw.toDouble()
        : double.tryParse(scaleRaw.toString()) ?? 1.0;

    state = AppSettings(themeMode: themeMode, textScale: textScale.clamp(0.85, 1.30));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final v = switch (mode) {
      ThemeMode.light => "light",
      ThemeMode.dark => "dark",
      _ => "system",
    };
    await _box.put("themeMode", v);
  }

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(0.85, 1.30);
    state = state.copyWith(textScale: clamped);
    await _box.put("textScale", clamped);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) => SettingsController());
