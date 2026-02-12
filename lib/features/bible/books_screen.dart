import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final versionsAsync = ref.watch(versionsProvider);
    final selectedVersion = ref.watch(selectedVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Livros"),
        actions: [
          versionsAsync.when(
            data: (versions) => DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedVersion,
                items: versions.map((v) {
                  final label = v.name != null && v.name!.isNotEmpty ? "${v.version} • ${v.name}" : v.version;
                  return DropdownMenuItem(
                    value: v.version,
                    child: SizedBox(width: 170, child: Text(label, overflow: TextOverflow.ellipsis)),
                  );
                }).toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  ref.read(selectedVersionProvider.notifier).state = v;
                  await ref.read(localRepoProvider).setVersion(v);
                },
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erro ao carregar livros: $e")),
        data: (books) => ListView.separated(
          itemCount: books.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final b = books[i];
            return ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(b.name),
              subtitle: Text("${b.chapters} capítulos • ${b.abbrev}"),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == "open") {
                    context.push("/book/${b.abbrev}/${b.chapters}");
                    return;
                  }
                  if (v == "download") {
                    final future = ref.read(downloadBookProvider(DownloadBookArgs(selectedVersion, b)).future);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => FutureBuilder<void>(
                        future: future,
                        builder: (_, snap) {
                          final done = snap.connectionState == ConnectionState.done && snap.error == null;
                          return AlertDialog(
                            title: Text(done ? "Download concluído" : "Baixando ${b.name}..."),
                            content: done
                                ? const Text("Livro disponível offline.")
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
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: "open", child: Text("Escolher capítulo")),
                  PopupMenuItem(value: "download", child: Text("Baixar livro offline")),
                ],
                child: const Icon(Icons.more_vert),
              ),
              onTap: () => context.push("/book/${b.abbrev}/${b.chapters}"),
            );
          },
        ),
      ),
    );
  }
}
