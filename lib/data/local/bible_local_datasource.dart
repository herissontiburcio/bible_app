import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

import '../models/book.dart';
import '../models/bible_version.dart';
import '../models/chapter.dart';
import '../models/verse.dart';
import '../models/random_verse.dart';
import '../models/search_result.dart';
import '../services/bible_version_service.dart';

class BibleLocalDataSource {
  static final BibleLocalDataSource instance = BibleLocalDataSource._();
  BibleLocalDataSource._();

  // Cache em memória dos dados dos arquivos de versões já carregadas (ex: nvi, acf)
  final Map<String, List<Map<String, dynamic>>> _versionDataCache = {};

  static final List<Book> _canonicalBooks = [
    Book(abbrev: 'gn', name: 'Gênesis', chapters: 50),
    Book(abbrev: 'ex', name: 'Êxodo', chapters: 40),
    Book(abbrev: 'lv', name: 'Levítico', chapters: 27),
    Book(abbrev: 'nm', name: 'Números', chapters: 36),
    Book(abbrev: 'dt', name: 'Deuteronômio', chapters: 34),
    Book(abbrev: 'js', name: 'Josué', chapters: 24),
    Book(abbrev: 'jz', name: 'Juízes', chapters: 21),
    Book(abbrev: 'rt', name: 'Rute', chapters: 4),
    Book(abbrev: '1sm', name: '1 Samuel', chapters: 31),
    Book(abbrev: '2sm', name: '2 Samuel', chapters: 24),
    Book(abbrev: '1rs', name: '1 Reis', chapters: 22),
    Book(abbrev: '2rs', name: '2 Reis', chapters: 25),
    Book(abbrev: '1cr', name: '1 Crônicas', chapters: 29),
    Book(abbrev: '2cr', name: '2 Crônicas', chapters: 36),
    Book(abbrev: 'ed', name: 'Esdras', chapters: 10),
    Book(abbrev: 'ne', name: 'Neemias', chapters: 13),
    Book(abbrev: 'et', name: 'Ester', chapters: 10),
    Book(abbrev: 'job', name: 'Jó', chapters: 42),
    Book(abbrev: 'sl', name: 'Salmos', chapters: 150),
    Book(abbrev: 'pv', name: 'Provérbios', chapters: 31),
    Book(abbrev: 'ec', name: 'Eclesiastes', chapters: 12),
    Book(abbrev: 'ct', name: 'Cânticos', chapters: 8),
    Book(abbrev: 'is', name: 'Isaías', chapters: 66),
    Book(abbrev: 'jr', name: 'Jeremias', chapters: 52),
    Book(abbrev: 'lm', name: 'Lamentações', chapters: 5),
    Book(abbrev: 'ez', name: 'Ezequiel', chapters: 48),
    Book(abbrev: 'dn', name: 'Daniel', chapters: 12),
    Book(abbrev: 'os', name: 'Oséias', chapters: 14),
    Book(abbrev: 'jl', name: 'Joel', chapters: 3),
    Book(abbrev: 'am', name: 'Amós', chapters: 9),
    Book(abbrev: 'ob', name: 'Obadias', chapters: 1),
    Book(abbrev: 'jn', name: 'Jonas', chapters: 4),
    Book(abbrev: 'mq', name: 'Miquéias', chapters: 7),
    Book(abbrev: 'na', name: 'Naum', chapters: 3),
    Book(abbrev: 'hc', name: 'Habacuque', chapters: 3),
    Book(abbrev: 'sf', name: 'Sofonias', chapters: 3),
    Book(abbrev: 'ag', name: 'Ageu', chapters: 2),
    Book(abbrev: 'zc', name: 'Zacarias', chapters: 14),
    Book(abbrev: 'ml', name: 'Malaquias', chapters: 4),
    Book(abbrev: 'mt', name: 'Mateus', chapters: 28),
    Book(abbrev: 'mc', name: 'Marcos', chapters: 16),
    Book(abbrev: 'lc', name: 'Lucas', chapters: 24),
    Book(abbrev: 'jo', name: 'João', chapters: 21),
    Book(abbrev: 'at', name: 'Atos', chapters: 28),
    Book(abbrev: 'rm', name: 'Romanos', chapters: 16),
    Book(abbrev: '1co', name: '1 Coríntios', chapters: 16),
    Book(abbrev: '2co', name: '2 Coríntios', chapters: 13),
    Book(abbrev: 'gl', name: 'Gálatas', chapters: 6),
    Book(abbrev: 'ef', name: 'Efésios', chapters: 6),
    Book(abbrev: 'fp', name: 'Filipenses', chapters: 4),
    Book(abbrev: 'cl', name: 'Colossenses', chapters: 4),
    Book(abbrev: '1ts', name: '1 Tessalonicenses', chapters: 5),
    Book(abbrev: '2ts', name: '2 Tessalonicenses', chapters: 3),
    Book(abbrev: '1tm', name: '1 Timóteo', chapters: 6),
    Book(abbrev: '2tm', name: '2 Timóteo', chapters: 4),
    Book(abbrev: 'tt', name: 'Tito', chapters: 3),
    Book(abbrev: 'fm', name: 'Filemom', chapters: 1),
    Book(abbrev: 'hb', name: 'Hebreus', chapters: 13),
    Book(abbrev: 'tg', name: 'Tiago', chapters: 5),
    Book(abbrev: '1pe', name: '1 Pedro', chapters: 5),
    Book(abbrev: '2pe', name: '2 Pedro', chapters: 3),
    Book(abbrev: '1jo', name: '1 João', chapters: 5),
    Book(abbrev: '2jo', name: '2 João', chapters: 1),
    Book(abbrev: '3jo', name: '3 João', chapters: 1),
    Book(abbrev: 'jd', name: 'Judas', chapters: 1),
    Book(abbrev: 'ap', name: 'Apocalipse', chapters: 22),
  ];

