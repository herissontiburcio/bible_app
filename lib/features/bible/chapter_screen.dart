import 'package:bible_app/features/widgets/verse_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';


class ChapterScreen extends ConsumerWidget {
  const ChapterScreen({super.key, required this.bookAbbrev, required this.chapter});
  final String bookAbbrev;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(selectedVersionProvider);
    final local = ref.read(localRepoProvider);

    final asyncChapter = ref.watch(chapterProvider(ChapterArgs(version, bookAbbrev, chapter)));
    final pinned = local.isChapterPinned(version: version, book: bookAbbrev, chapter: chapter);

    return Scaffold(
      appBar: AppBar(
        title: asyncChapter.when(
          data: (c) => Text("${c.bookName} $chapter • $version"),
          loading: () => Text("$bookAbbrev $chapter • $version"),
          error: (_, __) => Text("$bookAbbrev $chapter • $version"),
        ),
        actions: [
          IconButton(
            tooltip: pinned ? "Capítulo já baixado" : "Baixar capítulo offline",
            icon: Icon(pinned ? Icons.download_done : Icons.download_outlined),
            onPressed: () async {
              if (pinned) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Este capítulo já está disponível offline.")),
                );
                return;
              }

              final future = ref.read(downloadChapterProvider(ChapterArgs(version, bookAbbrev, chapter)).future);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => FutureBuilder<void>(
                  future: future,
                  builder: (_, snap) {
                    final done = snap.connectionState == ConnectionState.done && snap.error == null;
                    return AlertDialog(
                      title: Text(done ? "Download concluído" : "Baixando capítulo..."),
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
        ],
      ),
      body: asyncChapter.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Erro ao carregar capítulo.\n\n$e", textAlign: TextAlign.center),
          ),
        ),
        data: (c) {
          // ✅ Registra histórico sem travar a UI (não pode usar async aqui)
          Future.microtask(() {
            local.addHistory(version: version, book: bookAbbrev, chapter: chapter);
          });

          return ListView.separated(
            itemCount: c.verses.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
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
    );
  }
}
