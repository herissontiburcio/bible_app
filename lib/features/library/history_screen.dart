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
            title: const Text("Histórico"),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  tooltip: "Apagar histórico",
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Apagar histórico?"),
                        content: const Text("Isso vai remover todos os itens do histórico. Deseja continuar?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Apagar"),
                          ),
                        ],
                      ),
                    );

                    if (ok == true) {
                      await local.clearHistory();
                      if (!mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Histórico apagado.")),
                      );
                    }
                  },
                ),
            ],
          ),
          body: history.isEmpty
              ? const Center(child: Text("Nenhuma leitura registrada ainda."))
              : ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final h = history[i];

                    final version = (h["version"] ?? "").toString();
                    final bookAbbrev = (h["book"] ?? "").toString();
                    final chapter = (h["chapter"] ?? 0) as int;
                    final verse = h["verse"]; // pode ser null
                    final verseText = (h["verseText"] ?? "").toString();

                    final fullName = bookName(bookAbbrev);

                    final refText = (verse is int)
                        ? "$fullName $chapter:$verse • $version"
                        : "$fullName $chapter • $version";

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(refText),
                      subtitle: verseText.trim().isEmpty
                          ? null
                          : Text(
                              "“$verseText”",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push("/chapter/$bookAbbrev/$chapter"),
                    );
                  },
                ),
        );
      },
    );
  }
}
