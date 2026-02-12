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

    return booksAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text("Erro ao carregar livros: $e"))),
      data: (books) {
        // ✅ mapa normalizado: abbrev -> nome
        final bookMap = <String, String>{
          for (final b in books) b.abbrev.toString().trim().toLowerCase(): b.name
        };

        // dropdown de livros (nomes completos)
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
          appBar: AppBar(title: const Text("Favoritos")),
          body: favs.isEmpty
              ? const Center(child: Text("Nenhum favorito ainda."))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: "Buscar no favorito (texto ou referência)",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: "Limpar",
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _query = "");
                                      },
                                    ),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.filter_list),
                              const SizedBox(width: 8),
                              const Text("Livro:"),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: bookList.contains(_selectedBook) ? _selectedBook : "Todos",
                                  items: bookList
                                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedBook = v ?? "Todos"),
                                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Mostrando ${filtered.length} de ${favs.length}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("Nenhum favorito encontrado com esses filtros."))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final f = filtered[i];
                                final version = (f["version"] ?? "").toString();
                                final abbrevRaw = (f["book"] ?? "").toString();
                                final abbrevKey = abbrevRaw.trim().toLowerCase();

                                final bookName = bookMap[abbrevKey] ?? abbrevRaw;
                                final chapter = (f["chapter"] ?? 0) as int;
                                final verse = (f["verse"] ?? 0) as int;
                                final text = (f["text"] ?? "").toString();

                                return ListTile(
                                  leading: const Icon(Icons.bookmark),
                                  title: Text("$bookName $chapter:$verse • $version"),
                                  subtitle: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
                                  trailing: IconButton(
                                    tooltip: "Remover",
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await local.toggleFavorite(
                                        version: version,
                                        book: abbrevRaw, // mantém exatamente como foi salvo
                                        chapter: chapter,
                                        verse: verse,
                                        text: text,
                                      );
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                  onTap: () => context.push("/chapter/$abbrevRaw/$chapter"),
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
