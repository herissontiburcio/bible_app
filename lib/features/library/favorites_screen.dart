import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = "";
  String _selectedBook = "Todos";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = ref.read(localRepoProvider);
    final favs = local.getFavorites();
    final booksAsync = ref.watch(booksProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return booksAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Erro ao carregar livros: $e"))),
      data: (books) {
        final bookMap = <String, String>{
          for (final b in books) b.abbrev.toString().trim().toLowerCase(): b.name
        };

        final booksSet = <String>{"Todos"};
        for (final f in favs) {
          final abbrevRaw = (f["book"] ?? "").toString();
          final abbrevKey = abbrevRaw.trim().toLowerCase();
          final bookName = bookMap[abbrevKey] ?? abbrevRaw;
          if (bookName.isNotEmpty) booksSet.add(bookName);
        }
        final bookList = booksSet.toList()
          ..sort((a, b) => a == "Todos" ? -1 : b == "Todos" ? 1 : a.compareTo(b));

        final filtered = favs.where((f) {
          final abbrevRaw = (f["book"] ?? "").toString();
          final abbrevKey = abbrevRaw.trim().toLowerCase();

          final bookName = bookMap[abbrevKey] ?? abbrevRaw;
          final chapter = (f["chapter"] ?? 0).toString();
          final verse = (f["verse"] ?? 0).toString();
          final version = (f["version"] ?? "").toString();
          final text = (f["text"] ?? "").toString();

          if (_selectedBook != "Todos" && bookName != _selectedBook) return false;

          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;

          final refStr = "$bookName $chapter:$verse $version".toLowerCase();
          return refStr.contains(q) || text.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text("Versículos Favoritos")),
          body: favs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        "Nenhum versículo favoritado ainda.",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Toque em qualquer versículo durante a leitura para salvá-lo.",
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: "Buscar nos favoritos...",
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: "Limpar",
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _query = "");
                                      },
                                    ),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.filter_list_rounded, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: bookList.contains(_selectedBook) ? _selectedBook : "Todos",
                                  items: bookList
                                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedBook = v ?? "Todos"),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                "Nenhum favorito encontrado com esses filtros.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final f = filtered[i];
                                final version = (f["version"] ?? "").toString();
                                final abbrevRaw = (f["book"] ?? "").toString();
                                final abbrevKey = abbrevRaw.trim().toLowerCase();

                                final bookName = bookMap[abbrevKey] ?? abbrevRaw;
                                final chapter = (f["chapter"] ?? 0) as int;
                                final verse = (f["verse"] ?? 0) as int;
                                final text = (f["text"] ?? "").toString();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.bookmark_rounded, color: Colors.red, size: 20),
                                    ),
                                    title: Text(
                                      "$bookName $chapter:$verse • ${version.toUpperCase()}",
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        text,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(height: 1.4),
                                      ),
                                    ),
                                    trailing: IconButton(
                                      tooltip: "Remover dos favoritos",
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                      onPressed: () async {
                                        await local.toggleFavorite(
                                          version: version,
                                          book: abbrevRaw,
                                          chapter: chapter,
                                          verse: verse,
                                          text: text,
                                        );
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                    onTap: () => context.push("/chapter/$abbrevRaw/$chapter"),
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
