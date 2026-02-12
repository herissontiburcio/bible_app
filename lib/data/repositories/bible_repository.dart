import 'package:bible_app/data/models/random_verse.dart';

import '../api/abiblia_client.dart';
import '../api/endpoints.dart';
import '../models/bible_version.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/search_result.dart';

class BibleRepository {
  BibleRepository(this._client);
  final ABibliaClient _client;

  Future<List<BibleVersion>> getVersions() async {
    final res = await _client.get<List>(Endpoints.versions());
    final list = (res.data ?? []) as List;
    return list.map((e) => BibleVersion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Book>> getBooks() async {
    final res = await _client.get<List>(Endpoints.books());
    final list = (res.data ?? []) as List;
    return list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Chapter> getChapter(String version, String bookAbbrev, int chapter) async {
    final res = await _client.get<Map>(Endpoints.chapter(version, bookAbbrev, chapter));
    return Chapter.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<RandomVerse> getRandomVerse(String version) async {
    final res = await _client.get<Map>(Endpoints.randomVerse(version));
    final map = (res.data as Map).cast<String, dynamic>();
    return RandomVerse.fromJson(map);
  }


  Future<List<SearchVerseResult>> search(String version, String query) async {
    final res = await _client.post<Map>(
      Endpoints.search(),
      data: {'version': version, 'search': query},
    );

    final map = (res.data as Map?)?.cast<String, dynamic>() ?? {};
    final verses = (map['verses'] as List?) ?? const [];
    return verses.map((e) => SearchVerseResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}
