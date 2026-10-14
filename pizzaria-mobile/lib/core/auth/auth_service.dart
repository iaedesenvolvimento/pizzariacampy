import '../network/api_client.dart';
import '../storage/app_storage.dart';
import 'auth_models.dart';

class AuthService {
  AuthService({required ApiClient apiClient, required AppStorage storage})
      : _apiClient = apiClient,
        _storage = storage;

  final ApiClient _apiClient;
  final AppStorage _storage;

  String? get accessToken => _storage.accessToken;

  Future<AuthSession?> restoreSession() async {
    final accessToken = _storage.accessToken;
    final refreshToken = _storage.refreshToken;
    if (accessToken == null || refreshToken == null) return null;

    try {
      final response = await _apiClient.get('/auth/me', headers: _authHeaders(accessToken));
      if (response is! Map<String, dynamic>) return null;
      return AuthSession(accessToken: accessToken, refreshToken: refreshToken, user: AuthUser.fromJson(response));
    } catch (_) {
      await _storage.clearSession();
      return null;
    }
  }

  Future<AuthSession> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return _saveSession(response);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return _saveSession(response);
  }

  Future<void> requestPasswordRecovery(String email) async {
    await _apiClient.post('/auth/password-recovery', body: {'email': email.trim()});
  }

  Future<void> resetPassword({required String token, required String password}) async {
    await _apiClient.post('/auth/password-reset', body: {'token': token.trim(), 'password': password});
  }

  Future<void> logout() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken != null) {
      try {
        await _apiClient.post('/auth/logout', body: {'refresh_token': refreshToken});
      } finally {
        await _storage.clearSession();
      }
    } else {
      await _storage.clearSession();
    }
  }

  Future<AuthSession> _saveSession(dynamic response) async {
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta de autenticação inválida.');
    }
    final session = AuthSession.fromJson(response);
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }
}
