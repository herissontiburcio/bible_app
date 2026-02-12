import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bible_app/data/models/random_verse.dart';

import '../data/api/abiblia_client.dart';
import '../data/repositories/bible_repository.dart';
import '../data/local/local_repository.dart';
import '../data/models/book.dart';
import '../data/models/bible_version.dart';
import '../data/models/chapter.dart';
import '../data/models/search_result.dart';

final localRepoProvider = Provider((ref) => LocalRepository());
final apiClientProvider = Provider((ref) => ABibliaClient());
final bibleRepoProvider = Provider((ref) => BibleRepository(ref.read(apiClientProvider)));

final versionsProvider = FutureProvider<List<BibleVersion>>((ref) async {
  return ref.read(bibleRepoProvider).getVersions();
});

final booksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.read(bibleRepoProvider).getBooks();
});

final selectedVersionProvider = StateProvider<String>((ref) {
  final local = ref.read(localRepoProvider);
  return local.version;
});

final fontScaleProvider = StateProvider<double>((ref) {
  return ref.read(localRepoProvider).fontScale;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final mode = ref.read(localRepoProvider).themeMode;
  return switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

final redLetterExperimentalProvider = StateProvider<bool>((ref) {
  return ref.read(localRepoProvider).redLetterExperimental;
});

final dailyVerseEnabledProvider = StateProvider<bool>((ref) {
  return ref.read(localRepoProvider).dailyVerseEnabled;
});

final dailyVerseTimeProvider = StateProvider<TimeOfDay>((ref) {
  final local = ref.read(localRepoProvider);
  return TimeOfDay(hour: local.dailyVerseHour, minute: local.dailyVerseMinute);
});

final randomVerseProvider = FutureProvider<RandomVerse>((ref) async {
  final version = ref.read(selectedVersionProvider);
  return ref.read(bibleRepoProvider).getRandomVerse(version);
});


class ChapterArgs {
  final String version;
  final String bookAbbrev;
  final int chapter;
  ChapterArgs(this.version, this.bookAbbrev, this.chapter);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterArgs &&
          version == other.version &&
          bookAbbrev == other.bookAbbrev &&
          chapter == other.chapter;

  @override
  int get hashCode => version.hashCode ^ bookAbbrev.hashCode ^ chapter.hashCode;
}

final chapterProvider = FutureProvider.family<Chapter, ChapterArgs>((ref, args) async {
  final repo = ref.read(bibleRepoProvider);

  // tenta online
  try {
    final ch = await repo.getChapter(args.version, args.bookAbbrev, args.chapter);

    // salva cache (não pinned automaticamente)
    await ref.read(localRepoProvider).saveChapterOffline(
          version: args.version,
          book: args.bookAbbrev,
          chapter: args.chapter,
          chapterData: ch.toJson(),
          pinned: ref.read(localRepoProvider).isChapterPinned(
            version: args.version,
            book: args.bookAbbrev,
            chapter: args.chapter,
          ),
        );

    return ch;
  } catch (_) {
    // fallback offline
    final off = ref.read(localRepoProvider).getOfflineChapter(
          version: args.version,
          book: args.bookAbbrev,
          chapter: args.chapter,
        );
    if (off == null) rethrow;
    return Chapter.fromJson((off['data'] as Map).cast<String, dynamic>());
  }
});

final searchProvider = FutureProvider.family<List<SearchVerseResult>, String>((ref, q) async {
  final version = ref.read(selectedVersionProvider);
  return ref.read(bibleRepoProvider).search(version, q);
});

class DownloadBookArgs {
  final String version;
  final Book book;
  DownloadBookArgs(this.version, this.book);
}

final downloadChapterProvider = FutureProvider.family<void, ChapterArgs>((ref, args) async {
  final repo = ref.read(bibleRepoProvider);
  final local = ref.read(localRepoProvider);

  final ch = await repo.getChapter(args.version, args.bookAbbrev, args.chapter);
  await local.saveChapterOffline(
    version: args.version,
    book: args.bookAbbrev,
    chapter: args.chapter,
    chapterData: ch.toJson(),
    pinned: true,
  );
});

final downloadBookProvider = FutureProvider.family<void, DownloadBookArgs>((ref, args) async {
  final repo = ref.read(bibleRepoProvider);
  final local = ref.read(localRepoProvider);

  for (var c = 1; c <= args.book.chapters; c++) {
    final ch = await repo.getChapter(args.version, args.book.abbrev, c);
    await local.saveChapterOffline(
      version: args.version,
      book: args.book.abbrev,
      chapter: c,
      chapterData: ch.toJson(),
      pinned: true,
    );
  }
});
