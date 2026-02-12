import 'verse.dart';

class Chapter {
  final String bookName;
  final int chapter;
  final List<Verse> verses;

  Chapter({required this.bookName, required this.chapter, required this.verses});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final book = json['book'] as Map<String, dynamic>? ?? {};
    final verses = (json['verses'] as List? ?? []).map((e) => Verse.fromJson(e as Map<String, dynamic>)).toList();
    return Chapter(
      bookName: (book['name'] ?? '').toString(),
      chapter: json['chapter'] is int ? json['chapter'] : int.tryParse('${json['chapter']}') ?? 0,
      verses: verses,
    );
  }

  Map<String, dynamic> toJson() => {
    'book': {'name': bookName},
    'chapter': chapter,
    'verses': verses.map((v) => v.toJson()).toList(),
  };
}
