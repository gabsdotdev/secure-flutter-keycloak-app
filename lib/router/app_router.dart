import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/splash_screen.dart';

/// Configuração do roteador do aplicativo usando go_router.
///
/// Rotas disponíveis:
/// - `/` (SplashScreen): Verificação inicial do estado de autenticação.
/// - `/login` (LoginPage): Tela de autenticação com Keycloak.
/// - `/home` (HomePage): Tela protegida, acessível apenas após login.
///
/// O guard de navegação ([_redirect]) verifica o estado de autenticação
/// antes de permitir acesso a rotas protegidas.
///
/// O [authProvider] é passado diretamente para evitar que o router seja
/// recriado a cada rebuild do widget raiz.
class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      // Reescuta mudanças no AuthProvider para atualizar navegação
      refreshListenable: authProvider,
      redirect: (context, state) => _redirect(authProvider, state),
      routes: [
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Página não encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Guard de navegação: redireciona baseado no estado de autenticação.
  static String? _redirect(AuthProvider authProvider, GoRouterState state) {
    final isChecking = authProvider.status == AuthStatus.checking;
    final isAuthenticated = authProvider.isAuthenticated;
    final location = state.matchedLocation;

    // Aguarda verificação inicial do estado de autenticação
    if (isChecking) {
      return location == '/' ? null : '/';
    }

    // Redireciona usuário não autenticado para login (ou splash)
    if (!isAuthenticated && location == '/home') {
      return '/login';
    }

    // Redireciona usuário já autenticado para home
    if (isAuthenticated && (location == '/login' || location == '/')) {
      return '/home';
    }

    // Redireciona da splash para login se não autenticado
    if (!isAuthenticated && location == '/') {
      return '/login';
    }

    return null; // Sem redirecionamento necessário
  }
}

