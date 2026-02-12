class Env {
  static const String baseUrl = "https://www.abibliadigital.com.br/api";

  static const String abibliaToken = String.fromEnvironment('ABIBLIA_TOKEN');

  static void validate() {
    if (abibliaToken.isEmpty) {
      throw Exception(
        "ABIBLIA_TOKEN nao definido. Rode com --dart-define-from-file=env.json "
        "ou --dart-define=ABIBLIA_TOKEN=SEU_TOKEN",
      );
    }
  }
}
