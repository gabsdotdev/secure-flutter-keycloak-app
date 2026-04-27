import 'package:flutter_test/flutter_test.dart';
import 'package:secure_flutter_keycloak_app/models/user_model.dart';
import 'package:secure_flutter_keycloak_app/utils/jwt_utils.dart';

void main() {
  group('UserModel', () {
    test('deve criar UserModel a partir de claims JWT', () {
      final claims = {
        'sub': 'user-123',
        'name': 'João Silva',
        'email': 'joao@example.com',
        'preferred_username': 'joao.silva',
        'email_verified': true,
        'realm_access': {
          'roles': ['user', 'admin'],
        },
      };

      final user = UserModel.fromClaims(claims);

      expect(user.id, equals('user-123'));
      expect(user.name, equals('João Silva'));
      expect(user.email, equals('joao@example.com'));
      expect(user.username, equals('joao.silva'));
      expect(user.emailVerified, isTrue);
      expect(user.realmRoles, containsAll(['user', 'admin']));
    });

    test('deve lidar com claims ausentes graciosamente', () {
      final claims = <String, dynamic>{};

      final user = UserModel.fromClaims(claims);

      expect(user.id, isEmpty);
      expect(user.name, isEmpty);
      expect(user.email, isEmpty);
      expect(user.username, isEmpty);
      expect(user.emailVerified, isFalse);
      expect(user.realmRoles, isEmpty);
    });

    test('deve verificar roles corretamente', () {
      final user = UserModel(
        id: '1',
        name: 'Test',
        email: 'test@example.com',
        username: 'test',
        realmRoles: ['user', 'admin'],
      );

      expect(user.hasRole('admin'), isTrue);
      expect(user.hasRole('user'), isTrue);
      expect(user.hasRole('superuser'), isFalse);
    });
  });

  group('JwtUtils', () {
    // JWT de exemplo com payload: {"sub":"user1","exp":9999999999,"name":"Test"}
    // Header: {"alg":"HS256","typ":"JWT"}
    // Nota: Este token é apenas para teste de decodificação de payload,
    // a validação de assinatura deve ser feita no backend.
    const sampleJwt =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJzdWIiOiJ1c2VyMSIsImV4cCI6OTk5OTk5OTk5OSwibmFtZSI6IlRlc3QifQ'
        '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    test('deve decodificar o payload do JWT corretamente', () {
      final claims = JwtUtils.decodePayload(sampleJwt);

      expect(claims, isNotNull);
      expect(claims!['sub'], equals('user1'));
      expect(claims['name'], equals('Test'));
      expect(claims['exp'], equals(9999999999));
    });

    test('deve retornar null para JWT inválido', () {
      expect(JwtUtils.decodePayload('invalid'), isNull);
      expect(JwtUtils.decodePayload(''), isNull);
      expect(JwtUtils.decodePayload('a.b'), isNull);
    });

    test('deve identificar token não expirado', () {
      // exp: 9999999999 (ano ~2286) - definitivamente não expirado
      expect(JwtUtils.isExpired(sampleJwt), isFalse);
    });

    test('deve identificar token expirado', () {
      // Cria um JWT com exp no passado (1970)
      // Header e signature são ignorados na decodificação do payload
      // Payload: {"sub":"user1","exp":1}
      const expiredJwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
          '.eyJzdWIiOiJ1c2VyMSIsImV4cCI6MX0'
          '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

      expect(JwtUtils.isExpired(expiredJwt), isTrue);
    });

    test('deve tratar token sem campo exp como expirado', () {
      // Payload: {"sub":"user1"} - sem campo exp
      const noExpJwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
          '.eyJzdWIiOiJ1c2VyMSJ9'
          '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

      expect(JwtUtils.isExpired(noExpJwt), isTrue);
    });
  });
}
