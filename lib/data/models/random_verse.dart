class RandomVerse {
  final String bookAbbrev;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;

  RandomVerse({
    required this.bookAbbrev,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory RandomVerse.fromJson(Map<String, dynamic> json) {
    final book = (json['book'] as Map?)?.cast<String, dynamic>() ?? {};
    final abbrevObj = book['abbrev'];

    final abbrev = abbrevObj is Map
        ? (abbrevObj['pt'] ?? abbrevObj['en'] ?? '')
        : (abbrevObj ?? '');

    return RandomVerse(
      bookAbbrev: abbrev.toString(),
      bookName: (book['name'] ?? '').toString(),
      chapter: json['chapter'] is int ? json['chapter'] : int.tryParse('${json['chapter']}') ?? 0,
      verse: json['number'] is int ? json['number'] : int.tryParse('${json['number']}') ?? 0,
      text: (json['text'] ?? '').toString(),
    );
  }
}
