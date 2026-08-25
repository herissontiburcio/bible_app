class Env {
  static const String baseUrl = "https://www.abibliadigital.com.br/api";

  static const String abibliaToken = String.fromEnvironment('ABIBLIA_TOKEN');

  static bool get hasToken => abibliaToken.isNotEmpty;

  static void validate() {
    if (!hasToken) {
      // ignore: avoid_print
      print(
        "[Env] ABIBLIA_TOKEN não definido. O aplicativo operará em modo Híbrido/Offline com os dados locais integrados.",
      );
    }
  }
}
