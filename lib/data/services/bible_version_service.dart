import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class BibleVersionInfo {
  final String code;
  final String name;
  final String language;
  final String flag;
  final String size;
  final String description;
  final bool isBuiltIn;
  final String? downloadUrl;

  const BibleVersionInfo({
    required this.code,
    required this.name,
    required this.language,
    required this.flag,
    required this.size,
    required this.description,
    this.isBuiltIn = false,
    this.downloadUrl,
  });
}

class BibleVersionService {
  BibleVersionService._();
  static final instance = BibleVersionService._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 25),
    receiveTimeout: const Duration(seconds: 45),
  ));

  static const List<BibleVersionInfo> catalog = [
    // === PORTUGUÊS ===
    BibleVersionInfo(
      code: 'nvi',
      name: 'Nova Versão Internacional',
      language: 'Português',
      flag: '🇧🇷',
      size: '4.0 MB',
      description: 'Linguagem contemporânea, clara e de fácil compreensão.',
      isBuiltIn: true,
    ),
    BibleVersionInfo(
      code: 'acf',
      name: 'Almeida Corrigida Fiel',
      language: 'Português',
      flag: '🇧🇷',
      size: '4.0 MB',
      description: 'Baseada no Textus Receptus, clássica e fiel aos originais.',
      isBuiltIn: true,
    ),
    BibleVersionInfo(
      code: 'aa',
      name: 'Almeida Revisada (Atualizada)',
      language: 'Português',
      flag: '🇧🇷',
      size: '3.9 MB',
      description: 'Tradução tradicional da Imprensa Bíblica Brasileira.',
      isBuiltIn: false,
      downloadUrl: 'https://raw.githubusercontent.com/thiagobodruk/bible/master/json/pt_aa.json',
    ),

    // === INGLÊS ===
    BibleVersionInfo(
      code: 'kjv',
      name: 'King James Version',
      language: 'English',
      flag: '🇺🇸',
      size: '4.3 MB',
      description: 'A mais famosa e respeitada tradução clássica em língua inglesa.',
      isBuiltIn: false,
      downloadUrl: 'https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_kjv.json',
    ),
    BibleVersionInfo(
      code: 'bbe',
      name: 'Bible in Basic English',
      language: 'English',
      flag: '🇺🇸',
      size: '4.0 MB',
      description: 'Tradução com vocabulário simplificado em inglês (850 palavras básicas).',
      isBuiltIn: false,
      downloadUrl: 'https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_bbe.json',
    ),

    // === ESPANHOL ===
    BibleVersionInfo(
      code: 'rvr',
      name: 'Reina-Valera 1909',
      language: 'Español',
      flag: '🇪🇸',
      size: '3.8 MB',
      description: 'A tradução mais tradicional e lida no mundo hispânico.',
      isBuiltIn: false,
      downloadUrl: 'https://raw.githubusercontent.com/thiagobodruk/bible/master/json/es_rvr.json',
    ),

    // === FRANCÊS ===
    BibleVersionInfo(
      code: 'apee',
      name: "Bible de l'Épée",
      language: 'Français',
      flag: '🇫🇷',
      size: '4.1 MB',
      description: 'Tradução francesa fiel de referência histórica.',
      isBuiltIn: false,
      downloadUrl: 'https://raw.githubusercontent.com/thiagobodruk/bible/master/json/fr_apee.json',
    ),

    // === ALEMÃO ===
    BibleVersionInfo(
      code: 'schlachter',
      name: 'Schlachter Bibel',
      language: 'Deutsch',
      flag: '🇩🇪',
      size: '4.1 MB',
      description: 'Uma das mais populares traduções bíblicas em alemão.',
      isBuiltIn: false,
      downloadUrl: 'https://raw.githubusercontent.com/thiagobodruk/bible/master/json/de_schlachter.json',
    ),
  ];

  static BibleVersionInfo? getInfoByCode(String code) {
    final norm = code.trim().toLowerCase();
    try {
      return catalog.firstWhere((v) => v.code.toLowerCase() == norm);
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _getVersionsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final versionsDir = Directory('${appDir.path}/bible_versions');
    if (!await versionsDir.exists()) {
      await versionsDir.create(recursive: true);
    }
    return versionsDir;
  }

  Future<File> getVersionFile(String code) async {
    final dir = await _getVersionsDir();
    return File('${dir.path}/${code.trim().toLowerCase()}.json');
  }

  Future<bool> isVersionInstalled(String code) async {
    final norm = code.trim().toLowerCase();
    if (norm == 'nvi' || norm == 'acf') return true;

    final file = await getVersionFile(norm);
    return await file.exists();
  }

  Future<List<String>> getInstalledVersionCodes() async {
    final installed = <String>['nvi', 'acf'];
    try {
      final dir = await _getVersionsDir();
      final files = dir.listSync();
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          final fileName = entity.uri.pathSegments.last;
          final code = fileName.replaceAll('.json', '').toLowerCase();
          if (!installed.contains(code)) {
            installed.add(code);
          }
        }
      }
    } catch (_) {}
    return installed;
  }

  Future<void> downloadVersion(
    String code, {
    void Function(double progress)? onProgress,
  }) async {
    final info = getInfoByCode(code);
    if (info == null || info.downloadUrl == null) {
      throw Exception("Versão $code não possui link de download disponível.");
    }

    final targetFile = await getVersionFile(code);
    final tempFile = File('${targetFile.path}.tmp');

    try {
      await _dio.download(
        info.downloadUrl!,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  Future<void> deleteVersion(String code) async {
    final norm = code.trim().toLowerCase();
    if (norm == 'nvi' || norm == 'acf') {
      throw Exception("Não é possível excluir versões embutidas do aplicativo.");
    }

    final file = await getVersionFile(norm);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
