import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import 'auth_models.dart';
import 'auth_service.dart';

enum AuthStatus { loading, unauthenticated, authenticated, submitting, error }

class AuthController extends ChangeNotifier {
  AuthController(this._service);

  final AuthService _service;

  String? get accessToken => _service.accessToken;
  AuthStatus status = AuthStatus.loading;
  AuthUser? user;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  Future<void> initialize() async {
    status = AuthStatus.loading;
    notifyListeners();
    try {
      final session = await _service.restoreSession();
      user = session?.user;
      status = session == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _submit(() => _service.login(email: email, password: password));
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    return _submit(() => _service.register(name: name, email: email, password: password));
  }

  Future<bool> requestPasswordRecovery(String email) async {
    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.requestPasswordRecovery(email);
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppException catch (error) {
      status = AuthStatus.error;
      errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      status = AuthStatus.error;
      errorMessage = 'Não foi possível enviar as instruções.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({required String token, required String password}) async {
    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.resetPassword(token: token, password: password);
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AppException catch (error) {
      status = AuthStatus.error;
      errorMessage = error.message;
    } catch (_) {
      status = AuthStatus.error;
      errorMessage = 'Não foi possível redefinir a senha.';
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _submit(Future<AuthSession> Function() action) async {
    status = AuthStatus.submitting;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await action();
      user = session.user;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (error) {
      status = AuthStatus.error;
      errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      status = AuthStatus.error;
      errorMessage = 'Não foi possível concluir a operação.';
      notifyListeners();
      return false;
    }
  }
}
