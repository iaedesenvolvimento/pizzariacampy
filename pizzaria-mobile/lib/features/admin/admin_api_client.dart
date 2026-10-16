import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';

class AdminApiClient {
  AdminApiClient(this._api, this._storage);

  final ApiClient _api;
  final AppStorage _storage;
  Future<String?>? _refreshing;

  Future<dynamic> get(String path) => _run(
      (token) => _api.get(path, headers: {'Authorization': 'Bearer $token'}));

  Future<dynamic> post(String path, {Object? body}) => _run((token) =>
      _api.post(path, headers: {'Authorization': 'Bearer $token'}, body: body));

  Future<dynamic> patch(String path, {Object? body}) => _run((token) => _api
      .patch(path, headers: {'Authorization': 'Bearer $token'}, body: body));

  Future<void> delete(String path) => _run((token) =>
      _api.delete(path, headers: {'Authorization': 'Bearer $token'}));

  Future<dynamic> put(String path, {Object? body}) => _run((token) =>
      _api.put(path, headers: {'Authorization': 'Bearer $token'}, body: body));

  Future<dynamic> uploadFile(String path,
          {required String filePath, required String fieldName}) =>
      _run((token) => _api.uploadFile(path,
          filePath: filePath,
          fieldName: fieldName,
          headers: {'Authorization': 'Bearer $token'}));

  Future<T> _run<T>(Future<T> Function(String token) request) async {
    final token = _storage.accessToken;
    if (token == null) throw const FormatException('Sessão expirada.');
    try {
      return await request(token);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      final refreshed = await _refresh();
      if (refreshed == null) rethrow;
      return request(refreshed);
    }
  }

  Future<String?> _refresh() async {
    final currentRefresh = _refreshing;
    if (currentRefresh != null) return currentRefresh;
    final refreshOperation = _performRefresh();
    _refreshing = refreshOperation;
    try {
      return await refreshOperation;
    } finally {
      if (identical(_refreshing, refreshOperation)) _refreshing = null;
    }
  }

  Future<String?> _performRefresh() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null) return null;
    try {
      final response = await _api
          .post('/auth/refresh', body: {'refresh_token': refreshToken});
      if (response is! Map<String, dynamic>) return null;
      final access = response['access_token']?.toString();
      final refresh = response['refresh_token']?.toString();
      if (access == null || refresh == null) return null;
      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      return access;
    } catch (_) {
      return null;
    }
  }
}
