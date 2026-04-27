import '../app_config.dart';

/// Configuração do ambiente de produção.
///
/// IMPORTANTE:
/// - Nunca commite credenciais reais no repositório.
/// - Em CI/CD, injete as variáveis de ambiente via pipeline seguro.
/// - Configure HTTPS obrigatório no servidor Keycloak de produção.
/// - Habilite certificate pinning nas versões de produção do app.
/// - Registre somente a redirect URI exata no Keycloak (sem wildcards).
class ProdConfig extends AppConfig {
  const ProdConfig()
      : super(
          keycloakBaseUrl: 'https://keycloak.example.com',
          realm: 'meu-realm',
          clientId: 'meu-app',
          redirectUri: 'com.example.app://callback',
          postLogoutRedirectUri: 'com.example.app://logout',
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        );

  @override
  bool get isProduction => true;
}
