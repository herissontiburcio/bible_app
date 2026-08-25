import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/providers.dart';

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
    final fontScale = ref.watch(fontScaleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: highlightColor != null
            ? highlightColor.withValues(alpha: isDark ? 0.35 : 0.45)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showVerseBottomSheet(context, local),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${widget.verseNumber}",
                  style: TextStyle(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: useRed ? Colors.red.shade600 : null,
                    fontWeight: useRed ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 15.5 * fontScale,
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerseBottomSheet(BuildContext context, dynamic local) async {
    // Registra no histórico
    await local.addHistory(
      version: widget.version,
      book: widget.bookAbbrev,
      chapter: widget.chapter,
      verse: widget.verseNumber,
      verseText: widget.text,
    );

    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = [
      const Color(0xFFFEF08A), // Amarelo pastel
      const Color(0xFFBBF7D0), // Verde pastel
      const Color(0xFFBFDBFE), // Azul pastel
      const Color(0xFFFBCFE8), // Rosa pastel
      const Color(0xFFFED7AA), // Laranja pastel
      const Color(0xFFDDD6FE), // Roxo pastel
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final refText = "${widget.bookName} ${widget.chapter}:${widget.verseNumber}";
        final existingNote = local.getNote(
          version: widget.version,
          book: widget.bookAbbrev,
          chapter: widget.chapter,
          verse: widget.verseNumber,
        );

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Cabeçalho com referência e versão
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        refText,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.version.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "“${widget.text}”",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Paleta de cores para Marca-Texto
                  const Text(
                    "Destacar com Marca-Texto",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...colors.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await local.setHighlight(
                                version: widget.version,
                                book: widget.bookAbbrev,
                                chapter: widget.chapter,
                                verse: widget.verseNumber,
                                colorId: c.toARGB32(),
                              );
                              if (mounted) setState(() {});
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black12, width: 1),
                              ),
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        tooltip: "Remover destaque",
                        icon: const Icon(Icons.format_color_reset_rounded, size: 20),
                        onPressed: () async {
                          Navigator.pop(ctx);
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

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Ações Rápidas (Copiar, Compartilhar, Favoritar, Anotar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: Icons.copy_rounded,
                        label: "Copiar",
                        onTap: () {
                          Navigator.pop(ctx);
                          Clipboard.setData(
                            ClipboardData(text: "$refText (${widget.version})\n\"${widget.text}\""),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Versículo copiado!")),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.share_rounded,
                        label: "Compartilhar",
                        onTap: () async {
                          Navigator.pop(ctx);
                          final msg =
                              "$refText (${widget.version})\n\n\"${widget.text}\"\n\n— Enviado pela Bíblia Sagrada";
                          await Share.share(msg);
                        },
                      ),
                      _ActionButton(
                        icon: Icons.bookmark_add_rounded,
                        label: "Favoritar",
                        onTap: () async {
                          Navigator.pop(ctx);
                          await local.toggleFavorite(
                            version: widget.version,
                            book: widget.bookAbbrev,
                            chapter: widget.chapter,
                            verse: widget.verseNumber,
                            text: widget.text,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Favoritos atualizados!")),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                      _ActionButton(
                        icon: Icons.edit_note_rounded,
                        label: "Anotar",
                        onTap: () async {
                          Navigator.pop(ctx);
                          _showNoteDialog(context, local, existingNote);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNoteDialog(BuildContext context, dynamic local, String? existingNote) async {
    final ctrl = TextEditingController(text: existingNote ?? "");

    final action = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text("Nota • ${widget.bookName} ${widget.chapter}:${widget.verseNumber}"),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Escreva sua anotação ou reflexão aqui..."),
        ),
        actions: [
          if (existingNote != null && existingNote.trim().isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, "delete"),
              child: const Text("Excluir", style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, "cancel"),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, "save"),
            child: const Text("Salvar"),
          ),
        ],
      ),
    );

    if (action == "save") {
      await local.saveNote(
        version: widget.version,
        book: widget.bookAbbrev,
        chapter: widget.chapter,
        verse: widget.verseNumber,
        note: ctrl.text.trim(),
      );
      if (mounted) setState(() {});
    } else if (action == "delete") {
      await local.deleteNote(
        version: widget.version,
        book: widget.bookAbbrev,
        chapter: widget.chapter,
        verse: widget.verseNumber,
      );
      if (mounted) setState(() {});
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
