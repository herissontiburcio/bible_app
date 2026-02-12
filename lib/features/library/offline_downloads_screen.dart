import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';

class OfflineDownloadsScreen extends ConsumerStatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  ConsumerState<OfflineDownloadsScreen> createState() =>
      _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends ConsumerState<OfflineDownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final local = ref.read(localRepoProvider);
    final downloads = local.getOfflineDownloads();
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text("Erro ao carregar livros: $e"))),
      data: (books) {
        // ✅ AQUI: bookMap normalizado (abbrev minúsculo)
        final bookMap = {
          for (final b in books) b.abbrev.toString().trim().toLowerCase(): b.name
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text("Meus downloads offline"),
            actions: [
              IconButton(
                tooltip: "Limpar cache (mantém baixados/pinned)",
                icon: const Icon(Icons.cleaning_services_outlined),
                onPressed: () async {
                  await local.clearCacheKeepPinned();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cache limpo (mantendo pinned)."),
                    ),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
          body: downloads.isEmpty
              ? const Center(child: Text("Nenhum capítulo baixado ainda."))
              : ListView.separated(
                  itemCount: downloads.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = downloads[i];
                    final v = (d['version'] ?? '').toString();
                    final bookAbbrev = (d['book'] ?? '').toString();
                    final ch = (d['chapter'] ?? 0) as int;

                    // ✅ AQUI: normaliza a chave pra achar o nome completo
                    final bookKey = bookAbbrev.trim().toLowerCase();
                    final bookName = bookMap[bookKey] ?? bookAbbrev;

                    return ListTile(
                      leading: const Icon(Icons.push_pin),
                      title: Text("$bookName $ch • $v"),
                      subtitle: Text(
                        "Salvo em: ${(d['savedAt'] ?? '').toString()}",
                      ),
                      trailing: IconButton(
                        tooltip: "Remover download",
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Remover download?"),
                              content: Text("Remover $bookName $ch do offline?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
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
                              const SnackBar(content: Text("Download removido.")),
                            );
                          }
                        },
                      ),
                      onTap: () => context.push("/chapter/$bookAbbrev/$ch"),
                    );
                  },
                ),
        );
      },
    );
  }
}
