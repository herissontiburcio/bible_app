import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/book.dart';
import '../../state/providers.dart';

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final versionsAsync = ref.watch(versionsProvider);
    final selectedVersion = ref.watch(selectedVersionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Livros da Bíblia"),
        actions: [
          versionsAsync.when(
            data: (versions) => Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedVersion,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.primary),
                  items: versions.map((v) {
                    final label = v.name != null && v.name!.isNotEmpty ? "${v.version.toUpperCase()} • ${v.name}" : v.version.toUpperCase();
                    return DropdownMenuItem(
                      value: v.version,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    ref.read(selectedVersionProvider.notifier).state = v;
                    await ref.read(localRepoProvider).setVersion(v);
                  },
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: "Baixar mais versões",
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: () => context.push('/versions'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              // Barra de pesquisa rápida de livros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Filtrar por livro (ex: Gênesis, Salmos, Mateus)...",
                    hintStyle: TextStyle(fontSize: 13.5, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filterQuery = "");
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _filterQuery = v.trim().toLowerCase()),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                tabs: const [
                  Tab(text: "Antigo Testamento (39)"),
                  Tab(text: "Novo Testamento (27)"),
                  Tab(text: "Todos (66)"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erro ao carregar livros: $e")),
        data: (allBooks) {
          final oldTestament = allBooks.take(39).toList();
          final newTestament = allBooks.skip(39).toList();

          List<Book> filterList(List<Book> list) {
            if (_filterQuery.isEmpty) return list;
            return list.where((b) {
              return b.name.toLowerCase().contains(_filterQuery) ||
                  b.abbrev.toLowerCase().contains(_filterQuery);
            }).toList();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _BooksListView(
                books: filterList(oldTestament),
                selectedVersion: selectedVersion,
                testamentPrefix: "Antigo Testamento",
              ),
              _BooksListView(
                books: filterList(newTestament),
                selectedVersion: selectedVersion,
                testamentPrefix: "Novo Testamento",
              ),
              _BooksListView(
                books: filterList(allBooks),
                selectedVersion: selectedVersion,
                testamentPrefix: "Bíblia Completa",
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BooksListView extends ConsumerWidget {
  const _BooksListView({
    required this.books,
    required this.selectedVersion,
    required this.testamentPrefix,
  });

  final List<Book> books;
  final String selectedVersion;
  final String testamentPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text("Nenhum livro encontrado para a busca.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: books.length,
      itemBuilder: (context, i) {
        final b = books[i];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  b.abbrev.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            title: Text(
              b.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
            ),
            subtitle: Text(
              "${b.chapters} ${b.chapters == 1 ? 'capítulo' : 'capítulos'}",
              style: TextStyle(
                fontSize: 12.5,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Baixar livro para acesso offline",
                  icon: const Icon(Icons.download_for_offline_outlined, size: 20),
                  onPressed: () {
                    final future = ref.read(
                      downloadBookProvider(DownloadBookArgs(selectedVersion, b)).future,
                    );

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
                                ? const Text("Este livro já está pronto para uso offline.")
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LinearProgressIndicator(),
                                      SizedBox(height: 12),
                                      Text("Salvando capítulos localmente..."),
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
                  },
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            onTap: () => context.push("/book/${b.abbrev}/${b.chapters}"),
          ),
        );
      },
    );
  }
}
