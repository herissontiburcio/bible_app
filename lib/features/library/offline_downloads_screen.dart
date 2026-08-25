import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class OfflineDownloadsScreen extends ConsumerStatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  ConsumerState<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends ConsumerState<OfflineDownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final local = ref.read(localRepoProvider);
    final downloads = local.getOfflineDownloads();
    final booksAsync = ref.watch(booksProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return booksAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Erro ao carregar livros: $e"))),
      data: (books) {
        final bookMap = {
          for (final b in books) b.abbrev.toString().trim().toLowerCase(): b.name
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text("Downloads Offline"),
            actions: [
              IconButton(
                tooltip: "Limpar cache temporário",
                icon: const Icon(Icons.cleaning_services_rounded),
                onPressed: () async {
                  await local.clearCacheKeepPinned();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cache temporário limpo com sucesso.")),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Banner informativo sobre a base offline nativa
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded, color: Colors.teal, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "As versões NVI e ACF completas já vêm embutidas no seu app para uso 100% offline.",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.teal.shade200 : Colors.teal.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: downloads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_done_rounded, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              "Nenhum capítulo fixado manualmente.",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Capítulos baixados individualmente aparecerão listados aqui.",
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: downloads.length,
                        itemBuilder: (context, i) {
                          final d = downloads[i];
                          final v = (d['version'] ?? '').toString();
                          final bookAbbrev = (d['book'] ?? '').toString();
                          final ch = (d['chapter'] ?? 0) as int;

                          final bookKey = bookAbbrev.trim().toLowerCase();
                          final bookName = bookMap[bookKey] ?? bookAbbrev;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: isDark ? 0.25 : 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bookmark_added_rounded, color: Colors.teal, size: 20),
                              ),
                              title: Text(
                                "$bookName $ch • ${v.toUpperCase()}",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                              ),
                              subtitle: Text(
                                "Disponível offline",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: "Remover download",
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      title: const Text("Remover download?"),
                                      content: Text("Remover $bookName $ch dos itens salvos?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogCtx, false),
                                          child: const Text("Cancelar"),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(dialogCtx, true),
                                          child: const Text("Remover"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (ok == true) {
                                    await local.deleteOfflineChapter(
                                      version: v,
                                      book: bookAbbrev,
                                      chapter: ch,
                                    );
                                    if (!mounted) return;
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Capítulo removido do armazenamento.")),
                                    );
                                  }
                                },
                              ),
                              onTap: () => context.push("/chapter/$bookAbbrev/$ch"),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
