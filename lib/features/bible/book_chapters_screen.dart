import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class BookChaptersScreen extends ConsumerWidget {
  const BookChaptersScreen({
    super.key,
    required this.bookAbbrev,
    required this.chapters,
  });

  final String bookAbbrev;
  final int chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final book = booksAsync.when(
      data: (books) {
        return books.firstWhere(
          (b) => b.abbrev.toLowerCase() == bookAbbrev.toLowerCase(),
          orElse: () => books.first,
        );
      },
      loading: () => null,
      error: (_, __) => null,
    );

    final title = book?.name ?? bookAbbrev.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Banner do Livro
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_stories_rounded, color: theme.colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Selecione um capítulo para ler ($chapters no total)",
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Grade de Capítulos
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final chapterNumber = i + 1;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push("/chapter/$bookAbbrev/$chapterNumber"),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$chapterNumber",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: chapters,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
