import 'package:bible_app/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class VerseTile extends ConsumerStatefulWidget {
  const VerseTile({
    super.key,
    required this.bookAbbrev,
    required this.bookName,
    required this.chapter,
    required this.verseNumber,
    required this.text,
    required this.version,
  });

  final String version;
  final String bookAbbrev;
  final String bookName;
  final int chapter;
  final int verseNumber;
  final String text;

  @override
  ConsumerState<VerseTile> createState() => _VerseTileState();
}

class _VerseTileState extends ConsumerState<VerseTile> {
  bool _isGospel(String abbrev) =>
      ['mt', 'mc', 'lc', 'jo'].contains(abbrev.toLowerCase());

  bool _looksLikeJesusSpeech(String t) {
    return t.contains('“') || t.contains('”') || t.contains('"') || t.contains('—');
  }

  @override
  Widget build(BuildContext context) {
    final local = ref.read(localRepoProvider);
    final redLetter = ref.watch(redLetterExperimentalProvider);

    final highlightId = local.getHighlight(
      version: widget.version,
      book: widget.bookAbbrev,
      chapter: widget.chapter,
      verse: widget.verseNumber,
    );

    final highlightColor = highlightId != null ? Color(highlightId) : null;

    final useRed = redLetter &&
        _isGospel(widget.bookAbbrev) &&
        _looksLikeJesusSpeech(widget.text);

    return Container(
      color: highlightColor?.withOpacity(0.35),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          "${widget.verseNumber}. ${widget.text}",
          style: TextStyle(
            color: useRed ? Colors.red : null,
            fontWeight: useRed ? FontWeight.w500 : null,
            height: 1.5,
          ),
        ),
        onTap: () async {
          // ✅ histórico (último versículo tocado)
          await local.addHistory(
            version: widget.version,
            book: widget.bookAbbrev,
            chapter: widget.chapter,
            verse: widget.verseNumber,
            verseText: widget.text,
          );

          if (!context.mounted) return;

          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) {
              final colors = [
                Colors.yellow.shade200,
                Colors.green.shade200,
                Colors.blue.shade200,
                Colors.pink.shade200,
                Colors.orange.shade200,
              ];

              // pega nota atual
              final existingNote = local.getNote(
                version: widget.version,
                book: widget.bookAbbrev,
                chapter: widget.chapter,
                verse: widget.verseNumber,
              );

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade500,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        Text(
                          "${widget.bookName} ${widget.chapter}:${widget.verseNumber} • ${widget.version}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),

                        // -------- Compartilhar
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.share_outlined),
                          title: const Text("Compartilhar"),
                          onTap: () async {
                            Navigator.pop(context);
                            final msg =
                                "${widget.bookName} ${widget.chapter}:${widget.verseNumber} (${widget.version})\n\n${widget.text}\n\n— Enviado pelo Bíblia App";
                            await Share.share(msg);
                          },
                        ),

                        // -------- Favoritar
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.bookmark_add_outlined),
                          title: const Text("Favoritar / Desfavoritar"),
                          onTap: () async {
                            Navigator.pop(context);
                            await local.toggleFavorite(
                              version: widget.version,
                              book: widget.bookAbbrev,
                              chapter: widget.chapter,
                              verse: widget.verseNumber,
                              text: widget.text,
                            );
                            if (mounted) setState(() {});
                          },
                        ),

                        // -------- Notas
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.edit_note),
                          title: Text(existingNote == null || existingNote.trim().isEmpty
                              ? "Adicionar nota"
                              : "Editar nota"),
                          subtitle: (existingNote == null || existingNote.trim().isEmpty)
                              ? null
                              : Text(
                                  existingNote,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () async {
                            Navigator.pop(context);

                            final noteNow = local.getNote(
                                  version: widget.version,
                                  book: widget.bookAbbrev,
                                  chapter: widget.chapter,
                                  verse: widget.verseNumber,
                                ) ??
                                "";

                            final ctrl = TextEditingController(text: noteNow);

                            final action = await showDialog<String>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text("Nota • ${widget.bookName} ${widget.chapter}:${widget.verseNumber}"),
                                content: TextField(
                                  controller: ctrl,
                                  maxLines: 4,
                                  decoration: const InputDecoration(hintText: "Escreva sua nota..."),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, "cancel"),
                                    child: const Text("Cancelar"),
                                  ),
                                  if (noteNow.trim().isNotEmpty)
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, "delete"),
                                      child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                                    ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, "save"),
                                    child: const Text("Salvar"),
                                  ),
                                ],
                              ),
                            );

                            if (!mounted) return;

                            if (action == "save") {
                              await local.saveNote(
                                version: widget.version,
                                book: widget.bookAbbrev,
                                chapter: widget.chapter,
                                verse: widget.verseNumber,
                                note: ctrl.text.trim(),
                              );
                              if (mounted) setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Nota salva.")),
                              );
                            } else if (action == "delete") {
                              await local.deleteNote(
                                version: widget.version,
                                book: widget.bookAbbrev,
                                chapter: widget.chapter,
                                verse: widget.verseNumber,
                              );
                              if (mounted) setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Nota excluída.")),
                              );
                            }
                          },
                        ),

                        const Divider(height: 30),

                        const Text(
                          "Marca-texto",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 12,
                          children: colors.map((c) {
                            final selected = highlightId == c.value;

                            return GestureDetector(
                              onTap: () async {
                                // Salva cor
                                await local.setHighlight(
                                  version: widget.version,
                                  book: widget.bookAbbrev,
                                  chapter: widget.chapter,
                                  verse: widget.verseNumber,
                                  colorId: c.value,
                                );

                                // ✅ atualiza IMEDIATO (sem precisar rolar)
                                if (mounted) setState(() {});

                                if (context.mounted) Navigator.pop(context);
                              },
                              child: CircleAvatar(
                                backgroundColor: c,
                                radius: 18,
                                child: selected
                                    ? const Icon(Icons.check, color: Colors.black)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.format_clear),
                          title: const Text("Remover destaque"),
                          onTap: () async {
                            Navigator.pop(context);
                            await local.removeHighlight(
                              version: widget.version,
                              book: widget.bookAbbrev,
                              chapter: widget.chapter,
                              verse: widget.verseNumber,
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
