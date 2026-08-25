import 'package:flutter_test/flutter_test.dart';
import 'package:bible_app/data/local/bible_local_datasource.dart';
import 'package:bible_app/data/services/bible_version_service.dart';

void main() {
  test('BibleLocalDataSource contains all 66 books in canonical order', () {
    final ds = BibleLocalDataSource.instance;
    final books = ds.getBooks();

    expect(books.length, 66);
    expect(books.first.abbrev, 'gn');
    expect(books.first.name, 'Gênesis');
    expect(books.first.chapters, 50);

    expect(books[38].abbrev, 'ml'); // Malaquias
    expect(books[39].abbrev, 'mt'); // Mateus
    expect(books.last.abbrev, 'ap'); // Apocalipse
    expect(books.last.chapters, 22);
  });

  test('BibleLocalDataSource findBookIndex normalizes aliases correctly', () {
    final ds = BibleLocalDataSource.instance;

    expect(ds.findBookIndex('gn'), 0);
    expect(ds.findBookIndex('genesis'), 0);
    expect(ds.findBookIndex('Gênesis'), 0);
    expect(ds.findBookIndex('at'), 43);
    expect(ds.findBookIndex('atos'), 43);
    expect(ds.findBookIndex('mt'), 39);
    expect(ds.findBookIndex('ap'), 65);
  });

  test('BibleVersionService catalog contains built-in and downloadable versions', () {
    expect(BibleVersionService.catalog.isNotEmpty, true);
    
    final nvi = BibleVersionService.getInfoByCode('nvi');
    expect(nvi != null, true);
    expect(nvi!.isBuiltIn, true);

    final acf = BibleVersionService.getInfoByCode('acf');
    expect(acf != null, true);
    expect(acf!.isBuiltIn, true);

    final aa = BibleVersionService.getInfoByCode('aa');
    expect(aa != null, true);
    expect(aa!.isBuiltIn, false);
    expect(aa.downloadUrl != null, true);

    final kjv = BibleVersionService.getInfoByCode('kjv');
    expect(kjv != null, true);
    expect(kjv!.isBuiltIn, false);
  });
}
