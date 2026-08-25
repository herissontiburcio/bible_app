# 📖 Bible App (Bíblia Sagrada)

Um aplicativo moderno, fluido e completo da Bíblia Sagrada desenvolvido em **Flutter**, com suporte offline e online, plano de leitura anual, buscas inteligentes, anotações, favoritos e histórico.

---

## ✨ Funcionalidades

- 📚 **Navegação Completa por Livros e Capítulos:** Suporte ao Antigo e Novo Testamento.
- 📴 **Modo Híbrido / Offline:** Base local embarcada em JSON (ACF e NVI) e suporte a download de versões adicionais.
- 🌐 **Integração com API Externa:** Conexão com [A Bíblia Digital](https://www.abibliadigital.com.br/) para consulta online.
- 📅 **Ano Bíblico:** Acompanhamento de leitura diária com marcação de progresso e notificações de lembrete.
- ⭐ **Estudos e Favoritos:** Destaque de versículos, anotações personalizadas e histórico de leitura.
- 🔍 **Busca Rápida:** Pesquisa de termos e passagens com paginação.
- 🎨 **Interface Moderna:** Tema claro e escuro, fontes ajustáveis e transições suaves.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Flutter SDK (versão 3.x ou superior)
- Dart SDK
- Android Studio / Xcode configurados

### 1. Clonar o repositório
```bash
git clone https://github.com/herissontiburcio/bible_app.git
cd bible_app
```

### 2. Instalar dependências
```bash
flutter pub get
```

### 3. Configurar variáveis de ambiente (Opcional)
O aplicativo funciona em modo offline nativo. Para habilitar recursos adicionais da API *A Bíblia Digital*:

1. Copie o arquivo de exemplo:
   ```bash
   cp env.example.json env.json
   ```
2. Insira o seu token obtido em [abibliadigital.com.br](https://www.abibliadigital.com.br/):
   ```json
   {
     "ABIBLIA_TOKEN": "SEU_TOKEN_AQUI"
   }
   ```

### 4. Executar o aplicativo
Para rodar passando o arquivo de ambiente:
```bash
flutter run --dart-define-from-file=env.json
```

Ou simplesmente:
```bash
flutter run
```

---

## 🛠️ Tecnologias Utilizadas

- **[Flutter](https://flutter.dev/)** & **[Dart](https://dart.dev/)**
- **[Flutter Riverpod](https://riverpod.dev/)** - Gerenciamento de estado
- **[GoRouter](https://pub.dev/packages/go_router)** - Roteamento declarativo
- **[Hive](https://pub.dev/packages/hive_flutter)** - Armazenamento local rápido e leve
- **[Dio](https://pub.dev/packages/dio)** - Cliente HTTP
- **[Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)** - Notificações locais agendadas
- **[Google Fonts](https://pub.dev/packages/google_fonts)** - Tipografia personalizada
