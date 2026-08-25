import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../widgets/verse_tile.dart';

class ChapterScreen extends ConsumerWidget {
  const ChapterScreen({super.key, required this.bookAbbrev, required this.chapter});
  final String bookAbbrev;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(selectedVersionProvider);
    final local = ref.read(localRepoProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final asyncChapter = ref.watch(chapterProvider(ChapterArgs(version, bookAbbrev, chapter)));
    final pinned = local.isChapterPinned(version: version, book: bookAbbrev, chapter: chapter);
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: asyncChapter.when(
          data: (c) => Text("${c.bookName} $chapter"),
          loading: () => Text("${bookAbbrev.toUpperCase()} $chapter"),
          error: (_, __) => Text("${bookAbbrev.toUpperCase()} $chapter"),
        ),
        actions: [
          // Ajuste rápido de fonte
          IconButton(
            tooltip: "Tamanho da fonte",
            icon: const Icon(Icons.format_size_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const _FontSizeBottomSheet(),
              );
            },
          ),

          // Download offline
          IconButton(
            tooltip: pinned ? "Capítulo salvo offline" : "Salvar offline",
            icon: Icon(
              pinned ? Icons.download_done_rounded : Icons.download_rounded,
              color: pinned ? Colors.green : null,
            ),
            onPressed: () async {
              if (pinned) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Este capítulo já está salvo offline.")),
                );
                return;
              }

              final future = ref.read(
                downloadChapterProvider(ChapterArgs(version, bookAbbrev, chapter)).future,
              );

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => FutureBuilder<void>(
                  future: future,
                  builder: (_, snap) {
                    final done = snap.connectionState == ConnectionState.done && snap.error == null;
                    return AlertDialog(
                      title: Text(done ? "Salvo com sucesso" : "Baixando capítulo..."),
                      content: done
                          ? const Text("Este capítulo está disponível offline.")
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(),
                                SizedBox(height: 12),
                                Text("Aguarde..."),
                              ],
                            ),
                      actions: [
                        TextButton(
                          onPressed: done ? () => Navigator.pop(context) : null,
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: asyncChapter.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.amber),
                const SizedBox(height: 12),
                Text("Erro ao carregar capítulo:\n$e", textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(chapterProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Tentar novamente"),
                ),
              ],
            ),
          ),
        ),
        data: (c) {
          Future.microtask(() {
            local.addHistory(version: version, book: bookAbbrev, chapter: chapter);
          });

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: c.verses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final v = c.verses[i];
              return VerseTile(
                version: version,
                bookAbbrev: bookAbbrev,
                bookName: c.bookName,
                chapter: chapter,
                verseNumber: v.number,
                text: v.text,
              );
            },
          );
        },
      ),

      // Barra inferior para avançar / retroceder capítulos facilmente
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botão Anterior
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: chapter > 1
                    ? () => context.pushReplacement("/chapter/$bookAbbrev/${chapter - 1}")
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text("Anterior"),
              ),

              // Rótulo Central
              Text(
                "Capítulo $chapter",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),

              // Botão Próximo
              booksAsync.maybeWhen(
                data: (books) {
                  final currentBook = books.firstWhere(
                    (b) => b.abbrev.toLowerCase() == bookAbbrev.toLowerCase(),
                    orElse: () => books.first,
                  );
                  final hasNextChapter = chapter < currentBook.chapters;

                  return FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: hasNextChapter
                        ? () => context.pushReplacement("/chapter/$bookAbbrev/${chapter + 1}")
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text("Próximo"),
                  );
                },
                orElse: () => FilledButton.tonalIcon(
                  onPressed: () => context.pushReplacement("/chapter/$bookAbbrev/${chapter + 1}"),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text("Próximo"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSizeBottomSheet extends ConsumerWidget {
  const _FontSizeBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(fontScaleProvider);
    final local = ref.read(localRepoProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_size_rounded),
                const SizedBox(width: 10),
                const Text(
                  "Tamanho da Letra",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  "${(fontScale * 100).toInt()}%",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: fontScale,
              min: 0.85,
              max: 1.40,
              divisions: 11,
              label: "${(fontScale * 100).toInt()}%",
              onChanged: (v) async {
                ref.read(fontScaleProvider.notifier).state = v;
                await local.setFontScale(v);
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Assim resplandeça a vossa luz diante dos homens, para que vejam as vossas boas obras e glorifiquem o vosso Pai, que está nos céus. (Mateus 5:16)",
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
