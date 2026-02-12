import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    final local = ref.read(localRepoProvider);
    final entries = local.getNotesEntries();
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Erro ao carregar livros: $e"))),
      data: (books) {
        final bookMap = {for (final b in books) b.abbrev: b.name};

        return Scaffold(
          appBar: AppBar(title: const Text("Notas")),
          body: entries.isEmpty
              ? const Center(child: Text("Nenhuma nota ainda."))
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final key = entries[i].key;
                    final value = entries[i].value;

                    final note = (value["note"] ?? "").toString();
                    final updatedAt = (value["updatedAt"] ?? "").toString();

                    final parts = key.split("|");
                    final version = parts.length > 0 ? parts[0] : "";
                    final bookAbbrev = parts.length > 1 ? parts[1] : "";
                    final chapter = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
                    final verse = parts.length > 3 ? int.tryParse(parts[3]) ?? 0 : 0;

                    final bookName = bookMap[bookAbbrev] ?? bookAbbrev;

                    return ListTile(
                      leading: const Icon(Icons.edit_note),
                      title: Text("$bookName $chapter:$verse • $version"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note, maxLines: 3, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            "Atualizado: $updatedAt",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        tooltip: "Excluir nota",
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await local.deleteNote(
                            version: version,
                            book: bookAbbrev,
                            chapter: chapter,
                            verse: verse,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                      onTap: () => context.push("/chapter/$bookAbbrev/$chapter"),
                    );
                  },
                ),
        );
      },
    );
  }
}
