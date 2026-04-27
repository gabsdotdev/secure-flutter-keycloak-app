import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro de tokens.
///
/// Utiliza [flutter_secure_storage] para persistir tokens de forma segura:
/// - Android: Android Keystore System (criptografado com AES-256-GCM)
/// - iOS: Keychain Services
///
/// NUNCA use SharedPreferences ou outros storages não criptografados
/// para armazenar tokens de acesso ou refresh tokens.
class SecureStorageService {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _idTokenKey = 'auth_id_token';
  static const _tokenExpiryKey = 'auth_token_expiry';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          // Opções Android: usa EncryptedSharedPreferences
          // com Android Keystore para gerenciamento de chaves.
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          // Opções iOS: armazena no Keychain com acessibilidade
          // apenas quando o dispositivo está desbloqueado.
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Persiste o access token de forma segura.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Persiste o refresh token de forma segura.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Persiste o ID token de forma segura.
  Future<void> saveIdToken(String token) async {
    await _storage.write(key: _idTokenKey, value: token);
  }

  /// Persiste a data/hora de expiração do access token.
  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(
      key: _tokenExpiryKey,
      value: expiry.toUtc().toIso8601String(),
    );
  }

  /// Recupera o access token armazenado.
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Recupera o refresh token armazenado.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Recupera o ID token armazenado.
  Future<String?> getIdToken() async {
    return _storage.read(key: _idTokenKey);
  }

  /// Recupera a data/hora de expiração do access token.
  Future<DateTime?> getTokenExpiry() async {
    final value = await _storage.read(key: _tokenExpiryKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Remove todos os tokens armazenados (logout local).
  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _idTokenKey),
      _storage.delete(key: _tokenExpiryKey),
    ]);
  }

  /// Verifica se existem tokens armazenados.
  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
