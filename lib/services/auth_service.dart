import 'package:flutter_appauth/flutter_appauth.dart';

import '../config/app_config.dart';
import '../models/user_model.dart';
import '../utils/jwt_utils.dart';
import 'secure_storage_service.dart';

/// Exceção lançada quando ocorre erro durante autenticação.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Serviço de autenticação usando Keycloak via OIDC/OAuth2.
///
/// Implementa o Authorization Code Flow com PKCE usando [flutter_appauth],
/// que abre o navegador seguro do sistema operacional (Custom Tabs no Android,
/// ASWebAuthenticationSession no iOS). Nunca usa WebView embutida.
///
/// Boas práticas de segurança aplicadas:
/// - PKCE obrigatório (gerado automaticamente pelo flutter_appauth)
/// - Tokens armazenados somente em storage seguro
/// - Nenhuma senha armazenada ou transmitida pelo app
/// - Refresh token gerenciado de forma segura
/// - Client secret não incluído no app mobile
class AuthService {
  final FlutterAppAuth _appAuth;
  final SecureStorageService _storage;
  final AppConfig _config;

  AuthService({
    required AppConfig config,
    SecureStorageService? storage,
    FlutterAppAuth? appAuth,
  })  : _config = config,
        _storage = storage ?? SecureStorageService(),
        _appAuth = appAuth ?? const FlutterAppAuth();

  /// Inicia o fluxo de autenticação OAuth2 com Authorization Code + PKCE.
  ///
  /// Abre o navegador seguro do sistema para que o usuário possa inserir
  /// suas credenciais diretamente no Keycloak. O app nunca tem acesso
  /// à senha do usuário.
  ///
  /// Lança [AuthException] em caso de falha.
  Future<UserModel> login() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _config.clientId,
          _config.redirectUri,
          discoveryUrl: _config.discoveryUrl,
          scopes: _config.scopes,
          // Parâmetros adicionais para o Keycloak
          additionalParameters: {
            // Força o Keycloak a solicitar login mesmo com sessão ativa
            // Remova 'prompt' se quiser SSO silencioso
            // 'prompt': 'login',
          },
          // PKCE é habilitado automaticamente pelo flutter_appauth
          // Não é necessário configurar code_challenge manualmente
          allowInsecureConnections:
              !_config.isProduction, // Apenas em dev/staging
        ),
      );

      if (result == null) {
        throw const AuthException('Autenticação cancelada pelo usuário.');
      }

      await _persistTokens(result);
      return _extractUser(result.idToken);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Falha na autenticação: ${e.toString()}');
    }
  }

  /// Realiza o logout completo: limpa tokens locais e encerra a sessão
  /// no Keycloak via end_session_endpoint.
  ///
  /// O Keycloak invalida o refresh token no servidor, garantindo que
  /// o token não possa ser reutilizado mesmo que alguém o obtenha.
  Future<void> logout() async {
    try {
      final idToken = await _storage.getIdToken();

      // Encerra a sessão no Keycloak via end_session_endpoint
      if (idToken != null) {
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: idToken,
            postLogoutRedirectUrl: _config.postLogoutRedirectUri,
            discoveryUrl: _config.discoveryUrl,
            allowInsecureConnections: !_config.isProduction,
          ),
        );
      }
    } catch (_) {
      // Mesmo que o end_session falhe (ex: sem conectividade),
      // os tokens locais são removidos para garantir logout local.
    } finally {
      // Sempre limpa os tokens locais, independente do resultado remoto
      await _storage.clearAll();
    }
  }

  /// Retorna o access token válido, realizando refresh se necessário.
  ///
  /// Verifica a expiração do token antes de retorná-lo. Se estiver
  /// expirado ou próximo de expirar, tenta obter um novo usando o
  /// refresh token.
  ///
  /// Lança [AuthException] se não houver tokens ou se o refresh falhar.
  Future<String> getValidAccessToken() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) {
      throw const AuthException('Usuário não autenticado.');
    }

    // Verifica se o token está expirado (com margem de 30 segundos)
    if (!JwtUtils.isExpired(accessToken)) {
      return accessToken;
    }

    // Token expirado: tenta renovar com o refresh token
    return _refreshAccessToken();
  }

  /// Tenta renovar o access token usando o refresh token armazenado.
  ///
  /// Lança [AuthException] se o refresh token não existir ou estiver inválido.
  Future<String> _refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      throw const AuthException(
          'Sessão expirada. Por favor, faça login novamente.');
    }

    try {
      final result = await _appAuth.token(
        TokenRequest(
          _config.clientId,
          _config.redirectUri,
          discoveryUrl: _config.discoveryUrl,
          refreshToken: refreshToken,
          scopes: _config.scopes,
          allowInsecureConnections: !_config.isProduction,
        ),
      );

      if (result == null || result.accessToken == null) {
        throw const AuthException('Falha ao renovar sessão.');
      }

      await _persistTokens(result);
      return result.accessToken!;
    } on AuthException {
      rethrow;
    } catch (e) {
      // Se o refresh falhar, limpa os tokens para forçar novo login
      await _storage.clearAll();
      throw AuthException('Sessão expirada: ${e.toString()}');
    }
  }

  /// Verifica se há uma sessão ativa com tokens válidos.
  ///
  /// Retorna `true` se houver access token ou refresh token válido.
  Future<bool> isAuthenticated() async {
    final hasTokens = await _storage.hasTokens();
    if (!hasTokens) return false;

    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) return false;

    // Se o access token ainda é válido, o usuário está autenticado
    if (!JwtUtils.isExpired(accessToken)) return true;

    // Access token expirado: verifica se há refresh token para renovar
    final refreshToken = await _storage.getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// Recupera os dados do usuário a partir do ID token armazenado.
  ///
  /// Retorna `null` se não houver ID token ou se não for possível
  /// extrair os dados do usuário.
  Future<UserModel?> getCurrentUser() async {
    final idToken = await _storage.getIdToken();
    if (idToken == null) return null;

    final claims = JwtUtils.decodePayload(idToken);
    if (claims == null) return null;

    return UserModel.fromClaims(claims);
  }

  /// Persiste todos os tokens retornados pelo servidor de autorização.
  ///
  /// [TokenResponse] é a classe base comum de [AuthorizationTokenResponse]
  /// e [TokenResponse] no flutter_appauth.
  Future<void> _persistTokens(TokenResponse result) async {
    final operations = <Future<void>>[];

    if (result.accessToken != null) {
      operations.add(_storage.saveAccessToken(result.accessToken!));
    }
    if (result.refreshToken != null) {
      operations.add(_storage.saveRefreshToken(result.refreshToken!));
    }
    if (result.idToken != null) {
      operations.add(_storage.saveIdToken(result.idToken!));
    }
    if (result.accessTokenExpirationDateTime != null) {
      operations.add(
          _storage.saveTokenExpiry(result.accessTokenExpirationDateTime!));
    }

    await Future.wait(operations);
  }

  /// Extrai os dados do usuário a partir do ID token JWT.
  UserModel _extractUser(String? idToken) {
    if (idToken == null) {
      throw const AuthException('ID token não recebido do servidor.');
    }

    final claims = JwtUtils.decodePayload(idToken);
    if (claims == null) {
      throw const AuthException('Não foi possível decodificar o ID token.');
    }

    return UserModel.fromClaims(claims);
  }
}
