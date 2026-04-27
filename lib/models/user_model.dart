/// Modelo de usuário autenticado.
///
/// Os campos são preenchidos a partir dos claims do ID Token JWT
/// retornado pelo Keycloak após autenticação bem-sucedida.
class UserModel {
  /// Identificador único do usuário no Keycloak (sub claim).
  final String id;

  /// Nome de exibição completo (name claim).
  final String name;

  /// Endereço de e-mail (email claim).
  final String email;

  /// Nome de usuário preferido (preferred_username claim).
  final String username;

  /// Indica se o e-mail foi verificado (email_verified claim).
  final bool emailVerified;

  /// Roles do usuário no realm (roles do realm_access).
  final List<String> realmRoles;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.emailVerified = false,
    this.realmRoles = const [],
  });

  /// Cria um [UserModel] a partir do mapa de claims do JWT.
  factory UserModel.fromClaims(Map<String, dynamic> claims) {
    // Extrai roles do realm_access, se presentes
    final realmAccess = claims['realm_access'] as Map<String, dynamic>?;
    final roles = realmAccess != null
        ? List<String>.from(realmAccess['roles'] as List? ?? [])
        : <String>[];

    return UserModel(
      id: claims['sub'] as String? ?? '',
      name: claims['name'] as String? ??
          claims['preferred_username'] as String? ??
          '',
      email: claims['email'] as String? ?? '',
      username: claims['preferred_username'] as String? ?? '',
      emailVerified: claims['email_verified'] as bool? ?? false,
      realmRoles: roles,
    );
  }

  /// Verifica se o usuário possui uma determinada role no realm.
  bool hasRole(String role) => realmRoles.contains(role);

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, username: $username)';
}
