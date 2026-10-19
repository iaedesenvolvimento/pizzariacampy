import '../network/api_client.dart';
import '../errors/app_exception.dart';
import '../storage/app_storage.dart';
import 'auth_models.dart';

class AuthService {
  AuthService({required ApiClient apiClient, required AppStorage storage})
      : _apiClient = apiClient,
        _storage = storage;

  final ApiClient _apiClient;
  final AppStorage _storage;

  String? get accessToken => _storage.accessToken;

  Future<Map<String, String>?> readSavedCredentials() =>
      _storage.readSavedCredentials();

  Future<AuthSession?> restoreSession() async {
    final accessToken = _storage.accessToken;
    final refreshToken = _storage.refreshToken;
    if (accessToken == null || refreshToken == null) return null;

    try {
      final response =
          await _apiClient.get('/auth/me', headers: _authHeaders(accessToken));
      if (response is! Map<String, dynamic>) return null;
      await _storage.saveUser(response);
      return AuthSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: AuthUser.fromJson(response));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final refreshed = await refreshSession();
        if (refreshed != null) return refreshed;
      }
      return _cachedSession();
    } on NetworkException {
      return _cachedSession();
    } catch (_) {
      return _cachedSession();
    }
  }

  Future<AuthSession?> refreshSession() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null) return null;
    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        body: {'refresh_token': refreshToken},
      );
      final session = _saveSession(response);
      final savedSession = await session;
      await _storage.saveUser(_userToJson(savedSession.user));
      return savedSession;
    } catch (_) {
      return null;
    }
  }

  Future<AuthSession> login(
      {required String email,
      required String password,
      bool rememberPassword = false}) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    final session = await _saveSession(response);
    if (rememberPassword) {
      await _storage.saveCredentials(email: email, password: password);
    } else {
      await _storage.clearSavedCredentials();
    }
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    bool rememberPassword = true,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'privacy_consent': true,
      },
    );
    final session = await _saveSession(response);
    if (rememberPassword) {
      await _storage.saveCredentials(email: email, password: password);
    }
    return session;
  }

  Future<void> requestPasswordRecovery(String email) async {
    await _apiClient
        .post('/auth/password-recovery', body: {'email': email.trim()});
  }

  Future<void> resetPassword(
      {required String token, required String password}) async {
    await _apiClient.post('/auth/password-reset',
        body: {'token': token.trim(), 'password': password});
  }

  Future<AuthUser> updateProfile({required String name}) async {
    final response = await _apiClient.patch('/auth/me',
        headers: _authHeaders(_storage.accessToken!),
        body: {'name': name.trim()});
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta de perfil inválida.');
    }
    await _storage.saveUser(response);
    return AuthUser.fromJson(response);
  }

  Future<AuthUser> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _apiClient.uploadBytes('/auth/me/avatar',
        bytes: bytes,
        filename: filename,
        fieldName: 'file',
        headers: _authHeaders(_storage.accessToken!));
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta de perfil inválida.');
    }
    await _storage.saveUser(response);
    return AuthUser.fromJson(response);
  }

  Future<void> logout() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken != null) {
      try {
        await _apiClient
            .post('/auth/logout', body: {'refresh_token': refreshToken});
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
    await _storage.saveUser(_userToJson(session.user));
    return session;
  }

  AuthSession? _cachedSession() {
    final cachedUser = _storage.cachedUser;
    final accessToken = _storage.accessToken;
    final refreshToken = _storage.refreshToken;
    if (cachedUser == null || accessToken == null || refreshToken == null) {
      return null;
    }
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(cachedUser),
    );
  }

  Map<String, dynamic> _userToJson(AuthUser user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'avatar_url': user.avatarUrl,
      };

  Map<String, String> _authHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }
}
