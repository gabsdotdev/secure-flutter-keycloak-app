import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Estado atual da autenticação.
enum AuthStatus {
  /// Estado inicial: verificando se há sessão ativa armazenada.
  checking,

  /// Usuário não autenticado.
  unauthenticated,

  /// Usuário autenticado com sucesso.
  authenticated,

  /// Operação de autenticação em andamento.
  loading,

  /// Ocorreu um erro durante a autenticação ou logout.
  error,
}

/// Provider de autenticação que gerencia o estado global de auth do app.
///
/// Utiliza o padrão [ChangeNotifier] com o pacote [provider] para
/// notificar widgets sobre mudanças no estado de autenticação.
///
/// Expõe:
/// - [status]: Estado atual da autenticação
/// - [currentUser]: Dados do usuário autenticado
/// - [errorMessage]: Mensagem de erro em caso de falha
/// - [login()]: Inicia o fluxo de autenticação
/// - [logout()]: Realiza o logout completo
/// - [checkAuthState()]: Verifica estado inicial ao abrir o app
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.checking;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider({required AuthService authService})
      : _authService = authService;

  /// Estado atual da autenticação.
  AuthStatus get status => _status;

  /// Dados do usuário atualmente autenticado.
  /// Retorna `null` se não há usuário autenticado.
  UserModel? get currentUser => _currentUser;

  /// Mensagem de erro da última operação falha.
  /// Retorna `null` se não há erro.
  String? get errorMessage => _errorMessage;

  /// Indica se uma operação está em andamento.
  bool get isLoading =>
      _status == AuthStatus.loading || _status == AuthStatus.checking;

  /// Indica se o usuário está autenticado.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Verifica o estado de autenticação ao inicializar o app.
  ///
  /// Deve ser chamado na inicialização do app para verificar se há
  /// uma sessão ativa salva no armazenamento seguro.
  Future<void> checkAuthState() async {
    _setStatus(AuthStatus.checking);

    try {
      final authenticated = await _authService.isAuthenticated();

      if (authenticated) {
        final user = await _authService.getCurrentUser();
        _currentUser = user;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Inicia o fluxo de login via Keycloak.
  ///
  /// Abre o navegador seguro do sistema para autenticação.
  /// Notifica os listeners sobre mudanças no estado.
  Future<void> login() async {
    _clearError();
    _setStatus(AuthStatus.loading);

    try {
      final user = await _authService.login();
      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
    } catch (e) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
      _setStatus(AuthStatus.error);
    }
  }

  /// Realiza o logout completo: remove tokens locais e encerra sessão
  /// no Keycloak.
  Future<void> logout() async {
    _clearError();
    _setStatus(AuthStatus.loading);

    try {
      await _authService.logout();
    } catch (_) {
      // Logout local sempre acontece, mesmo em caso de falha remota
    } finally {
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Limpa a mensagem de erro atual.
  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
