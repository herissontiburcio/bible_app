import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = "";

  final _suggestions = ["amor", "paz", "fé", "esperança", "graça", "coração", "luz", "vida"];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submitSearch(String text) {
    final clean = text.trim();
    if (clean.isNotEmpty) {
      setState(() => _query = clean);
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(selectedVersionProvider);
    final resultsAsync = _query.isEmpty ? null : ref.watch(searchProvider(_query));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Buscar Versículos • ${version.toUpperCase()}"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de busca com estilo moderno
            TextField(
              controller: _ctrl,
              autofocus: _query.isEmpty,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Digite uma palavra ou termo (ex: amor, fé...)",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_ctrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = "");
                        },
                      ),
                    IconButton(
                      tooltip: "Pesquisar",
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: () => _submitSearch(_ctrl.text),
                    ),
                  ],
                ),
              ),
              onSubmitted: _submitSearch,
            ),

            const SizedBox(height: 12),

            // Sugestões de pesquisa rápida se não buscou ainda
            if (_query.isEmpty) ...[
              const Text(
                "Sugestões de busca:",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((s) {
                  return ActionChip(
                    label: Text(s),
                    onPressed: () {
                      _ctrl.text = s;
                      _submitSearch(s);
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      "Busca rápida e 100% offline",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ] else ...[
              // Resultados da busca
              Expanded(
                child: resultsAsync == null
                    ? const SizedBox.shrink()
                    : resultsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Text("Erro na busca: $e", textAlign: TextAlign.center),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Nenhum versículo encontrado para '$_query'.",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final r = items[i];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => context.push("/chapter/${r.abbrev}/${r.chapter}"),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "${r.book} ${r.chapter}:${r.verse}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12.5,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          r.text,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            height: 1.45,
                                          ),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
