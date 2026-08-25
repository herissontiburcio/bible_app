import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final local = ref.read(localRepoProvider);
    final history = local.getHistory();
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

        String bookName(String abbrev) {
          final key = abbrev.trim().toLowerCase();
          return bookMap[key] ?? abbrev;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Histórico de Leitura"),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  tooltip: "Limpar histórico",
                  icon: const Icon(Icons.delete_sweep_rounded),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text("Limpar histórico?"),
                        content: const Text("Isso removerá todos os registros de capítulos e versículos lidos."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: const Text("Cancelar"),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: const Text("Limpar"),
                          ),
                        ],
                      ),
                    );

                    if (ok == true) {
                      await local.clearHistory();
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Histórico limpo com sucesso.")),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
          body: history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        "Nenhuma leitura recente.",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Os capítulos que você abrir aparecerão automaticamente aqui.",
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: history.length,
                  itemBuilder: (context, i) {
                    final h = history[i];

                    final version = (h["version"] ?? "").toString();
                    final bookAbbrev = (h["book"] ?? "").toString();
                    final chapter = (h["chapter"] ?? 0) as int;
                    final verse = h["verse"];
                    final verseText = (h["verseText"] ?? "").toString();

                    final fullName = bookName(bookAbbrev);

                    final refText = (verse is int)
                        ? "$fullName $chapter:$verse"
                        : "$fullName $chapter";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.blue, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(
                              refText,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                version.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: verseText.trim().isEmpty
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "“$verseText”",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(height: 1.35, fontStyle: FontStyle.italic),
                                ),
                              ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        onTap: () => context.push("/chapter/$bookAbbrev/$chapter"),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
