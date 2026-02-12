import 'package:hive/hive.dart';
import 'hive_boxes.dart';

class LocalRepository {
  Box get _settings => Hive.box(HiveBoxes.settings);
  Box get _offline => Hive.box(HiveBoxes.offlineChapters);
  Box get _favorites => Hive.box(HiveBoxes.favorites);
  Box get _history => Hive.box(HiveBoxes.history);
  Box get _notes => Hive.box(HiveBoxes.notes);

  Box get _bibleYear => Hive.box(HiveBoxes.bibleYear);

  // ✅ NOVO: box separada para destaques (marca-texto)
  Box get _highlights => Hive.box(HiveBoxes.highlights);

  // ---------- Settings ----------
  double get fontScale => (_settings.get('fontScale', defaultValue: 1.0) as num).toDouble();
  Future<void> setFontScale(double v) => _settings.put('fontScale', v);

  String get themeMode => (_settings.get('themeMode', defaultValue: 'system') as String);
  Future<void> setThemeMode(String v) => _settings.put('themeMode', v);

  String get version => (_settings.get('version', defaultValue: 'nvi') as String);
  Future<void> setVersion(String v) => _settings.put('version', v);

  bool get redLetterExperimental => (_settings.get('redLetter', defaultValue: false) as bool);
  Future<void> setRedLetterExperimental(bool v) => _settings.put('redLetter', v);

  bool get dailyVerseEnabled => (_settings.get('dailyVerseEnabled', defaultValue: false) as bool);
  Future<void> setDailyVerseEnabled(bool v) => _settings.put('dailyVerseEnabled', v);

  int get dailyVerseHour => (_settings.get('dailyVerseHour', defaultValue: 8) as int);
  Future<void> setDailyVerseHour(int v) => _settings.put('dailyVerseHour', v);

  int get dailyVerseMinute => (_settings.get('dailyVerseMinute', defaultValue: 0) as int);
  Future<void> setDailyVerseMinute(int v) => _settings.put('dailyVerseMinute', v);

  // ---------- Offline ----------
  String _chapterKey(String version, String book, int chapter) => "$version|$book|$chapter";

  bool isChapterPinned({required String version, required String book, required int chapter}) {
    final key = _chapterKey(version, book, chapter);
    final data = _offline.get(key);
    if (data is Map) return (data['pinned'] == true);
    return false;
  }

  Future<void> saveChapterOffline({
    required String version,
    required String book,
    required int chapter,
    required Map<String, dynamic> chapterData,
    required bool pinned,
  }) async {
    final key = _chapterKey(version, book, chapter);
    await _offline.put(key, {
      'version': version,
      'book': book,
      'chapter': chapter,
      'pinned': pinned,
      'savedAt': DateTime.now().toIso8601String(),
      'data': chapterData,
    });
  }

  Map<String, dynamic>? getOfflineChapter({
    required String version,
    required String book,
    required int chapter,
  }) {
    final key = _chapterKey(version, book, chapter);
    final raw = _offline.get(key);
    if (raw is Map) return raw.cast<String, dynamic>();
    return null;
  }

  // ✅ Só lista capítulos realmente baixados (pinned = true)
  List<Map<String, dynamic>> getOfflineDownloads() {
    return _offline.values
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .where((e) => e['pinned'] == true)
        .toList()
      ..sort((a, b) => (b['savedAt'] ?? '').toString().compareTo((a['savedAt'] ?? '').toString()));
  }

  Future<void> clearCacheKeepPinned() async {
    final keysToDelete = <dynamic>[];
    for (final entry in _offline.toMap().entries) {
      final value = entry.value;
      if (value is Map && value['pinned'] != true) {
        keysToDelete.add(entry.key);
      }
    }
    await _offline.deleteAll(keysToDelete);
  }

  Future<void> deleteOfflineChapter({
    required String version,
    required String book,
    required int chapter,
  }) async {
    final key = _chapterKey(version, book, chapter);
    await _offline.delete(key);
  }

  // ---------- Favorites ----------
  String _favKey(String version, String book, int chapter, int verse) => "$version|$book|$chapter|$verse";

