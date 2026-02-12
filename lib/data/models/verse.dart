class Verse {
  final int number;
  final String text;

  Verse({required this.number, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['number'] is int ? json['number'] : int.tryParse('${json['number']}') ?? 0,
      text: (json['text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'number': number, 'text': text};
}
