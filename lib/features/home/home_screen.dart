import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/api/bible_year_service.dart';
import '../../state/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ({String emoji, String greeting, String subtitle}) _greeting() {
    final now = DateTime.now().toLocal();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return (
        emoji: "🌅",
        greeting: "Bom dia",
        subtitle: "Comece o seu dia com a Palavra de Deus"
      );
    } else if (hour >= 12 && hour < 18) {
      return (
        emoji: "☀️",
        greeting: "Boa tarde",
        subtitle: "Que a paz do Senhor continue com você"
      );
    } else {
      return (
        emoji: "🌙",
        greeting: "Boa noite",
        subtitle: "Descanse e medite na presença de Deus"
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _greeting();
    final verseAsync = ref.watch(randomVerseProvider);
    final version = ref.watch(selectedVersionProvider);
    final streak = ref.watch(bibleYearStreakProvider);
    final today = BibleYearService.todayDayNumber();
    final readDays = ref.watch(bibleYearReadDaysProvider);
    final todayDone = readDays.contains(today);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // -------- APP BAR MODERNA --------
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: true,
            expandedHeight: 80,
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Bíblia Sagrada",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      version.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: "Buscar",
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push("/search"),
              ),
              IconButton(
                tooltip: "Configurações",
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => context.push("/settings"),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // -------- CONTEÚDO PRINCIPAL --------
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. SAUDAÇÃO HERO
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 4),
                  child: Row(
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${g.greeting}!",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              g.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. VERSÍCULO DO DIA (CARD DESTAQUE)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF1E293B),
                                const Color(0xFF0F172A),
                              ]
                            : [
                                const Color(0xFFFFFFFF),
                                const Color(0xFFF1F5F9),
                              ],
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: verseAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                      error: (_, __) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text("Carregando versículo offline..."),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () => ref.invalidate(randomVerseProvider),
                            ),
                          ],
                        ),
                      ),
                      data: (v) {
                        final refText = "${v.bookName} ${v.chapter}:${v.verse}";
                        final shareMsg = "📖 $refText ($version)\n\n\"${v.text}\"\n\n— Bíblia Sagrada";

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.secondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        "VERSÍCULO DO DIA",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.secondary,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: "Novo Versículo",
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  onPressed: () => ref.invalidate(randomVerseProvider),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: "Copiar",
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: "$refText\n\"${v.text}\""));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Versículo copiado!")),
                                    );
                                  },
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: "Compartilhar",
                                  icon: const Icon(Icons.share_outlined, size: 18),
                                  onPressed: () => Share.share(shareMsg),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "“${v.text}”",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16.5,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  refText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () => context.push("/chapter/${v.bookAbbrev}/${v.chapter}"),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: const Text("Ler capítulo"),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. BARRA DE ANO BÍBLICO / STREAK
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push("/bible-year"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Ano Bíblico • Dia $today de 365",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                todayDone
                                    ? "✅ Leitura de hoje concluída! (🔥 $streak dias seguidos)"
                                    : "⏳ Leitura de hoje pendente • Toque para ler",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: todayDone ? Colors.green.shade600 : theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. TÍTULO: NAVEGAÇÃO RÁPIDA
                Text(
                  "Navegação & Estudo",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),

                // 5. GRID DE ACESSO RÁPIDO (2x2)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _QuickCard(
                      title: "Livros da Bíblia",
                      subtitle: "66 Livros • AT e NT",
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF2563EB),
                      onTap: () => context.push("/books"),
                    ),
                    _QuickCard(
                      title: "Ano Bíblico",
                      subtitle: "Plano de 365 Dias",
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFFD97706),
                      onTap: () => context.push("/bible-year"),
                    ),
                    _QuickCard(
                      title: "Buscar Texto",
                      subtitle: "Pesquisar versículos",
                      icon: Icons.search_rounded,
                      color: const Color(0xFF0D9488),
                      onTap: () => context.push("/search"),
                    ),
                    _QuickCard(
                      title: "Favoritos",
                      subtitle: "Versículos salvos",
                      icon: Icons.bookmark_rounded,
                      color: const Color(0xFFE11D48),
                      onTap: () => context.push("/favorites"),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 6. BIBLIOTECA PESSOAL
                Text(
                  "Minha Biblioteca",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  child: Column(
                    children: [
                      _ListMenuTile(
                        icon: Icons.edit_note_rounded,
                        iconColor: Colors.purple,
                        title: "Minhas Anotações",
                        onTap: () => context.push("/notes"),
                      ),
                      const Divider(),
                      _ListMenuTile(
                        icon: Icons.history_rounded,
                        iconColor: Colors.blue,
                        title: "Histórico de Leitura",
                        onTap: () => context.push("/history"),
                      ),
                      const Divider(),
                      _ListMenuTile(
                        icon: Icons.download_for_offline_rounded,
                        iconColor: Colors.teal,
                        title: "Downloads Offline",
                        onTap: () => context.push("/offline"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListMenuTile extends StatelessWidget {
  const _ListMenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
