class BibleVersion {
  final String version;
  final String? name;

  BibleVersion({required this.version, this.name});

  factory BibleVersion.fromJson(Map<String, dynamic> json) {
    return BibleVersion(
      version: (json['version'] ?? '').toString(),
      name: json['name']?.toString(),
    );
  }
}
