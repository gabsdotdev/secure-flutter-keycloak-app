import 'dart:convert';

/// Utilitário para operações com JSON Web Tokens (JWT).
///
/// IMPORTANTE: Esta implementação decodifica o payload do JWT para leitura
/// de claims. A validação criptográfica da assinatura deve ser feita no
/// backend, nunca no cliente mobile. O app confia no token porque veio
/// diretamente do servidor de autorização (Keycloak) via HTTPS.
class JwtUtils {
  JwtUtils._();

  /// Decodifica o payload de um JWT e retorna os claims como Map.
  ///
  /// Retorna `null` se o token for inválido ou não puder ser decodificado.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // O payload é a segunda parte do JWT, codificada em Base64URL
      final payload = _decodeBase64(parts[1]);
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Verifica se um access token JWT está expirado.
  ///
  /// Compara o campo `exp` (expiration time) com o timestamp atual.
  /// Adiciona uma margem de segurança de [bufferSeconds] para evitar
  /// uso de tokens prestes a expirar.
  static bool isExpired(String token, {int bufferSeconds = 30}) {
    final claims = decodePayload(token);
    if (claims == null) return true;

    final exp = claims['exp'];
    if (exp == null) return true;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (exp as int) * 1000,
      isUtc: true,
    );

    final now = DateTime.now().toUtc();
    return now.isAfter(expiresAt.subtract(Duration(seconds: bufferSeconds)));
  }

  /// Decodifica uma string Base64URL para string UTF-8.
  static String _decodeBase64(String input) {
    // Normaliza para Base64 padrão adicionando padding necessário
    String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
      case 3:
        normalized += '=';
    }
    final bytes = base64Decode(normalized);
    return utf8.decode(bytes);
  }
}
