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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Dia $day • Ano Bíblico')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erro ao carregar o plano.')),
        data: (plan) {
          final d = plan.days[day - 1];
          final done = readDays.contains(day);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (done ? Colors.green : theme.colorScheme.secondary)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          done ? Icons.check_circle_rounded : Icons.schedule_rounded,
                          color: done ? Colors.green : theme.colorScheme.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              done ? 'Leitura Concluída' : 'Leitura Pendente',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            Text(
                              'Dia $day de 365',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          final year = DateTime.now().year;
                          await ref.read(localRepoProvider).toggleBibleYearDayRead(year, day);
                          ref.invalidate(bibleYearReadDaysProvider);
                          ref.invalidate(bibleYearStreakProvider);
                        },
                        child: Text(done ? 'Desmarcar' : 'Concluir'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                "Passagens para leitura:",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              ...d.readings.map((r) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_stories_rounded, color: theme.colorScheme.primary, size: 20),
                    ),
                    title: Text(
                      _streamLabel(r.stream),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: Text(
                      'Capítulo ${r.chapter}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () async {
                      final books = await ref.read(booksProvider.future);
                      if (context.mounted) {
                        final abbrev = books[r.bookIndex].abbrev;
                        context.push('/chapter/$abbrev/${r.chapter}');
                      }
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