  List<Book> getBooks() => List.unmodifiable(_canonicalBooks);

  void invalidateVersionCache(String version) {
    _versionDataCache.remove(version.toLowerCase().trim());
  }

  Future<List<BibleVersion>> getLocalVersions() async {
    final installedCodes = await BibleVersionService.instance.getInstalledVersionCodes();
    final result = <BibleVersion>[];

    for (final code in installedCodes) {
      final info = BibleVersionService.getInfoByCode(code);
      if (info != null) {
        result.add(BibleVersion(version: info.code, name: "${info.flag} ${info.name}"));
      } else {
        result.add(BibleVersion(version: code, name: code.toUpperCase()));
      }
    }
    return result;
  }

  /// Normaliza abreviação para encontrar o índice do livro (0 a 65)
  int? findBookIndex(String rawAbbrev) {
    final clean = rawAbbrev.trim().toLowerCase();

    // Mapeamento direto por índice canônico ou abreviação
    for (int i = 0; i < _canonicalBooks.length; i++) {
      final b = _canonicalBooks[i];
      if (b.abbrev.toLowerCase() == clean) return i;
    }

    // Aliases comuns
    final aliases = {
      'jó': 17,
      'jo': 42,
      'job': 17,
      'atos': 43,
      'at': 43,
      'genesis': 0,
      'gênesis': 0,
      'exodo': 1,
      'êxodo': 1,
      'levitico': 2,
      'levítico': 2,
      'numeros': 3,
      'números': 3,
      'deuteronomio': 4,
      'deuteronômio': 4,
      'josue': 5,
      'josué': 5,
      'juizes': 6,
      'juízes': 6,
      'rute': 7,
      'salmos': 18,
      'proverbios': 19,
      'provérbios': 19,
      'mateus': 39,
      'marcos': 40,
      'lucas': 41,
      'joao': 42,
      'joão': 42,
      'romanos': 44,
      'apocalipse': 65,
    };

    return aliases[clean];
  }

  Future<List<Map<String, dynamic>>?> _loadVersionData(String version) async {
    final v = version.toLowerCase().trim();
    if (_versionDataCache.containsKey(v)) {
      return _versionDataCache[v];
    }

    try {
      // 1. Tenta carregar dos assets embutidos (NVI / ACF)
      if (v == 'acf') {
        final str = await rootBundle.loadString('assets/bible/acf.json');
        final rawList = jsonDecode(str) as List;
        final parsed = rawList.map((e) => (e as Map).cast<String, dynamic>()).toList();
        _versionDataCache[v] = parsed;
        return parsed;
      } else if (v == 'nvi') {
        final str = await rootBundle.loadString('assets/bible/nvi.json');
        final rawList = jsonDecode(str) as List;
        final parsed = rawList.map((e) => (e as Map).cast<String, dynamic>()).toList();
        _versionDataCache[v] = parsed;
        return parsed;
      }

      // 2. Tenta carregar do armazenamento de versões baixadas
      final downloadedFile = await BibleVersionService.instance.getVersionFile(v);
      if (await downloadedFile.exists()) {
        final str = await downloadedFile.readAsString();
        final rawList = jsonDecode(str) as List;
        final parsed = rawList.map((e) => (e as Map).cast<String, dynamic>()).toList();
        _versionDataCache[v] = parsed;
        return parsed;
      }

      // 3. Se não encontrar a versão baixada, fallback para NVI
      return await _loadVersionData('nvi');
    } catch (_) {
      if (v != 'nvi') {
        return await _loadVersionData('nvi');
      }
      return null;
    }
  }

