import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_service.dart';
import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _fmt(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.read(localRepoProvider);

    final fontScale = ref.watch(fontScaleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final redLetter = ref.watch(redLetterExperimentalProvider);

    final dailyEnabled = ref.watch(dailyVerseEnabledProvider);
    final dailyTime = ref.watch(dailyVerseTimeProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Future<void> applyDailyVerseSchedule() async {
      final version = ref.read(selectedVersionProvider);
      final verse = await ref.read(bibleRepoProvider).getRandomVerse(version);

      final title = "Versículo do dia • ${version.toUpperCase()}";
      final body = "${verse.bookName} ${verse.chapter}:${verse.verse}\n\n${verse.text}";

      await NotificationService.instance.scheduleDailyVerse(
        hour: dailyTime.hour,
        minute: dailyTime.minute,
        title: title,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. TEMA & APARÊNCIA
          Text(
            "Aparência do Aplicativo",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ThemeCard(
                  title: "Sistema",
                  icon: Icons.brightness_auto_rounded,
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () async {
                    ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                    await local.setThemeMode('system');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThemeCard(
                  title: "Claro",
                  icon: Icons.light_mode_rounded,
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () async {
                    ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                    await local.setThemeMode('light');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThemeCard(
                  title: "Escuro",
                  icon: Icons.dark_mode_rounded,
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () async {
                    ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                    await local.setThemeMode('dark');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. ACESSIBILIDADE & FONTE
          Text(
            "Tamanho da Letra",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Escala do Texto",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${(fontScale * 100).toInt()}%",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: fontScale,
                    min: 0.85,
                    max: 1.40,
                    divisions: 11,
                    label: "${(fontScale * 100).toInt()}%",
                    onChanged: (v) async {
                      ref.read(fontScaleProvider.notifier).state = v;
                      await local.setFontScale(v);
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "“Lâmpada para os meus pés é tua palavra e luz, para o meu caminho.” (Salmos 119:105)",
                      style: TextStyle(
                        fontSize: 14 * fontScale,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. NOTIFICAÇÕES (VERSÍCULO DIÁRIO)
          Text(
            "Notificações Diárias",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 22),
                  ),
                  title: const Text(
                    "Versículo do Dia",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  subtitle: const Text(
                    "Receba um versículo inspirador no horário programado.",
                    style: TextStyle(fontSize: 12.5),
                  ),
                  value: dailyEnabled,
                  onChanged: (v) async {
                    ref.read(dailyVerseEnabledProvider.notifier).state = v;
                    await local.setDailyVerseEnabled(v);

                    if (!v) {
                      await NotificationService.instance.cancelDailyVerse();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Notificação diária desativada.")),
                        );
                      }
                      return;
                    }

                    await applyDailyVerseSchedule();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Notificação agendada para ${_fmt(dailyTime)}")),
                      );
                    }
                  },
                ),
                if (dailyEnabled) ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.schedule_rounded, color: theme.colorScheme.primary, size: 22),
                    ),
                    title: const Text(
                      "Horário da Notificação",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _fmt(dailyTime),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: dailyTime,
                      );
                      if (picked == null) return;

                      ref.read(dailyVerseTimeProvider.notifier).state = picked;
                      await local.setDailyVerseHour(picked.hour);
                      await local.setDailyVerseMinute(picked.minute);

                      await applyDailyVerseSchedule();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Horário atualizado para ${_fmt(picked)}")),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. EXPERIMENTAL & LEITURA
          Text(
            "Leitura & Recursos",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.format_quote_rounded, color: Colors.red, size: 22),
              ),
              title: const Text(
                "Falas de Jesus em Vermelho",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: const Text(
                "Destaca citações nos Evangelhos (recurso visual auxiliar).",
                style: TextStyle(fontSize: 12.5),
              ),
              value: redLetter,
              onChanged: (v) async {
                ref.read(redLetterExperimentalProvider.notifier).state = v;
                await local.setRedLetterExperimental(v);
              },
            ),
          ),
          const SizedBox(height: 24),

          // 5. VERSÕES DA BÍBLIA
          Text(
            "Versões da Bíblia",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_download_rounded, color: Colors.blue, size: 22),
              ),
              title: const Text(
                "Gerenciar & Baixar Versões",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: const Text(
                "Baixe mais traduções (Almeida Atualizada, King James, etc.) para uso offline.",
                style: TextStyle(fontSize: 12.5),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/versions'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
