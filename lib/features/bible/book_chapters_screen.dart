import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/providers.dart';

class BookChaptersScreen extends ConsumerWidget {
  const BookChaptersScreen({
    super.key,
    required this.bookAbbrev,
    required this.chapters,
  });

  final String bookAbbrev;
  final int chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    final title = booksAsync.when(
      data: (books) {
        final book = books.firstWhere(
          (b) => b.abbrev == bookAbbrev,
          orElse: () => books.first,
        );
        return book.name;
      },
      loading: () => "Capítulos",
      error: (_, __) => "Capítulos",
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemCount: chapters,
        itemBuilder: (_, i) {
          final c = i + 1;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push("/chapter/$bookAbbrev/$c"),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Center(child: Text("$c", style: Theme.of(context).textTheme.titleMedium)),
            ),
          );
        },
      ),
    );
  }
}
