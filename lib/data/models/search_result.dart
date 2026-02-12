class SearchVerseResult {
  final String abbrev;
  final String book;
  final int chapter;
  final int verse;
  final String text;

  SearchVerseResult({
    required this.abbrev,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory SearchVerseResult.fromJson(Map<String, dynamic> json) {
    final book = json['book'] as Map<String, dynamic>? ?? {};
    return SearchVerseResult(
      abbrev: (book['abbrev']?['pt'] ?? book['abbrev']?['en'] ?? '').toString(),
      book: (book['name'] ?? '').toString(),
      chapter: json['chapter'] is int ? json['chapter'] : int.tryParse('${json['chapter']}') ?? 0,
      verse: json['number'] is int ? json['number'] : int.tryParse('${json['number']}') ?? 0,
      text: (json['text'] ?? '').toString(),
    );
  }
}