  Future<Chapter?> getChapter(String version, String bookAbbrev, int chapterNumber) async {
    final data = await _loadVersionData(version);
    if (data == null) return null;

    final index = findBookIndex(bookAbbrev);
    if (index == null || index < 0 || index >= data.length) return null;

    final bookJson = data[index];
    final bookName = (bookJson['name'] ?? _canonicalBooks[index].name).toString();
    final chaptersList = (bookJson['chapters'] as List? ?? []);

    if (chapterNumber < 1 || chapterNumber > chaptersList.length) return null;

    final versesRaw = (chaptersList[chapterNumber - 1] as List? ?? []);
    final verses = <Verse>[];
    for (int i = 0; i < versesRaw.length; i++) {
      verses.add(Verse(number: i + 1, text: versesRaw[i].toString()));
    }

    return Chapter(
      bookName: bookName,
      chapter: chapterNumber,
      verses: verses,
    );
  }

  Future<RandomVerse> getRandomVerse(String version) async {
    final data = await _loadVersionData(version);
    final random = math.Random();

    if (data != null && data.isNotEmpty) {
      // Escolhe um livro aleatório com preferência para livros populares de meditação
      final popularBookIndices = [
        18, // Salmos
        19, // Provérbios
        22, // Isaías
        39, // Mateus
        41, // Lucas
        42, // João
        44, // Romanos
        48, // Efésios
        49, // Filipenses
      ];

      final bookIdx = random.nextBool()
          ? popularBookIndices[random.nextInt(popularBookIndices.length)]
          : random.nextInt(data.length);

      final bookJson = data[bookIdx];
      final bookAbbrev = _canonicalBooks[bookIdx].abbrev;
      final bookName = (bookJson['name'] ?? _canonicalBooks[bookIdx].name).toString();
      final chapters = (bookJson['chapters'] as List? ?? []);

      if (chapters.isNotEmpty) {
        final chIdx = random.nextInt(chapters.length);
        final verses = (chapters[chIdx] as List? ?? []);
        if (verses.isNotEmpty) {
          final vIdx = random.nextInt(verses.length);
          return RandomVerse(
            bookAbbrev: bookAbbrev,
            bookName: bookName,
            chapter: chIdx + 1,
            verse: vIdx + 1,
            text: verses[vIdx].toString(),
          );
        }
      }
    }

    // Fallback padrão se arquivo não puder ser lido
    return RandomVerse(
      bookAbbrev: 'sl',
      bookName: 'Salmos',
      chapter: 23,
      verse: 1,
      text: 'O Senhor é o meu pastor; de nada terei falta.',
    );
  }

  Future<List<SearchVerseResult>> search(String version, String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final data = await _loadVersionData(version);
    if (data == null) return [];

    final results = <SearchVerseResult>[];

    for (int bIdx = 0; bIdx < data.length; bIdx++) {
      final bookJson = data[bIdx];
      final bookAbbrev = _canonicalBooks[bIdx].abbrev;
      final bookName = (bookJson['name'] ?? _canonicalBooks[bIdx].name).toString();
      final chapters = (bookJson['chapters'] as List? ?? []);

      for (int cIdx = 0; cIdx < chapters.length; cIdx++) {
        final verses = (chapters[cIdx] as List? ?? []);
        for (int vIdx = 0; vIdx < verses.length; vIdx++) {
          final verseText = verses[vIdx].toString();
          if (verseText.toLowerCase().contains(cleanQuery)) {
            results.add(
              SearchVerseResult(
                abbrev: bookAbbrev,
                book: bookName,
                chapter: cIdx + 1,
                verse: vIdx + 1,
                text: verseText,
              ),
            );

            // Limite para alta performance
            if (results.length >= 60) return results;
          }
        }
      }
    }

    return results;
  }
}
