import '../../core/env.dart';
import '../api/abiblia_client.dart';
import '../api/endpoints.dart';
import '../local/bible_local_datasource.dart';
import '../local/local_repository.dart';
import '../models/bible_version.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/random_verse.dart';
import '../models/search_result.dart';

class BibleRepository {
  BibleRepository({
    required ABibliaClient client,
    required LocalRepository localRepo,
    BibleLocalDataSource? localDataSource,
  })  : _client = client,
        _localRepo = localRepo,
        _localDataSource = localDataSource ?? BibleLocalDataSource.instance;

  final ABibliaClient _client;
  final LocalRepository _localRepo;
  final BibleLocalDataSource _localDataSource;

  /// Retorna as versões disponíveis: locais embutidas + adicionais salvas ou remotas
  Future<List<BibleVersion>> getVersions() async {
    final localVersions = await _localDataSource.getLocalVersions();
    final versionsMap = <String, BibleVersion>{
      for (final v in localVersions) v.version.toLowerCase(): v,
    };

    if (Env.hasToken) {
      try {
        final res = await _client.get<List>(Endpoints.versions());
        final list = (res.data ?? []) as List;
        for (final e in list) {
          final bv = BibleVersion.fromJson(e as Map<String, dynamic>);
          final key = bv.version.toLowerCase();
          if (!versionsMap.containsKey(key)) {
            versionsMap[key] = bv;
          }
        }
      } catch (_) {
        // Modo offline: segue com versões locais sem travar
      }
    }

    return versionsMap.values.toList();
  }

  /// Retorna a lista dos 66 livros da Bíblia instantaneamente do catálogo local
  Future<List<Book>> getBooks() async {
    return _localDataSource.getBooks();
  }

  /// Busca um capítulo: Hive -> Asset Local -> API Remota (se necessário)
  Future<Chapter> getChapter(String version, String bookAbbrev, int chapter) async {
    // 1. Verifica no Hive (se baixado/cacheados previamente)
    final cached = _localRepo.getOfflineChapter(
      version: version,
      book: bookAbbrev,
      chapter: chapter,
    );
    if (cached != null) {
      final rawData = cached['data'];
      if (rawData is Map) {
        return Chapter.fromJson(rawData.cast<String, dynamic>());
      }
    }

    // 2. Verifica nos dados locais embutidos (NVI / ACF)
    final localChapter = await _localDataSource.getChapter(version, bookAbbrev, chapter);
    if (localChapter != null) {
      // Salva no cache do Hive para histórico e consistência
      await _localRepo.saveChapterOffline(
        version: version,
        book: bookAbbrev,
        chapter: chapter,
        chapterData: localChapter.toJson(),
        pinned: _localRepo.isChapterPinned(version: version, book: bookAbbrev, chapter: chapter),
      );
      return localChapter;
    }

    // 3. Se não houver localmente e tiver token, busca na API remota
    if (Env.hasToken) {
      try {
        final res = await _client.get<Map>(Endpoints.chapter(version, bookAbbrev, chapter));
        final ch = Chapter.fromJson((res.data as Map).cast<String, dynamic>());

        await _localRepo.saveChapterOffline(
          version: version,
          book: bookAbbrev,
          chapter: chapter,
          chapterData: ch.toJson(),
          pinned: _localRepo.isChapterPinned(version: version, book: bookAbbrev, chapter: chapter),
        );
        return ch;
      } catch (_) {
        // Se a busca remota falhar, tenta fallback local com NVI
        final fallbackChapter = await _localDataSource.getChapter('nvi', bookAbbrev, chapter);
        if (fallbackChapter != null) return fallbackChapter;
        rethrow;
      }
    }

    // Fallback final: tenta ler da NVI local se a versão solicitada não estava nos assets
    final fallbackChapter = await _localDataSource.getChapter('nvi', bookAbbrev, chapter);
    if (fallbackChapter != null) return fallbackChapter;

    throw Exception("Capítulo não encontrado offline e sem conexão para download.");
  }

  /// Retorna um versículo aleatório (tenta online se tiver token, com fallback local garantido)
  Future<RandomVerse> getRandomVerse(String version) async {
    if (Env.hasToken) {
      try {
        final res = await _client.get<Map>(Endpoints.randomVerse(version));
        final map = (res.data as Map).cast<String, dynamic>();
        return RandomVerse.fromJson(map);
      } catch (_) {
        // Fallback local
      }
    }

    return _localDataSource.getRandomVerse(version);
  }

  /// Busca por palavra-chave: tenta online se disponível, ou busca rápida local
  Future<List<SearchVerseResult>> search(String version, String query) async {
    if (Env.hasToken) {
      try {
        final res = await _client.post<Map>(
          Endpoints.search(),
          data: {'version': version, 'search': query},
        );

        final map = (res.data as Map?)?.cast<String, dynamic>() ?? {};
        final verses = (map['verses'] as List?) ?? const [];
        final results = verses.map((e) => SearchVerseResult.fromJson(e as Map<String, dynamic>)).toList();
        if (results.isNotEmpty) return results;
      } catch (_) {
        // Fallback local
      }
    }

    return _localDataSource.search(version, query);
  }
}
