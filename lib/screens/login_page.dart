import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Tela de login com autenticação via Keycloak.
///
/// Exibe o nome do app, botão de login e indicador de carregamento.
/// O login é feito via navegador seguro do sistema (não WebView embutida),
/// garantindo que as credenciais do usuário nunca passem pelo app.
///
/// Fluxo:
/// 1. Usuário toca em "Entrar com Keycloak"
/// 2. App abre o navegador seguro do sistema
/// 3. Usuário se autentica no Keycloak
/// 4. Keycloak redireciona de volta ao app via deep link
/// 5. App troca o authorization code por tokens (com PKCE)
/// 6. Tokens são armazenados de forma segura
/// 7. Usuário é redirecionado para a HomePage
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // ── Logo e nome do aplicativo ──
                  _buildLogo(context),

                  const Spacer(flex: 2),

                  // ── Mensagem de erro ──
                  if (authProvider.status == AuthStatus.error &&
                      authProvider.errorMessage != null)
                    _buildErrorMessage(context, authProvider),

                  const SizedBox(height: 16),

                  // ── Botão de login ──
                  _buildLoginButton(context, authProvider),

                  const SizedBox(height: 16),

                  // ── Informação de segurança ──
                  _buildSecurityInfo(context),

                  const Spacer(flex: 1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        // Ícone do aplicativo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.security,
            size: 56,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Nome do aplicativo
        Text(
          'Secure App',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Acesse com sua conta corporativa',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authProvider.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: Theme.of(context).colorScheme.onErrorContainer,
            onPressed: () => authProvider.clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, AuthProvider authProvider) {
    final isLoading = authProvider.isLoading;

    return FilledButton.icon(
      onPressed: isLoading ? null : () => authProvider.login(),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.login),
      label: Text(
        isLoading ? 'Autenticando...' : 'Entrar com Keycloak',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSecurityInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'Conexão segura via navegador do sistema',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
        ),
      ],
    );
  }
}
