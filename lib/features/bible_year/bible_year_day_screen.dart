import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class BibleYearDayScreen extends ConsumerWidget {
  final int day;
  const BibleYearDayScreen({super.key, required this.day});

  String _streamLabel(String s) => switch (s) {
        'OT' => 'Antigo Testamento',
        'NT' => 'Novo Testamento',
        'PS' => 'Salmos',
        'PV' => 'Provérbios',
        _ => s,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(bibleYearPlanProvider);
    final readDays = ref.watch(bibleYearReadDaysProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Dia $day')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erro ao carregar.')),
        data: (plan) {
          final d = plan.days[day - 1];
          final done = readDays.contains(day);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          done ? '✅ Concluído' : '⏳ Pendente',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          final year = DateTime.now().year;
                          await ref.read(localRepoProvider).toggleBibleYearDayRead(year, day);
                          ref.invalidate(bibleYearReadDaysProvider);
                          ref.invalidate(bibleYearStreakProvider);
                        },
                        child: Text(done ? 'Desmarcar' : 'Marcar como lido'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...d.readings.map((r) {
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: Text(_streamLabel(r.stream), style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text('Capítulo ${r.chapter}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final books = await ref.read(booksProvider.future);
                      final abbrev = books[r.bookIndex].abbrev;
                      context.push('/chapter/$abbrev/${r.chapter}');
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
