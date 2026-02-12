class Book {
  final String abbrev;
  final String name;
  final int chapters;

  Book({required this.abbrev, required this.name, required this.chapters});

  factory Book.fromJson(Map<String, dynamic> json) {
    final abbrevObj = json['abbrev'];
    final abbrev = abbrevObj is Map ? (abbrevObj['pt'] ?? abbrevObj['en'] ?? '') : (abbrevObj ?? '');
    return Book(
      abbrev: abbrev.toString(),
      name: (json['name'] ?? '').toString(),
      chapters: (json['chapters'] ?? 0) is int ? json['chapters'] : int.tryParse('${json['chapters']}') ?? 0,
    );
  }
}
