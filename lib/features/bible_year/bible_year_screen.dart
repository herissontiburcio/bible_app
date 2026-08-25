import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/bible_year_service.dart';
import '../../state/providers.dart';

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
              Tab(icon: Icon(Icons.today_rounded), text: 'Hoje'),
              Tab(icon: Icon(Icons.calendar_view_day_rounded), text: 'Plano (365)'),
              Tab(icon: Icon(Icons.insights_rounded), text: 'Progresso'),
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
                // ===== ABA 1: HOJE =====
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (todayDone ? Colors.green : theme.colorScheme.secondary)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    todayDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                    color: todayDone ? Colors.green : theme.colorScheme.secondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dia $today de 365',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      todayDone ? '✅ Leitura Concluída' : '⏳ Leitura Pendente',
                                      style: TextStyle(
                                        color: todayDone ? Colors.green.shade600 : theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 12),

                            const Text(
                              "Passagens do dia:",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: todayData.readings.map((r) {
                                return ActionChip(
                                  avatar: const Icon(Icons.menu_book_rounded, size: 16),
                                  label: Text("${_streamLabel(r.stream)} • Cap. ${r.chapter}"),
                                  onPressed: () async {
                                    final books = await ref.read(booksProvider.future);
                                    if (context.mounted) {
                                      final abbrev = books[r.bookIndex].abbrev;
                                      context.push('/chapter/$abbrev/${r.chapter}');
                                    }
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => context.push('/bible-year/day/$today'),
                                    icon: const Icon(Icons.auto_stories_rounded),
                                    label: const Text('Abrir Leituras do Dia'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton.filledTonal(
                                  tooltip: todayDone ? 'Desmarcar dia' : 'Marcar dia como concluído',
                                  onPressed: () async {
                                    final year = DateTime.now().year;
                                    await ref.read(localRepoProvider).toggleBibleYearDayRead(year, today);
                                    ref.invalidate(bibleYearReadDaysProvider);
                                    ref.invalidate(bibleYearStreakProvider);
                                  },
                                  icon: Icon(
                                    todayDone ? Icons.check_circle_rounded : Icons.check_rounded,
                                    color: todayDone ? Colors.green : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ===== ABA 2: LISTA DO PLANO (365 DIAS) =====
                ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: plan.days.length,
                  itemBuilder: (context, i) {
                    final day = plan.days[i].day;
                    final doneDay = readDays.contains(day);
                    final isCurrent = day == today;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : (doneDay
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : theme.colorScheme.surfaceContainerHigh),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isCurrent
                                    ? Colors.white
                                    : (doneDay ? Colors.green : null),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          'Dia $day ${isCurrent ? " (Hoje)" : ""}',
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${plan.days[i].readings.length} passagens',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                        trailing: Icon(
                          doneDay ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                          color: doneDay ? Colors.green : Colors.grey,
                        ),
                        onTap: () => context.push('/bible-year/day/$day'),
                      ),
                    );
                  },
                ),

                // ===== ABA 3: PROGRESSO & ESTATÍSTICAS =====
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              'Progresso Anual',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 10,
                                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                    color: theme.colorScheme.primary,
                                    strokeCap: StrokeCap.round,
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(progress * 100).toStringAsFixed(0)}%',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text(
                                        'concluído',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatColumn(
                                  label: "Dias Lidos",
                                  value: "$done / $total",
                                  icon: Icons.check_circle_outline_rounded,
                                  color: Colors.green,
                                ),
                                _StatColumn(
                                  label: "Sequência",
                                  value: "🔥 $streak dias",
                                  icon: Icons.local_fire_department_rounded,
                                  color: Colors.amber,
                                ),
                              ],
                            ),
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

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
