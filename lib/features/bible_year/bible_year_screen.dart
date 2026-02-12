import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../data/api/bible_year_service.dart';

class BibleYearScreen extends ConsumerWidget {
  const BibleYearScreen({super.key});

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
    final streak = ref.watch(bibleYearStreakProvider);

    final theme = Theme.of(context);
    final today = BibleYearService.todayDayNumber();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ano Bíblico'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'Hoje'),
              Tab(icon: Icon(Icons.view_day), text: 'Plano'),
              Tab(icon: Icon(Icons.insights), text: 'Progresso'),
            ],
          ),
        ),
        body: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Não foi possível carregar o plano.')),
          data: (plan) {
            final total = plan.days.length;
            final done = readDays.length;
            final progress = total == 0 ? 0.0 : done / total;

            final todayData = plan.days[today - 1];
            final todayDone = readDays.contains(today);

            return TabBarView(
              children: [
                // ===== HOJE =====
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dia $today', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(
                              todayDone ? '✅ Concluído' : '⏳ Pendente',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: todayData.readings.map((r) {
                                return ActionChip(
                                  label: Text(_streamLabel(r.stream)),
                                  onPressed: () async {
                                    final books = await ref.read(booksProvider.future);
                                    final abbrev = books[r.bookIndex].abbrev;
                                    context.push('/chapter/$abbrev/${r.chapter}');
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => context.push('/bible-year/day/$today'),
                                    icon: const Icon(Icons.menu_book),
                                    label: const Text('Abrir leitura de hoje'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.filledTonal(
                                  tooltip: todayDone ? 'Desmarcar' : 'Marcar como lido',
                                  onPressed: () async {
                                    final year = DateTime.now().year;
                                    await ref.read(localRepoProvider).toggleBibleYearDayRead(year, today);
                                    ref.invalidate(bibleYearReadDaysProvider);
                                    ref.invalidate(bibleYearStreakProvider);
                                  },
                                  icon: Icon(todayDone ? Icons.check_circle : Icons.done),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ===== PLANO =====
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: plan.days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final day = plan.days[i].day;
                    final doneDay = readDays.contains(day);

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('$day')),
                        title: Text('Dia $day', style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('${plan.days[i].readings.length} leituras'),
                        trailing: Icon(doneDay ? Icons.check_circle : Icons.chevron_right),
                        onTap: () => context.push('/bible-year/day/$day'),
                      ),
                    );
                  },
                ),

                // ===== PROGRESSO =====
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Progresso do ano', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 14),

                            SizedBox(
                              width: 150,
                              height: 150,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(value: progress, strokeWidth: 10),
                                  Text('${(progress * 100).toStringAsFixed(0)}%',
                                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            Text('$done de $total dias concluídos',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('🔥 Streak: $streak dias',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
