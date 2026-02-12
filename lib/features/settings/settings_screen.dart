import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../core/notifications/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _fmt(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.read(localRepoProvider);

    final fontScale = ref.watch(fontScaleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final redLetter = ref.watch(redLetterExperimentalProvider);

    final dailyEnabled = ref.watch(dailyVerseEnabledProvider);
    final dailyTime = ref.watch(dailyVerseTimeProvider);

    Future<void> applyDailyVerseSchedule() async {
      final version = ref.read(selectedVersionProvider);
      final verse = await ref.read(bibleRepoProvider).getRandomVerse(version);

      final title = "Versículo do dia • $version";
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
        padding: const EdgeInsets.all(12),
        children: [
          const Text("Acessibilidade", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          ListTile(
            title: const Text("Tamanho da letra"),
            subtitle: Text("Escala: ${fontScale.toStringAsFixed(2)}"),
          ),
          Slider(
            value: fontScale,
            min: 0.85,
            max: 1.40,
            divisions: 11,
            label: fontScale.toStringAsFixed(2),
            onChanged: (v) async {
              ref.read(fontScaleProvider.notifier).state = v;
              await local.setFontScale(v);
            },
          ),

          const Divider(),
          const Text("Aparência", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          RadioListTile(
            value: ThemeMode.system,
            groupValue: themeMode,
            title: const Text("Usar tema do sistema"),
            onChanged: (_) async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.system;
              await local.setThemeMode('system');
            },
          ),
          RadioListTile(
            value: ThemeMode.light,
            groupValue: themeMode,
            title: const Text("Modo claro"),
            onChanged: (_) async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.light;
              await local.setThemeMode('light');
            },
          ),
          RadioListTile(
            value: ThemeMode.dark,
            groupValue: themeMode,
            title: const Text("Modo escuro"),
            onChanged: (_) async {
              ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
              await local.setThemeMode('dark');
            },
          ),

          const Divider(),
          const Text("Versículo do dia", style: TextStyle(fontWeight: FontWeight.w700)),
          SwitchListTile(
            title: const Text("Ativar notificação diária"),
            subtitle: const Text("Receber um versículo automaticamente no horário escolhido."),
            value: dailyEnabled,
            onChanged: (v) async {
              ref.read(dailyVerseEnabledProvider.notifier).state = v;
              await local.setDailyVerseEnabled(v);

              if (!v) {
                await NotificationService.instance.cancelDailyVerse();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Versículo do dia desativado.")),
                  );
                }
                return;
              }

              // ativou → agenda agora
              await applyDailyVerseSchedule();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Notificação agendada para ${_fmt(dailyTime)}")),
                );
              }
            },
          ),

          ListTile(
            title: const Text("Horário do versículo"),
            subtitle: Text(_fmt(dailyTime)),
            trailing: const Icon(Icons.schedule),
            onTap: !dailyEnabled
                ? null
                : () async {
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

          const Divider(),
          const Text("Experimental", style: TextStyle(fontWeight: FontWeight.w700)),
          SwitchListTile(
            title: const Text("Destacar falas de Jesus (vermelho)"),
            subtitle: const Text("Heurística (pode errar). A API não marca red-letter."),
            value: redLetter,
            onChanged: (v) async {
              ref.read(redLetterExperimentalProvider.notifier).state = v;
              await local.setRedLetterExperimental(v);
            },
          ),
        ],
      ),
    );
  }
}
