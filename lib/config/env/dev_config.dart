import '../app_config.dart';

/// Configuração do ambiente de desenvolvimento.
///
/// Para usar este ambiente, passe [DevConfig()] ao inicializar o aplicativo.
/// Exemplo no main.dart:
///   const config = DevConfig();
///
/// ATENÇÃO: Nunca use URLs ou credenciais de desenvolvimento em produção.
class DevConfig extends AppConfig {
  const DevConfig()
      : super(
          // Substitua pelo endereço do seu servidor Keycloak de desenvolvimento.
          // Durante desenvolvimento local, você pode usar ngrok ou localhost com
          // port forwarding para expor o Keycloak ao emulador/dispositivo.
          keycloakBaseUrl: 'https://keycloak-dev.example.com',
          realm: 'meu-realm-dev',
          clientId: 'meu-app-dev',
          // O scheme 'com.example.app' deve ser registrado no AndroidManifest.xml
          // e no Info.plist do iOS. Veja a documentação para configuração.
          redirectUri: 'com.example.app://callback',
          postLogoutRedirectUri: 'com.example.app://logout',
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        );
}
