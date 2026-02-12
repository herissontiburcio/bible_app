class BibleYearPlan {
  final String id;
  final List<BibleYearDay> days;

  BibleYearPlan({
    required this.id,
    required this.days,
  });

  factory BibleYearPlan.fromJson(Map<String, dynamic> json) {
    return BibleYearPlan(
      id: json['id'],
      days: (json['days'] as List)
          .map((e) => BibleYearDay.fromJson(e))
          .toList(),
    );
  }
}

class BibleYearDay {
  final int day;
  final List<BibleYearReading> readings;

  BibleYearDay({
    required this.day,
    required this.readings,
  });

  factory BibleYearDay.fromJson(Map<String, dynamic> json) {
    return BibleYearDay(
      day: json['day'],
      readings: (json['readings'] as List)
          .map((e) => BibleYearReading.fromJson(e))
          .toList(),
    );
  }
}

class BibleYearReading {
  final int bookIndex;
  final int chapter;
  final String stream;

  BibleYearReading({
    required this.bookIndex,
    required this.chapter,
    required this.stream,
  });

  factory BibleYearReading.fromJson(Map<String, dynamic> json) {
    return BibleYearReading(
      bookIndex: json['bookIndex'],
      chapter: json['chapter'],
      stream: json['stream'],
    );
  }
}
