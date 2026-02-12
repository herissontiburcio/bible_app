class Endpoints {
  static String randomVerse(String version) => "/verses/$version/random";
  static String versions() => "/versions";
  static String books() => "/books";
  static String chapter(String version, String bookAbbrev, int chapter) =>
      "/verses/$version/$bookAbbrev/$chapter";
  static String search() => "/verses/search";
}