  Future<void> toggleFavorite({
    required String version,
    required String book,
    required int chapter,
    required int verse,
    required String text,
  }) async {
    final key = _favKey(version, book, chapter, verse);
    if (_favorites.containsKey(key)) {
      await _favorites.delete(key);
    } else {
      await _favorites.put(key, {
        'version': version,
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'text': text,
        'savedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  List<Map<String, dynamic>> getFavorites() {
    return _favorites.values
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList()
      ..sort((a, b) => (b['savedAt'] ?? '').toString().compareTo((a['savedAt'] ?? '').toString()));
  }

  // ---------- History ----------
  Future<void> addHistory({
    required String version,
    required String book,
    required int chapter,
    int? verse,
    String? verseText,
  }) async {
    final key = "$version|$book|$chapter";
    await _history.put(key, {
      'version': version,
      'book': book,
      'chapter': chapter,
      if (verse != null) 'verse': verse,
      if (verseText != null && verseText.trim().isNotEmpty) 'verseText': verseText.trim(),
      'lastReadAt': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> getHistory() {
    return _history.values
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList()
      ..sort((a, b) => (b['lastReadAt'] ?? '').toString().compareTo((a['lastReadAt'] ?? '').toString()));
  }

  Future<void> clearHistory() async {
    await _history.clear();
  }

  // ---------- Notes ----------
  Future<void> saveNote({
    required String version,
    required String book,
    required int chapter,
    required int verse,
    required String note,
  }) async {
    final key = "$version|$book|$chapter|$verse";
    await _notes.put(key, {
      'note': note,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  String? getNote({
    required String version,
    required String book,
    required int chapter,
    required int verse,
  }) {
    final key = "$version|$book|$chapter|$verse";
    final raw = _notes.get(key);
    if (raw is Map) return raw['note']?.toString();
    return null;
  }

  Future<void> deleteNote({
    required String version,
    required String book,
    required int chapter,
    required int verse,
  }) async {
    final key = "$version|$book|$chapter|$verse";
    await _notes.delete(key);
  }

  List<MapEntry<String, Map<String, dynamic>>> getNotesEntries() {
    final map = _notes.toMap();
    final entries = <MapEntry<String, Map<String, dynamic>>>[];
    for (final e in map.entries) {
      if (e.key is String && e.value is Map) {
        entries.add(MapEntry(e.key as String, (e.value as Map).cast<String, dynamic>()));
      }
    }
    entries.sort((a, b) => (b.value['updatedAt'] ?? '').toString().compareTo((a.value['updatedAt'] ?? '').toString()));
    return entries;
  }

  // ---------- Highlight (Marca-texto) ----------

String _highlightKey(String version, String book, int chapter, int verse) =>
    "$version|$book|$chapter|$verse";

/// Salva a cor do destaque (colorId = Color.value)
Future<void> setHighlight({
  required String version,
  required String book,
  required int chapter,
  required int verse,
  required int colorId,
}) async {
  final key = _highlightKey(version, book, chapter, verse);
  await _settings.put("highlight_$key", colorId);
}

/// Retorna a cor salva (Color.value) ou null
int? getHighlight({
  required String version,
  required String book,
  required int chapter,
  required int verse,
}) {
  final key = _highlightKey(version, book, chapter, verse);
  final v = _settings.get("highlight_$key");
  if (v is int) return v;
  return null;
}

/// Remove o destaque
Future<void> removeHighlight({
  required String version,
  required String book,
  required int chapter,
  required int verse,
}) async {
  final key = _highlightKey(version, book, chapter, verse);
  await _settings.delete("highlight_$key");
}

  // ---------- Ano Bíblico ----------

  String _bibleYearDaysKey(int year) => 'bibleYear_readDays_$year';

  Set<int> getBibleYearReadDays(int year) {
    final raw = _bibleYear.get(
      _bibleYearDaysKey(year),
      defaultValue: <dynamic>[],
    ) as List;

    return raw.map((e) => (e as num).toInt()).toSet();
  }

  Future<void> toggleBibleYearDayRead(int year, int day) async {
    final set = getBibleYearReadDays(year);

    if (set.contains(day)) {
      set.remove(day);
    } else {
      set.add(day);
    }

    final list = set.toList()..sort();
    await _bibleYear.put(_bibleYearDaysKey(year), list);
  }

  bool isBibleYearDayRead(int year, int day) {
    return getBibleYearReadDays(year).contains(day);
  }

    int getBibleYearStreak(int year) {
    final read = getBibleYearReadDays(year);
    final now = DateTime.now();
    final start = DateTime(year, 1, 1);

    int streak = 0;

    // conta dias seguidos (de hoje pra trás) marcados como lidos
    for (int i = 0; i < 366; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (date.year != year) break;

      final dayNumber = date.difference(start).inDays + 1;
      if (dayNumber < 1 || dayNumber > 365) break;

      if (read.contains(dayNumber)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }


}
