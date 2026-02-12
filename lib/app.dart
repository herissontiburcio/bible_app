import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/app/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/bible/books_screen.dart';
import 'features/bible/book_chapters_screen.dart';
import 'features/bible/chapter_screen.dart';
import 'features/bible/search_screen.dart';
import 'features/library/offline_downloads_screen.dart';
import 'features/library/favorites_screen.dart';
import 'features/library/history_screen.dart';
import 'features/library/notes_screen.dart';
import 'features/settings/settings_screen.dart';
import 'state/providers.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

    GoRoute(path: '/books', builder: (_, __) => const BooksScreen()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),

    GoRoute(
      path: '/book/:abbrev/:chapters',
      builder: (context, state) {
        final abbrev = state.pathParameters['abbrev']!;
        final chapters = int.parse(state.pathParameters['chapters']!);

      return BookChaptersScreen(
      bookAbbrev: abbrev,
      chapters: chapters,
    );
  },
),


    GoRoute(
      path: '/chapter/:book/:chapter',
      builder: (context, state) {
        final book = state.pathParameters['book']!;
        final chapter = int.parse(state.pathParameters['chapter']!);
        return ChapterScreen(bookAbbrev: book, chapter: chapter);
      },
    ),

    GoRoute(path: '/offline', builder: (_, __) => const OfflineDownloadsScreen()),
    GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class BibliaApp extends ConsumerWidget {
  const BibliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      title: 'Bíblia Sagrada',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: themeMode,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
