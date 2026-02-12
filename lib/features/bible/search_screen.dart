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
  final ctrl = TextEditingController();
  String q = "";

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(selectedVersionProvider);
    final resultsAsync = q.trim().isEmpty ? null : ref.watch(searchProvider(q.trim()));

    return Scaffold(
      appBar: AppBar(title: Text("Buscar • $version")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: "Digite uma palavra (ex: amor, fé...)",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: "Buscar",
                  icon: const Icon(Icons.check),
                  onPressed: () => setState(() => q = ctrl.text),
                ),
              ),
              onSubmitted: (_) => setState(() => q = ctrl.text),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: resultsAsync == null
                  ? const Center(child: Text("Digite algo e pressione Enter."))
                  : resultsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text("Erro na busca: $e")),
                      data: (items) {
                        if (items.isEmpty) return const Center(child: Text("Nada encontrado."));
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = items[i];
                            return ListTile(
                              title: Text("${r.book} ${r.chapter}:${r.verse}"),
                              subtitle: Text(r.text, maxLines: 3, overflow: TextOverflow.ellipsis),
                              onTap: () => context.push("/chapter/${r.abbrev}/${r.chapter}"),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
