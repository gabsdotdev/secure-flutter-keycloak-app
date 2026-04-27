import '../app_config.dart';

/// Configuração do ambiente de homologação (staging).
///
/// Use este ambiente para testes de integração e QA antes do deploy
/// em produção.
class StagingConfig extends AppConfig {
  const StagingConfig()
      : super(
          keycloakBaseUrl: 'https://keycloak-staging.example.com',
          realm: 'meu-realm-staging',
          clientId: 'meu-app-staging',
          redirectUri: 'com.example.app://callback',
          postLogoutRedirectUri: 'com.example.app://logout',
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        );
}
