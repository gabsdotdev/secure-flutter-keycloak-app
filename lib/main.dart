import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/env/dev_config.dart';
// import 'config/env/staging_config.dart'; // Descomente para staging
// import 'config/env/prod_config.dart';    // Descomente para produção
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';

/// Ponto de entrada do aplicativo.
///
/// Para trocar de ambiente, altere a configuração injetada no [AuthService].
/// Sugestão: use dart-define para selecionar o ambiente em tempo de compilação:
///   flutter run --dart-define=ENV=prod
///
/// Exemplo com dart-define:
/// ```dart
/// const env = String.fromEnvironment('ENV', defaultValue: 'dev');
/// final config = switch (env) {
///   'prod'    => const ProdConfig(),
///   'staging' => const StagingConfig(),
///   _         => const DevConfig(),
/// };
/// ```
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Seleciona a configuração de ambiente
  // Em produção, substitua DevConfig() por ProdConfig()
  const config = DevConfig();

  // Inicializa o serviço de autenticação com a configuração do ambiente
  final authService = AuthService(config: config);

  // Cria o AuthProvider que gerencia o estado de autenticação
  final authProvider = AuthProvider(authService: authService);

  // Cria o router uma única vez, passando o authProvider diretamente.
  // Isso evita que o router seja recriado a cada rebuild do widget raiz.
  final router = AppRouter.createRouter(authProvider);

  runApp(
    // Injeta o AuthProvider na árvore de widgets usando ChangeNotifierProvider.value
    // para reutilizar a instância já criada
    ChangeNotifierProvider.value(
      value: authProvider,
      child: SecureApp(router: router),
    ),
  );
}

/// Widget raiz do aplicativo.
class SecureApp extends StatelessWidget {
  /// Roteador go_router criado uma única vez em [main].
  final GoRouter router;

  const SecureApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Secure App',
      debugShowCheckedModeBanner: false,

      // Tema do aplicativo usando Material Design 3
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Azul corporativo
          brightness: Brightness.light,
        ),
      ),

      // Tema escuro
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
      ),

      themeMode: ThemeMode.system,

      // Configuração do roteador go_router
      routerConfig: router,
    );
  }
}

