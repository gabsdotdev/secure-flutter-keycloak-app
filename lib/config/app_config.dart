/// Classe base de configuração do aplicativo.
///
/// Cada ambiente (dev, staging, produção) deve estender esta classe
/// e fornecer os valores adequados para cada parâmetro.
abstract class AppConfig {
  /// URL base do servidor Keycloak.
  /// Exemplo: https://keycloak.example.com
  final String keycloakBaseUrl;

  /// Nome do realm do Keycloak.
  final String realm;

  /// Client ID público registrado no Keycloak.
  /// Não incluir client_secret no app mobile.
  final String clientId;

  /// URI de redirecionamento após autenticação bem-sucedida.
  /// Deve corresponder exatamente ao valor configurado no Keycloak.
  final String redirectUri;

  /// URI de redirecionamento após logout.
  final String postLogoutRedirectUri;

  /// Escopos OAuth2 solicitados.
  /// offline_access é necessário para receber refresh_token.
  final List<String> scopes;

  const AppConfig({
    required this.keycloakBaseUrl,
    required this.realm,
    required this.clientId,
    required this.redirectUri,
    required this.postLogoutRedirectUri,
    this.scopes = const [
      'openid',
      'profile',
      'email',
      'offline_access',
    ],
  });

  /// Endpoint de descoberta OpenID Connect.
  /// O flutter_appauth usa este endpoint para descobrir automaticamente
  /// os endpoints de autorização, token e end_session.
  String get discoveryUrl =>
      '$keycloakBaseUrl/realms/$realm/.well-known/openid-configuration';

  /// Issuer URL do realm. Usado para validar o campo "iss" do JWT.
  String get issuer => '$keycloakBaseUrl/realms/$realm';

  /// Indica se esta configuração é para um ambiente de produção.
  /// Subclasses de produção devem retornar `true`.
  bool get isProduction => false;
}
