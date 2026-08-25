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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return booksAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Erro ao carregar livros: $e"))),
      data: (books) {
        final bookMap = {for (final b in books) b.abbrev.toLowerCase(): b.name};

        return Scaffold(
          appBar: AppBar(title: const Text("Minhas Anotações")),
          body: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        "Nenhuma anotação ainda.",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Toque em um versículo durante a leitura para escrever uma nota.",
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
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final key = entries[i].key;
                    final value = entries[i].value;

                    final note = (value["note"] ?? "").toString();

                    final parts = key.split("|");
                    final version = parts.isNotEmpty ? parts[0] : "";
                    final bookAbbrev = parts.length > 1 ? parts[1] : "";
                    final chapter = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
                    final verse = parts.length > 3 ? int.tryParse(parts[3]) ?? 0 : 0;

                    final bookName = bookMap[bookAbbrev.toLowerCase()] ?? bookAbbrev;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: isDark ? 0.25 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_note_rounded, color: Colors.purple, size: 22),
                        ),
                        title: Text(
                          "$bookName $chapter:$verse • ${version.toUpperCase()}",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            note,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: "Excluir nota",
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
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
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
