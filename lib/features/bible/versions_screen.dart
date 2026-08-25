import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/bible_local_datasource.dart';
import '../../data/services/bible_version_service.dart';
import '../../state/providers.dart';

class VersionsScreen extends ConsumerStatefulWidget {
  const VersionsScreen({super.key});

  @override
  ConsumerState<VersionsScreen> createState() => _VersionsScreenState();
}

class _VersionsScreenState extends ConsumerState<VersionsScreen> {
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadingCodes = {};
  List<String> _installedCodes = ['nvi', 'acf'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalled();
  }

  Future<void> _loadInstalled() async {
    final installed = await BibleVersionService.instance.getInstalledVersionCodes();
    if (mounted) {
      setState(() {
        _installedCodes = installed;
        _isLoading = false;
      });
    }
  }

  Future<void> _download(BibleVersionInfo info) async {
    setState(() {
      _downloadingCodes.add(info.code);
      _downloadProgress[info.code] = 0.0;
    });

    try {
      await BibleVersionService.instance.downloadVersion(
        info.code,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _downloadProgress[info.code] = p;
            });
          }
        },
      );

      // Invalida caches
      BibleLocalDataSource.instance.invalidateVersionCache(info.code);
      ref.invalidate(versionsProvider);

      await _loadInstalled();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Versão ${info.name} instalada com sucesso!"),
            action: SnackBarAction(
              label: "Usar agora",
              onPressed: () {
                ref.read(selectedVersionProvider.notifier).state = info.code;
                ref.read(localRepoProvider).setVersion(info.code);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao baixar versão: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingCodes.remove(info.code);
          _downloadProgress.remove(info.code);
        });
      }
    }
  }

  Future<void> _delete(BibleVersionInfo info) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Excluir versão?"),
        content: Text("Deseja remover a versão '${info.name}' do seu aparelho para liberar espaço?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await BibleVersionService.instance.deleteVersion(info.code);
        BibleLocalDataSource.instance.invalidateVersionCache(info.code);

        // Se a versão excluída for a atual, volta para NVI
        final currentSelected = ref.read(selectedVersionProvider);
        if (currentSelected.toLowerCase() == info.code.toLowerCase()) {
          ref.read(selectedVersionProvider.notifier).state = 'nvi';
          ref.read(localRepoProvider).setVersion('nvi');
        }

        ref.invalidate(versionsProvider);
        await _loadInstalled();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Versão ${info.name} removida.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao excluir: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeVersion = ref.watch(selectedVersionProvider).toLowerCase();

    final catalog = BibleVersionService.catalog;
    final installedList = catalog.where((v) => _installedCodes.contains(v.code.toLowerCase())).toList();
    final availableList = catalog.where((v) => !_installedCodes.contains(v.code.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Versões da Bíblia"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Header Informativo
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_pin_rounded, color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Todas as versões instaladas ficam 100% disponíveis offline no seu smartphone.",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== SEÇÃO 1: INSTALADAS =====
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "Versões Instaladas (${installedList.length})",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...installedList.map((info) {
                  final isSelected = activeVersion == info.code.toLowerCase();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(info.flag, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          info.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHigh,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            info.code.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${info.language} • ${info.size}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (info.isBuiltIn)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Embutida",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.teal,
                                    ),
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: "Excluir versão baixada",
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  onPressed: () => _delete(info),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            info.description,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: isSelected
                                ? OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.check_rounded, color: Colors.green),
                                    label: const Text(
                                      "Versão Ativa",
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
                                    ),
                                  )
                                : FilledButton.tonal(
                                    onPressed: () {
                                      ref.read(selectedVersionProvider.notifier).state = info.code;
                                      ref.read(localRepoProvider).setVersion(info.code);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Versão alterada para ${info.name}."),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: const Text("Usar esta versão"),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                if (availableList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  // ===== SEÇÃO 2: DISPONÍVEIS PARA DOWNLOAD =====
                  Row(
                    children: [
                      const Icon(Icons.cloud_download_outlined, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        "Disponíveis para Download (${availableList.length})",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...availableList.map((info) {
                    final isDownloading = _downloadingCodes.contains(info.code);
                    final progress = _downloadProgress[info.code] ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(info.flag, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            info.name,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHigh,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              info.code.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${info.language} • ${info.size}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              info.description,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isDownloading) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "${(progress * 100).toStringAsFixed(0)}%",
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _download(info),
                                  icon: const Icon(Icons.download_rounded, size: 18),
                                  label: Text("Baixar Versão (${info.size})"),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
