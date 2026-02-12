import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({String emoji, String greeting, String message}) _greeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return (
        emoji: "🌅",
        greeting: "Bom dia!",
        message: "Que Deus abençoe o seu dia!"
      );
    } else if (hour >= 12 && hour < 18) {
      return (
        emoji: "🌤",
        greeting: "Boa tarde!",
        message: "Que Deus continue te guiando!"
      );
    } else {
      return (
        emoji: "🌙",
        greeting: "Boa noite!",
        message: "Descanse na presença de Deus!"
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _greeting();
    final verseAsync = ref.watch(randomVerseProvider);
    final version = ref.watch(selectedVersionProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              theme.colorScheme.primary.withOpacity(0.32),
              theme.colorScheme.surface.withOpacity(0.01),
            ]
          : [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.primaryContainer.withOpacity(0.62),
            ],
    );

    final items = [
      ("Livros", "/books", Icons.menu_book),
      ("Buscar", "/search", Icons.search),
      ("Meus downloads offline", "/offline", Icons.download_for_offline),
      ("Favoritos", "/favorites", Icons.bookmark),
      ("Histórico", "/history", Icons.history),
      ("Notas", "/notes", Icons.edit_note),
      ("Configurações", "/settings", Icons.settings),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 2.5,
        shadowColor: Colors.black.withOpacity(isDark ? 0.35 : 0.18),
        surfaceTintColor: theme.colorScheme.surface,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final t = _ctrl.value;
                final scale = 1.0 + (0.055 * math.sin(t * math.pi));
                final rotate = 0.018 * math.sin(t * math.pi);
                return Transform.rotate(
                  angle: rotate,
                  child: Transform.scale(
                    scale: scale,
                    child: const Icon(Icons.menu_book, size: 30),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Text(
              "Bíblia Sagrada",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),

      body: CustomScrollView(
        slivers: [
          // -------- HEADER --------
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              decoration: BoxDecoration(gradient: gradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          g.greeting,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    g.message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    elevation: isDark ? 0.8 : 1.6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: verseAsync.when(
                        loading: () => Row(
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text("Carregando versículo do dia..."),
                          ],
                        ),
                        error: (_, __) => const Text("Não foi possível carregar."),
                        data: (v) {
                          final refText =
                              "${v.bookName} ${v.chapter}:${v.verse} • $version";

                          final shareMsg =
                              "📖 Versículo do dia ($version)\n$refText\n\n${v.text}\n\n— Enviado pelo Bíblia App";

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_stories_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Versículo do dia",
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: "Atualizar",
                                    onPressed: () =>
                                        ref.invalidate(randomVerseProvider),
                                    icon: const Icon(Icons.refresh, size: 20),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: "Compartilhar",
                                    onPressed: () => Share.share(shareMsg),
                                    icon:
                                        const Icon(Icons.share_outlined, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                refText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "“${v.text}”",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.2,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------- MENU --------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final (t, route, icon) = items[i];

                return Card(
                  elevation: isDark ? 0.6 : 1.2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(isDark ? 0.22 : 0.14),
                      child: Icon(icon),
                    ),
                    title: Text(
                      t,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(route),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
