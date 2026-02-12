import 'package:bible_app/features/bible/search_screen.dart';
import 'package:bible_app/features/home/home_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:bible_app/features/bible_year/bible_year_screen.dart';
import 'package:bible_app/features/bible_year/bible_year_day_screen.dart';

// Splash / Home
import 'package:bible_app/features/app/splash_screen.dart';

// Bíblia
import 'package:bible_app/features/bible/books_screen.dart';
import 'package:bible_app/features/bible/book_chapters_screen.dart';
import 'package:bible_app/features/bible/chapter_screen.dart';

// Biblioteca
import 'package:bible_app/features/library/favorites_screen.dart';
import 'package:bible_app/features/library/history_screen.dart';
import 'package:bible_app/features/library/notes_screen.dart';
import 'package:bible_app/features/library/offline_downloads_screen.dart';

// Configurações
import 'package:bible_app/features/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    /// SPLASH
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),

    /// HOME
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),

    /// LISTA DE LIVROS
    GoRoute(
      path: '/books',
      builder: (_, __) => const BooksScreen(),
    ),

    /// CAPÍTULOS DE UM LIVRO
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

    /// CAPÍTULO (LEITURA)
    GoRoute(
      path: '/chapter/:book/:chapter',
      builder: (context, state) {
        final book = state.pathParameters['book']!;
        final chapter = int.parse(state.pathParameters['chapter']!);

        return ChapterScreen(
          bookAbbrev: book,
          chapter: chapter,
        );
      },
    ),

    /// BUSCA
    GoRoute(
      path: '/search',
      builder: (_, __) => const SearchScreen(),
    ),

    /// FAVORITOS
    GoRoute(
      path: '/favorites',
      builder: (_, __) => const FavoritesScreen(),
    ),

    /// HISTÓRICO
    GoRoute(
      path: '/history',
      builder: (_, __) => const HistoryScreen(),
    ),

    /// NOTAS
    GoRoute(
      path: '/notes',
      builder: (_, __) => const NotesScreen(),
    ),

    /// DOWNLOADS OFFLINE
    GoRoute(
      path: '/offline',
      builder: (_, __) => const OfflineDownloadsScreen(),
    ),

    /// ANO BÍBLICO
    GoRoute(
      path: '/bible-year',
      builder: (_, __) => const BibleYearScreen(),
    ),

    /// ANO BÍBLICO (DIA)
    GoRoute(
      path: '/bible-year/day/:day',
      builder: (_, state) {
        final day = int.parse(state.pathParameters['day']!);
        return BibleYearDayScreen(day: day);
      },
    ),

    /// CONFIGURAÇÕES
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);
